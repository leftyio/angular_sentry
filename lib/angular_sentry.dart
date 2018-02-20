library angular_sentry;

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:sentry_client/api_data/sentry_exception.dart';
import 'package:sentry_client/api_data/sentry_packet.dart';
import 'package:sentry_client/api_data/sentry_stacktrace.dart';
import 'package:sentry_client/api_data/sentry_stacktrace_frame.dart';
import 'package:sentry_client/api_data/sentry_user.dart';
import 'package:sentry_client/sentry_client_browser.dart';
import 'package:sentry_client/sentry_dsn.dart';
import 'package:stack_trace/stack_trace.dart';

export 'package:sentry_client/api_data/sentry_user.dart';
export 'package:stack_trace/stack_trace.dart';

const OpaqueToken SENTRY_DSN = const OpaqueToken('sentryDSN');

@Injectable()
class AngularSentry implements ExceptionHandler {
  SentryClientBrowser _sentry;
  Logger _log;
  Logger get log => _log;
  ApplicationRef _appRef;

  AngularSentry(
      Injector injector, @Optional() @Inject(SENTRY_DSN) String sentryDSN) {
    if (sentryDSN != null) {
      _sentry = new SentryClientBrowser(
          SentryDsn.fromString(sentryDSN, allowSecretKey: true));
    }

    _log = new Logger("$runtimeType");
    // prevent DI circular dependency
    new Future<Null>.delayed(Duration.ZERO, () {
      _appRef = injector.get(ApplicationRef) as ApplicationRef;
    });
  }

  void onCatch(dynamic exception, Trace trace, [String reason]) {
    try {
      _send(exception, trace);
    } catch (e, s) {
      logError(e, s);
      // do nothing;
    }
  }

  /// Log the catched error using Logging
  /// Called before onCatch
  void logError(dynamic exception, Trace trace, [String reason]) {
    _log.severe(ExceptionHandler.exceptionToString(
      exception,
      trace,
      reason,
    ));
  }

  @override
  void call(dynamic exception, [dynamic stackTrace, String reason]) {
    final trace = parseStackTrace(stackTrace);
    logError(exception, trace, reason);
    onCatch(exception, trace, reason);
    _appRef?.tick();
  }

  /// provide environment data to the sentry report
  String get environment => null;

  /// provide user data to the sentry report
  SentryUser get user => null;

  /// The release version of the application.
  String get release => null;

  /// provide extra data to the sentry report
  Map<String, String> get extra => null;

  void _send(dynamic exception, Trace trace) {
    final stacktraceValue = new SentryStacktrace(
        frames: trace?.frames
            ?.map((Frame frame) => new SentryStacktraceFrame(
                filename: frame?.uri?.toString(),
                package: frame?.package,
                lineno: frame?.line,
                colno: frame?.column,
                function: frame?.member,
                module: frame?.library))
            ?.toList());

    final exceptionValue = new SentryException(
        type: exception?.runtimeType?.toString(),
        value: exception?.toString(),
        stacktrace: stacktraceValue);

    final packet = new SentryPacket(
        user: user,
        environment: environment,
        release: release,
        exceptionValues: [exceptionValue],
        extra: extra);
    _sentry?.write(packet);
  }
}

Trace parseStackTrace(dynamic stackTrace) {
  if (stackTrace is StackTrace) {
    return new Trace.parse(stackTrace.toString());
  } else if (stackTrace is String) {
    return new Trace.parse(stackTrace);
  } else if (stackTrace is Iterable<Frame>) {
    return new Trace(stackTrace);
  } else if (stackTrace is Iterable<String>) {
    return new Trace(stackTrace.map(parseFrame).where((f) => f != null));
  }
  return new Trace.current();
}

Frame parseFrame(String f) {
  Frame parsed = new Frame.parseV8(f);
  if (parsed is UnparsedFrame) {
    parsed = new Frame.parseFirefox(f);
    if (parsed is UnparsedFrame) {
      try {
        return new Frame.parseFriendly(f);
      } catch (_) {
        parsed = null;
      }
    }
  }
  return null;
}