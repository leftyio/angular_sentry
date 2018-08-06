# Changelog

## 0.1.0

- Update angular 5
- Update sentry package
- ***Warning*** refactoring ***Breaking Change***:
    + use OpaqueToken to pass release version, environment, dsn and logger
        sentryEnvironmentToken,sentryReleaseVersionToken, sentryLoggerToken, sentryDsnToken
    + no more tags and extra field, override `transformEvent` function instead
    + rename `onCatch` to `capture`

## 0.0.4

- update sentry package to 1.0.0

## 0.0.3

- fix logger
- fix stacktrace parsing

## 0.0.2

- Use `sentry` package instead of `sentry_client`

## 0.0.1

- Initial version, created by Stagehand
