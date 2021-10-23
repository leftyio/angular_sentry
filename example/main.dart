import 'dart:async';
import 'dart:html' hide Event;

import "package:angular/angular.dart";
import 'package:sentry/sentry.dart';
import "package:angular_sentry/angular_sentry.dart";

// ignore: uri_has_not_been_generated
import 'main.template.dart' as ng;

// ignore: uri_has_not_been_generated
import 'app.template.dart' as app;

const sentryModule = Module(provide: [
  ClassProvider(ExceptionHandler, useClass: AngularSentry),
]);

@GenerateInjector([sentryModule])
const scannerApp = ng.scannerApp$Injector;

Future<void> main() async {
  await Sentry.init(
    (options) {
      options.dsn = 'https://example@sentry.io/add-your-dsn-here';
      options.environment = 'production';
      options.release = '1.0.0';
    },
    appRunner: initApp,
  );
}

void initApp() {
  runApp(app.AppComponentNgFactory, createInjector: scannerApp);
}

class AppSentry extends AngularSentry {
  @override
  SentryEvent transformEvent(SentryEvent e) {
    return super.transformEvent(e).copyWith(
      user: SentryUser(id: '1', ipAddress: '0.0.0.0'),
      extra: {"location_url": window.location.href},
    );
  }
}
