# Changelog

## 0.0.8-alpha+1

- support Angular 6

## 0.0.7

- Fix logger
- remove logErrorWindow
- Breadcrumbs size limit can be set by injecting value with token `breadcrumbsLimit`

## 0.0.6

- Fix Breadcrumb message
- Upgrade sentry package to 3.0.0+1

## 0.0.5

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
