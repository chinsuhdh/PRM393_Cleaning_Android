import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../core/network/dio_client.dart';
import '../repositories/booking_repository.dart';

/// Client side of the E-T3/E-T4 dispatch broadcast (MASTER_FEATURE_SPEC.md § E.3): the backend's
/// `DispatchHub` already sends `jobPosted`/`jobTaken`/`jobCancelled` to each eligible worker's group
/// whenever a booking enters or leaves `AwaitingWorker`. This is the abstraction the live-feed
/// controller talks to, so it can be faked in tests instead of opening a real socket.
abstract class DispatchHubClient {
  Future<void> connect();
  Future<void> disconnect();
  void onJobPosted(void Function() handler);
  void onJobTaken(void Function() handler);
  void onJobCancelled(void Function() handler);
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

  static String? _bearerToken(Dio dio) =>
      (dio.options.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');

  /// The API base URL is `.../api`; the hub is mounted at the API root (`Program.cs`:
  /// `app.MapHub<DispatchHub>("/hubs/dispatch")`), so the `/api` suffix has to come off.
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

/// Turns hub pushes into Available Jobs feed refreshes. Per § E.3's reconnect strategy the feed is
/// "eventually consistent with the REST list, never the source of truth" — so every event is just a
/// signal to refetch `availableBookingsProvider`, not a payload to merge client-side.
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

/// Watch this from the Available Jobs / My Jobs / dashboard screens to keep the dispatch hub connected
/// for as long as they're visible; disposed automatically (and the socket closed) once nothing watches
/// it anymore. Every event refreshes both the eligible-worker feed and the worker's own booking list —
/// a jobCancelled push can be about a job the worker never accepted (drop it from the browse feed) or
/// one they already had (drop it from My Jobs / the active-job bar), and there's no cheap way to tell
/// which from here, so both just refetch (§ E.3: "eventually consistent... never the source of truth").
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
