library angular_sentry;

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import "package:sentry/sentry.dart";

export 'package:sentry/sentry.dart';

typedef TransformEvent = SentryEvent Function(SentryEvent e);

/// Report any error happening inside Angular scope
///
/// Listen to [Logger.root] record to build [Breadcrumbs]
/// can be disable via [AngularSentry] constructor
class AngularSentry implements ExceptionHandler {
  final log = Logger('AngularSentry');
  final bool disableBreadcrumbs;

  StreamSubscription<Breadcrumb>? _loggerListener;

  AngularSentry({this.disableBreadcrumbs = false}) {
    if (disableBreadcrumbs == false) {
      _loggerListener = Logger.root.onRecord
          .map(_logRecordToBreadcrumb)
          .listen(_buildBreadcrumbs);
    }
  }

  /// can be override to transform sentry report
  /// adding tags or extra for example
  ///
  /// Example
  ///     ```dart
  ///     @override
  ///     Event transformEvent(SentryEvent e) {
  ///       return super.transformEvent(e).copyWith(
  ///         userContext: User(id: '1', ipAddress: '0.0.0.0'),
  ///         extra: {"location_url": window.location.href},
  ///       );
  ///     }
  ///     ```
  @protected
  @mustCallSuper
  SentryEvent transformEvent(SentryEvent e) => e;

  /// Log the catched error using Logging
  void logError(exception, [stackTrace, String? reason]) {
    log.severe(reason, exception, stackTrace);
  }

  @protected
  @mustCallSuper
  void capture(dynamic exception, [dynamic stackTrace, String? reason]) {
    final event = transformEvent(
      SentryEvent(
        throwable: exception,
        timestamp: DateTime.now().toUtc(),
      ),
    );

    Sentry.captureEvent(event, stackTrace: stackTrace, hint: reason);
  }

  @override
  @protected
  void call(dynamic exception, [dynamic stackTrace, String? reason]) {
    logError(exception, stackTrace, reason);
    capture(exception, stackTrace, reason);
  }

  void dispose() {
    _loggerListener?.cancel();
  }

  void _buildBreadcrumbs(Breadcrumb crumb) {
    Sentry.addBreadcrumb(crumb);
  }
}

SentryLevel _logLevelToSeverityLevel(Level level) {
  if (level == Level.WARNING) {
    return SentryLevel.warning;
  }

  if (level == Level.SEVERE) {
    return SentryLevel.error;
  }

  if (level == Level.SHOUT) {
    return SentryLevel.fatal;
  }

  return SentryLevel.info;
}

Breadcrumb _logRecordToBreadcrumb(LogRecord record) => Breadcrumb(
      message: _normalizeMessage(record.message, record.error),
      timestamp: record.time,
      level: _logLevelToSeverityLevel(record.level),
      category: record.loggerName,
    );

String _normalizeMessage(String reason, exception) =>
    reason == 'null' || reason.isEmpty ? '$exception' : reason;
