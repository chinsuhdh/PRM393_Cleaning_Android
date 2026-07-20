import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../core/network/dio_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/dispatch_repository.dart';

abstract class DispatchHubClient {
  Future<void> connect();
  Future<void> disconnect();
  void onJobPosted(void Function() handler);
  void onJobTaken(void Function() handler);
  void onJobCancelled(void Function() handler);

  void onReconnected(void Function() handler);
  void onDisconnected(void Function() handler);

  Future<void> subscribeToBooking(String bookingId);
  void onBookingStatusChanged(void Function() handler);

  void onWorkerPosition(void Function(double lat, double lng) handler);

  void onNearbyWorkersUpdated(void Function(List<({double lat, double lng})> locations) handler);
  void onReceiveMessage(void Function(Map<String, dynamic> msg) handler);
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
  void onDisconnected(void Function() handler) => _connection.onclose(({error}) => handler());

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

  @override
  void onReceiveMessage(void Function(Map<String, dynamic> msg) handler) {
    _connection.on('receiveMessage', (args) {
      final raw = (args != null && args.isNotEmpty) ? args[0] : null;
      if (raw is Map) {
        handler(Map<String, dynamic>.from(raw));
      }
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
  DispatchLiveFeedController(
    this._client, {
    required this.onFeedChanged,
    this.onBeforeRetry,
    this.retryDelay = const Duration(seconds: 10),
  });

  final DispatchHubClient _client;
  final void Function() onFeedChanged;
  // Access tokens expire in 15 minutes (JwtConfig:AccessTokenExpirationMinutes) and nothing else
  // proactively refreshes one while a worker just idles on Available Jobs with no REST calls firing —
  // so a reconnect attempt after that window presents an already-expired JWT and the hub's [Authorize]
  // rejects it. Called before every RETRY (not the very first connect in start()) so a stale token gets
  // refreshed before it can cause a permanently-failing reconnect loop.
  final Future<void> Function()? onBeforeRetry;
  final Duration retryDelay;
  bool _stopped = false;
  Timer? _retryTimer;

  Future<void> start() async {
    _client.onJobPosted(onFeedChanged);
    _client.onJobTaken(onFeedChanged);
    _client.onJobCancelled(onFeedChanged);
    _client.onReconnected(onFeedChanged);
    // withAutomaticReconnect() only covers drops after a connection was established at least once,
    // and it eventually gives up retrying — onDisconnected fires whenever the connection ends up
    // Disconnected either way, so this is the single place that keeps trying to get the live feed
    // back instead of leaving the worker stuck on manual pull-to-refresh for the rest of the session.
    _client.onDisconnected(_scheduleReconnect);
    await _connectWithRetry();
  }

  Future<void> _connectWithRetry({bool refreshFirst = false}) async {
    if (_stopped) return;
    if (refreshFirst) {
      try {
        await onBeforeRetry?.call();
      } catch (_) {
        // Best-effort — if the refresh itself fails, still attempt to connect with whatever
        // token is currently set; a failure there just schedules another retry as usual.
      }
    }
    try {
      await _client.connect();
    } catch (_) {
      // Best-effort: the Available Jobs feed still works via REST pull-to-refresh without live
      // updates (same tolerance as WorkerRepository.updateLocation's background pings) — but keep
      // retrying in the background instead of giving up on live updates for the rest of the session.
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(retryDelay, () => _connectWithRetry(refreshFirst: true));
  }

  Future<void> stop() async {
    _stopped = true;
    _retryTimer?.cancel();
    await _client.disconnect();
  }
}


final dispatchLiveFeedProvider = Provider.autoDispose<void>((ref) {
  final controller = DispatchLiveFeedController(
    ref.watch(dispatchHubClientProvider),
    onFeedChanged: () {
      ref.invalidate(availableBookingsProvider);
      ref.invalidate(workerBookingsProvider);
    },
    onBeforeRetry: () => ref.read(authProvider.notifier).refreshToken(),
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
