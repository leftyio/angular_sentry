library angular_sentry;

import 'dart:async';
import "dart:html" as html;

import 'package:meta/meta.dart';
import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import "package:sentry/sentry.dart";

export 'package:sentry/browser_client.dart';

typedef Event TransformEvent(Event e);

const _breadcrumbsLimit = 30;

class AngularSentry implements ExceptionHandler {
  final log = Logger('AngularSentry');
  final SentryClient sentryClient;

  StreamSubscription<Breadcrumb> _loggerListener;
  List<Breadcrumb> _breadcrumbs = [];

  AngularSentry(this.sentryClient) {
    _loggerListener =
        Logger.root.onRecord.map(_recordToBreadcrumb).listen(_buildBreadcrumbs);
  }

  /// can be override to transform sentry report
  /// adding tags or extra for example
  ///
  /// Example
  ///     ```dart
  ///     @override
  ///     Event transformEvent(Event e) {
  ///       return super.transformEvent(e).copyWith(
  ///         userContext: User(id: '1', ipAddress: '0.0.0.0'),
  ///         extra: {"location_url": window.location.href},
  ///       );
  ///     }
  ///     ```
  @protected
  @mustCallSuper
  Event transformEvent(Event e) => e;

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
    if (reason != null) html.window.console.error(reason.toString());

    html.window.console.error(exception.toString());

    if (stackTrace != null) html.window.console.error(stackTrace.toString());
  }

  @protected
  @mustCallSuper
  void capture(dynamic exception, [dynamic stackTrace, String reason]) {
    final event = transformEvent(
      Event(
        exception: exception,
        stackTrace: stackTrace,
        message: reason,
        breadcrumbs: _breadcrumbs,
      ),
    );

    if (event == null) return;

    sentryClient.capture(event: event).catchError(logError);
  }

  @override
  @protected
  void call(dynamic exception, [dynamic stackTrace, String reason]) {
    logError(exception, stackTrace, reason);
    capture(exception, stackTrace, reason);
  }

  void dispose() {
    _loggerListener.cancel();
  }

  void _buildBreadcrumbs(Breadcrumb event) {
    if (_breadcrumbs.length >= _breadcrumbsLimit) {
      _breadcrumbs.removeAt(0);
    }
    _breadcrumbs.add(event);
  }
}

SeverityLevel _logLevelToSeverityLevel(Level level) {
  if (level == Level.WARNING) {
    return SeverityLevel.warning;
  }

  if (level == Level.SEVERE) {
    return SeverityLevel.error;
  }

  if (level == Level.SHOUT) {
    return SeverityLevel.fatal;
  }

  return SeverityLevel.info;
}

Breadcrumb _recordToBreadcrumb(LogRecord record) => Breadcrumb(
      record.message,
      record.time,
      level: _logLevelToSeverityLevel(record.level),
      category: record.loggerName,
    );
