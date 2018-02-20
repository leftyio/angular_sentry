# angular_sentry

Helper to implements sentry with Angular.

## Usage

### Basic

```dart
import "package:angular/angular.dart";
import "package:angular_sentry/angular_sentry.dart";

main() {
  bootstrap(MyApp, [
    provide(SENTRY_DSN, useValue: "MY_SENTRY_DSN"),
    provide(ExceptionHandler, useClass: AngularSentry)
  ]);
}

```

### Advanced

```dart

main() {
  bootstrap(MyApp, [
    AppSentry
  ]);
}

@Injectable()
class AppSentry extends AngularSentry {
  AppSentry(Injector injector)
      : super(injector, "MY_SENTRY_DSN");

  SentryUser get user => new SentryUser();

  String get environment => "production";

  String get release => "1.0.0";

  Map<String, String> get extra => {"location_url": window.location.href};

  void onCatch(dynamic exception, Trace trace, [String reason]) {
    if (exception is ClientException) {
      log("Network error");
    } else {
      super.onCatch(exception, trace, reason);
    }
  }
}

```
