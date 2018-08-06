library angular_sentry;

import "dart:html" as html;
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import "package:sentry/sentry_browser.dart";
import "package:http/http.dart";
import "package:http/browser_client.dart";

export 'package:sentry/sentry_browser.dart';

typedef Event TransformEvent(Event e);

/// Use to transform the event before sending to sentry
/// add tags or extra for example
const sentryTransformEventToken = OpaqueToken<TransformEvent>(
  'sentry.transformEvent',
);

/// provide environment data to the sentry report
const sentryEnvironmentToken = OpaqueToken<String>('sentry.env');

/// The release version of the application.
const sentryReleaseVersionToken = OpaqueToken<String>('sentry.release');

/// Pass Logger to sentry
/// If no logger, it will print exception to console
const sentryLoggerToken = OpaqueToken<Logger>('sentry.logger');

/// Provide sentry dsn
/// If no dsn provided, it will log the exception without reporting it to sentry
const sentryDsnToken = OpaqueToken<String>('sentry.dsn');

class AngularSentry implements ExceptionHandler {
  final Logger log;
  final String environment;
  final String release;
  final String dsn;
  final Client client;
  final TransformEvent eventTransformer;
  final _exceptionController = new StreamController<Event>.broadcast();
  final NgZone zone;

  Stream<Event> _onException;
  SentryClientBrowser _sentry;
  ApplicationRef _appRef;

  AngularSentry(
    Injector injector,
    this.zone, {
    @Optional() this.client,
    @Optional() @Inject(sentryDsnToken) this.dsn,
    @Optional() @Inject(sentryLoggerToken) this.log,
    @Optional() @Inject(sentryEnvironmentToken) this.environment,
    @Optional() @Inject(sentryReleaseVersionToken) this.release,
    @Optional() @Inject(sentryTransformEventToken) this.eventTransformer,
  }) {
    // prevent DI circular dependency
    new Future<Null>.delayed(Duration.zero, () {
      _appRef = injector.get(ApplicationRef) as ApplicationRef;
    });

    _onException =
        _exceptionController.stream.map(transformEvent).where((e) => e != null);

    _onException.listen(_sendEvent, onError: logError);

    zone.runOutsideAngular(_initSentry);
  }

  void _initSentry() {
    if (dsn == null) return;

    try {
      _sentry = new SentryClientBrowser(
          dsn: dsn,
          httpClient: client ?? new BrowserClient(),
          environmentAttributes: Event(
            environment: environment,
            release: release,
          ));
    } catch (e, s) {
      logError(e, s);
    }
  }

  void _sendEvent(Event e) => zone.runOutsideAngular(() {
        try {
          _sentry?.capture(event: e);
        } catch (e, s) {
          logError(e, s);
        }
      });

  /// onException stream after [transformEvent] call
  Stream<Event> get onException => _onException;

  /// can be override to transform sentry report
  /// adding tags or extra for example
  @protected
  @mustCallSuper
  Event transformEvent(Event e) => zone.runOutsideAngular(() {
        try {
          if (eventTransformer == null) return e;

          return eventTransformer(e);
        } catch (e, s) {
          logError(e, s);
        }
      });

  /// Log the catched error using Logging
  /// if no logger provided, print into console with window.console.error
  void logError(exception, [stackTrace, String reason]) {
    if (log != null) {
      log.severe(reason, exception, stackTrace);
    } else {
      logErrorWindow(exception, stackTrace, reason);
    }
  }

  /// log error using window.console.error
  void logErrorWindow(exception, [stackTrace, String reason]) {
    if (reason != null) html.window.console.error(reason);

    html.window.console.error(exception);

    if (stackTrace != null) html.window.console.error(stackTrace);
  }

  @protected
  @mustCallSuper
  void capture(dynamic exception, [dynamic stackTrace, String reason]) =>
      _exceptionController.add(Event(
        exception: exception,
        stackTrace: stackTrace,
        message: reason,
      ));

  @override
  @protected
  void call(dynamic exception, [dynamic stackTrace, String reason]) {
    logError(exception, stackTrace, reason);
    capture(exception, stackTrace, reason);

    // not sure about this
    // the application state might not be clean
    _appRef?.tick();
  }

  void dispose() {
    _exceptionController.close();
  }
}
