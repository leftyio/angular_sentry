[![Dart](https://github.com/leftyio/angular_sentry/actions/workflows/dart.yml/badge.svg)](https://github.com/leftyio/angular_sentry/actions/workflows/dart.yml)

# angular_sentry

Helper to implements [sentry.io](https://sentry.io) with Angular.

## Usage

### Inject Angular Sentry

```dart
import "package:angular/angular.dart";
import "package:angular_sentry/angular_sentry.dart";

// ignore: uri_has_not_been_generated
import 'main.template.dart' as ng;

const sentryModule = Module(provide: [
  ClassProvider(ExceptionHandler, useClass: AngularSentry),
]);

@GenerateInjector([sentryModule])
const scannerApp = ng.scannerApp$Injector;
```

### Init Sentry and run your app

```dart
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
  runApp(ng.AppComponentNgFactory, createInjector: scannerApp);
}
```

### Advanced

Implement your own class using AngularSentry

```dart
class AppSentry extends AngularSentry {
  @override
  Event transformEvent(SentryEvent e) {
    return super.transformEvent(e).copyWith(
      user: SentryUser(id: '1', ipAddress: '0.0.0.0'),
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
