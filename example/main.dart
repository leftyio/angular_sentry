import 'dart:html' hide Event;

import "package:angular/angular.dart";
import "package:angular_sentry/angular_sentry.dart";
import 'package:http/http.dart';

// ignore: uri_has_not_been_generated
import 'main.template.dart' as ng;

// ignore: uri_has_not_been_generated
import 'app.template.dart' as app;

Event _transformEvent(Event e) {
  return e.copyWith(
    userContext: new User(id: '1', ipAddress: '0.0.0.0'),
    extra: {"location_url": window.location.href},
  );
}

const sentryModule = Module(provide: [
  ValueProvider.forToken(sentryLoggerToken, "MY_SENTRY_DSN"),
  ValueProvider.forToken(sentryEnvironmentToken, "production"),
  ValueProvider.forToken(sentryReleaseVersionToken, "1.0.0"),
  ValueProvider.forToken(sentryTransformEventToken, _transformEvent),
  ClassProvider<ExceptionHandler>(
    ExceptionHandler,
    useClass: AngularSentry,
  ),
]);

@GenerateInjector(
  [sentryModule],
)
const scannerApp = ng.scannerApp$Injector;

main() {
  runApp(app.AppComponentNgFactory, createInjector: scannerApp);
}

class AppSentry extends AngularSentry {
  AppSentry(Injector injector)
      : super(
          injector,
          //dsn: "MY_SENTRY_DSN",
          environment: "production",
          release: "1.0.0",
        );

  @override
  Event transformEvent(Event e) {
    return _transformEvent(super.transformEvent(e));
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
