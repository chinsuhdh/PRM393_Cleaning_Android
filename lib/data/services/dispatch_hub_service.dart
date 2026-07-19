import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../core/network/dio_client.dart';
import '../repositories/booking_repository.dart';
import '../repositories/dispatch_repository.dart';

abstract class DispatchHubClient {
  Future<void> connect();
  Future<void> disconnect();
  void onJobPosted(void Function() handler);
  void onJobTaken(void Function() handler);
  void onJobCancelled(void Function() handler);

  void onReconnected(void Function() handler);

  Future<void> subscribeToBooking(String bookingId);
  void onBookingStatusChanged(void Function() handler);

  void onWorkerPosition(void Function(double lat, double lng) handler);

  void onNearbyWorkersUpdated(void Function(List<({double lat, double lng})> locations) handler);
}

class SignalrDispatchHubClient implements DispatchHubClient {
  SignalrDispatchHubClient(Dio dio)
      : _connection = HubConnectionBuilder()
            .withUrl(
              _hubUrl(dio.options.baseUrl),
              options: HttpConnectionOptions(
                accessTokenFactory: () async => _bearerToken(dio) ?? '',
              ),
            )
            .withAutomaticReconnect()
            .build();

  final HubConnection _connection;

  @override
  Future<void> connect() async {
    if (_connection.state != HubConnectionState.Disconnected) return;
    await _connection.start();
  }

  @override
  Future<void> disconnect() => _connection.stop();

  @override
  void onJobPosted(void Function() handler) => _connection.on('jobPosted', (_) => handler());

  @override
  void onJobTaken(void Function() handler) => _connection.on('jobTaken', (_) => handler());

  @override
  void onJobCancelled(void Function() handler) => _connection.on('jobCancelled', (_) => handler());

  @override
  void onReconnected(void Function() handler) => _connection.onreconnected(({connectionId}) => handler());

  @override
  Future<void> subscribeToBooking(String bookingId) => _connection.invoke('SubscribeBooking', args: [bookingId]);

  @override
  void onBookingStatusChanged(void Function() handler) => _connection.on('bookingStatusChanged', (_) => handler());

  @override
  void onWorkerPosition(void Function(double lat, double lng) handler) {
    _connection.on('workerPosition', (args) {
      final raw = (args != null && args.isNotEmpty) ? args[0] : null;
      if (raw is Map) {
        final lat = (raw['latitude'] as num?)?.toDouble();
        final lng = (raw['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) handler(lat, lng);
      }
    });
  }

  @override
  void onNearbyWorkersUpdated(void Function(List<({double lat, double lng})> locations) handler) {
    _connection.on('nearbyWorkersUpdated', (args) {
      final raw = (args != null && args.isNotEmpty) ? args[0] : null;
      handler(parseNearbyWorkerLocations(raw));
    });
  }

  static String? _bearerToken(Dio dio) =>
      (dio.options.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');

  static String _hubUrl(String apiBaseUrl) {
    final trimmed = apiBaseUrl.endsWith('/api')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - '/api'.length)
        : apiBaseUrl;
    return '$trimmed/hubs/dispatch';
  }
}

final dispatchHubClientProvider = Provider<DispatchHubClient>((ref) {
  return SignalrDispatchHubClient(ref.watch(dioProvider));
});

class DispatchLiveFeedController {
  DispatchLiveFeedController(this._client, {required this.onFeedChanged});

  final DispatchHubClient _client;
  final void Function() onFeedChanged;

  Future<void> start() async {
    _client.onJobPosted(onFeedChanged);
    _client.onJobTaken(onFeedChanged);
    _client.onJobCancelled(onFeedChanged);
    _client.onReconnected(onFeedChanged);
    try {
      await _client.connect();
    } catch (_) {
      // Best-effort: the Available Jobs feed still works via REST pull-to-refresh without live
      // updates (same tolerance as WorkerRepository.updateLocation's background pings).
    }
  }

  Future<void> stop() => _client.disconnect();
}


final dispatchLiveFeedProvider = Provider.autoDispose<void>((ref) {
  final controller = DispatchLiveFeedController(
    ref.watch(dispatchHubClientProvider),
    onFeedChanged: () {
      ref.invalidate(availableBookingsProvider);
      ref.invalidate(workerBookingsProvider);
    },
  );
  controller.start();
  ref.onDispose(() {
    controller.stop();
  });
});

/// Keeps the client's booking list (`bookingsProvider` — the active-booking bar and "Đơn của tôi"
/// list both read it) fresh as the worker moves a booking through its statuses, even when the
/// client isn't on that specific booking's detail screen. Backed by the client's always-joined
/// `client:{clientId}` SignalR group (auto-joined server-side on connect — no per-booking
/// SubscribeBooking call needed, unlike BookingDetailScreen's own live-update wiring).
final clientBookingsLiveFeedProvider = Provider.autoDispose<void>((ref) {
  final client = ref.watch(dispatchHubClientProvider);
  void refresh() => ref.invalidate(bookingsProvider);

  client.onBookingStatusChanged(refresh);
  // Group membership isn't preserved across a reconnect, but OnConnectedAsync re-runs on every new
  // connection and re-joins client:{clientId} automatically — this refresh is just a defensive
  // catch-up for anything that changed while disconnected, matching BookingDetailScreen's approach.
  client.onReconnected(refresh);
  unawaited(client.connect());
});
