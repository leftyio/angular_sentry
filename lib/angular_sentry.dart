library angular_sentry;

import "dart:html" as html;
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import "package:sentry/sentry.dart";
import "package:http/browser_client.dart";

const OpaqueToken sentryDsn = const OpaqueToken('sentryDSN');

@Injectable()
class AngularSentry implements ExceptionHandler {
  SentryClient _sentry;
  Logger _log;
  Logger get log => _log;
  ApplicationRef _appRef;

  AngularSentry(Injector injector, @Optional() @Inject(sentryDsn) String dsn,
      @Optional() BrowserClient client) {
    if (dsn != null) {
      _sentry = new SentryClient(
          dsn: dsn,
          compressPayload: false,
          httpClient: client ?? new BrowserClient());
    }

    _log = new Logger("$runtimeType");
    // prevent DI circular dependency
    new Future<Null>.delayed(Duration.zero, () {
      _appRef = injector.get(ApplicationRef) as ApplicationRef;
    });
  }

  void onCatch(dynamic exception, [dynamic stackTrace, String reason]) {
    try {
      _send(exception, stackTrace, reason);
    } catch (e, s) {
      logError(e, s);
      // do nothing;
    }
  }

  /// Log the catched error using Logging
  /// Called before onCatch
  void logError(dynamic exception, [dynamic stackTrace, String reason]) {
    _log.severe(() => ExceptionHandler.exceptionToString(
          exception,
          stackTrace,
          reason,
        ));
  }

  @override
  void call(dynamic exception, [dynamic stackTrace, String reason]) {
    logError(exception, stackTrace, reason);
    onCatch(exception, stackTrace, reason);
    _appRef?.tick();
  }

  /// provide environment data to the sentry report
  String get environment => null;

  Map<String, String> get tags => {
        "userAgent": html.window.navigator.userAgent,
        "platform": html.window.navigator.platform
      };

  /// The release version of the application.
  String get release => null;

  /// provide extra data to the sentry report
  Map<String, String> get extra => null;

  void _send(dynamic exception, [dynamic stackTrace, String reason]) {
    final event = new Event(
        exception: exception,
        stackTrace: stackTrace,
        release: release,
        environment: environment,
        extra: extra,
        tags: tags,
        message: reason);
    _sentry?.capture(event: event);
  }
}
