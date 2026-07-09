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

  Future<void> subscribeToBooking(String bookingId);
  void onBookingStatusChanged(void Function() handler);

  /// F.2/F.3: the assigned worker's live position while `OnTheWay`, pushed on the `booking:{id}`
  /// group every time the worker's device sends a location update — replaces the client's REST poll.
  void onWorkerPosition(void Function(double lat, double lng) handler);

  /// E.6/E.9: anonymous eligible-worker positions for a searching client, pushed on the same group
  /// every ~60s — replaces the client's REST poll on the finding-worker map.
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
  Future<void> connect() async => _connection.start();

  @override
  Future<void> disconnect() => _connection.stop();

  @override
  void onJobPosted(void Function() handler) => _connection.on('jobPosted', (_) => handler());

  @override
  void onJobTaken(void Function() handler) => _connection.on('jobTaken', (_) => handler());

  @override
  void onJobCancelled(void Function() handler) => _connection.on('jobCancelled', (_) => handler());

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
