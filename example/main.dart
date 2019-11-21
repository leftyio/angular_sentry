import 'dart:html' hide Event;

import "package:angular/angular.dart";
import 'package:http/http.dart';
import 'package:sentry/sentry.dart';
import "package:angular_sentry/angular_sentry.dart";

// ignore: uri_has_not_been_generated
import 'main.template.dart' as ng;

// ignore: uri_has_not_been_generated
import 'app.template.dart' as app;

SentryClient sentryProdider() => SentryClient(
      dsn: "https://public:secret@sentry.example.com/1",
      environmentAttributes: Event(
        environment: 'production',
        release: '1.0.0',
      ),
    );

const sentryModule = Module(provide: [
  FactoryProvider(SentryClient, sentryProdider),
  ClassProvider(ExceptionHandler, useClass: AngularSentry),
]);

@GenerateInjector([sentryModule])
const scannerApp = ng.scannerApp$Injector;

main() {
  runApp(app.AppComponentNgFactory, createInjector: scannerApp);
}

class AppSentry extends AngularSentry {
  AppSentry(SentryClient client) : super(client);

  @override
  Event transformEvent(Event e) {
    return super.transformEvent(e).copyWith(
      userContext: new User(id: '1', ipAddress: '0.0.0.0'),
      extra: {"location_url": window.location.href},
    );
  }

  @override
  void capture(exception, [trace, String reason]) {
    if (exception is ClientException) {
      logError("Network error");
    } else {
      super.capture(exception, trace, reason);
    }
  }
}
