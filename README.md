# angular_sentry

Helper to implements [sentry.io](https://sentry.io) with Angular.

## Usage

### Basic

```dart
import "package:angular/angular.dart";
import 'package:sentry/sentry.dart';
import "package:angular_sentry/angular_sentry.dart";

// ignore: uri_has_not_been_generated
import 'main.template.dart' as ng;

SentryClient sentryProdider() => SentryClient(
      dsn: "YOUR_DSN",
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
  runApp(appComponentNgFactory, createInjector: scannerApp);
}
```

### Advanced

Implement your own class using AngularSentry

```dart
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

const sentryModule = Module(provide: [
  FactoryProvider(SentryClient, sentryProdider),
  ClassProvider(ExceptionHandler, useClass: AppSentry),
]);

main() {
  runApp(appComponentNgFactory, createInjector: scannerApp);
}
```
