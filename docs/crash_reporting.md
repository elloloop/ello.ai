# Crash Reporting Integration

This document describes the crash reporting and error tracking implementation for the ello.ai Flutter app.

## Overview

The app now includes comprehensive crash reporting and error tracking using Sentry. This helps with debugging issues and providing better user support.

## Features

- **Automatic crash reporting**: Unhandled exceptions and Flutter framework errors are automatically reported
- **Enhanced logging**: All error logs are also sent to Sentry for monitoring
- **Breadcrumb tracking**: Debug and info logs are added as breadcrumbs for better error context
- **User-friendly error handling**: Users see helpful error messages instead of raw Flutter error widgets
- **Configurable reporting**: Can be enabled/disabled via environment variables

## Configuration

### Environment Variables

- `SENTRY_DSN`: Your Sentry project's Data Source Name (DSN). If not provided, crash reporting is disabled.
- `APP_VERSION`: Application version for release tracking (defaults to '0.1.0')

### Example Configuration

```bash
# For development
export SENTRY_DSN="https://your-sentry-dsn@sentry.io/project-id"
export APP_VERSION="0.1.0-dev"

# For production
export SENTRY_DSN="https://your-production-sentry-dsn@sentry.io/project-id"
export APP_VERSION="0.1.0"
```

## Usage

### Automatic Reporting

Most errors are automatically reported:
- Unhandled exceptions in Flutter framework
- Widget build errors
- Errors logged through the `Logger` utility

### Manual Reporting

You can manually report errors or events:

```dart
import 'package:ello_ai/src/services/crash_reporting_service.dart';

// Report an error
await CrashReportingService.reportError(
  exception,
  stackTrace,
  message: 'Custom error message',
  extra: {'userId': '123', 'action': 'send_message'},
);

// Report a message
await CrashReportingService.reportMessage(
  'User completed onboarding',
  level: SentryLevel.info,
  extra: {'completionTime': 120}, // seconds
);

// Add breadcrumb for context
CrashReportingService.addBreadcrumb(
  'User opened settings',
  category: 'navigation',
  data: {'screen': 'settings'},
);

// Set user context
CrashReportingService.setUser(
  id: 'user-123',
  username: 'johndoe',
  extras: {'subscription': 'premium'},
);
```

### Enhanced Logger

The existing `Logger` utility now automatically integrates with crash reporting:

```dart
import 'package:ello_ai/src/utils/logger.dart';

// These automatically add breadcrumbs
Logger.debug('Debug message', extra: {'key': 'value'});
Logger.info('Info message', extra: {'key': 'value'});

// These report to Sentry
Logger.warning('Warning message', extra: {'key': 'value'});
Logger.error('Error message', 
  exception: exception, 
  stackTrace: stackTrace,
  extra: {'key': 'value'},
);
```

## Integration Points

### Main Application (`lib/main.dart`)

- Initializes crash reporting service on startup
- Wraps the app with Sentry error handling
- Provides user-friendly error widgets for build failures

### Enhanced Logger (`lib/src/utils/logger.dart`)

- All logging methods now support additional context via `extra` parameter
- Error and warning logs are automatically reported to Sentry
- Debug and info logs are added as breadcrumbs for context

### Error Handling (`lib/src/core/dependencies.dart`)

- Chat stream errors include additional context (client type, message count, etc.)
- Connection errors provide operation context
- All critical errors are properly tracked

## Privacy and Security

- Only errors and specified metadata are sent to Sentry
- User data is only included when explicitly set via `setUser()`
- Debug information is only collected in debug builds
- Sample rate is reduced in production (10% vs 100% in development)

## Testing

Run the crash reporting tests to ensure integration works correctly:

```bash
flutter test test/crash_reporting_test.dart
```

## Troubleshooting

### Crash reporting not working

1. Check that `SENTRY_DSN` environment variable is set
2. Verify the DSN is correct for your Sentry project
3. Check debug logs for initialization messages
4. Ensure network connectivity for reporting

### Too many reports

1. Adjust the sample rate in `CrashReportingService.initialize()`
2. Filter out specific error types if needed
3. Use different environments for development vs production

### Missing context

1. Add more breadcrumbs at key user actions
2. Set user context when user information is available
3. Include relevant state in error extra data

## Best Practices

1. **Don't log sensitive data**: Avoid including passwords, tokens, or personal information in error reports
2. **Add context gradually**: Start with basic error reporting and add more context as needed
3. **Use appropriate log levels**: Use error for actual problems, warning for potential issues, info for important events
4. **Test error scenarios**: Ensure error handling works correctly in various failure conditions
5. **Monitor regularly**: Check Sentry dashboard regularly for new issues and trends