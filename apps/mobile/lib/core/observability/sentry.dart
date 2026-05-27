import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/environment.dart';

/// Reads at build time. Pass via `--dart-define=SENTRY_DSN=...`. Empty string
/// when not provided — in that case [initSentry] becomes a thin pass-through.
const String _dsn = String.fromEnvironment('SENTRY_DSN');

/// Release tag (CI populates from `pubspec.yaml` version + git short SHA).
/// Empty in local builds — Sentry then groups events under "unknown release".
const String _release = String.fromEnvironment(
  'SENTRY_RELEASE',
  defaultValue: '',
);

bool get _sentryEnabled => _dsn.isNotEmpty;

String _environmentName() {
  if (EnvironmentConfig.isStaging) return 'staging';
  if (EnvironmentConfig.isDev) return 'development';
  return 'production';
}

/// Wraps app boot in Sentry's error-capturing zone.
///
/// Falls through to a plain `appRunner()` call when no DSN is configured
/// (e.g. local debug builds without `--dart-define=SENTRY_DSN=...`). That
/// keeps the dev flavor's launch time identical to before Sentry landed.
///
/// On supported builds, this hooks `FlutterError.onError`,
/// `PlatformDispatcher.instance.onError`, and the platform's native crash
/// handlers (NDK on Android, KSCrash on iOS) before `appRunner` runs.
Future<void> initSentry(Future<void> Function() appRunner) async {
  if (!_sentryEnabled) {
    await appRunner();
    return;
  }

  final isProd = EnvironmentConfig.isProd;

  await SentryFlutter.init((options) {
    options.dsn = _dsn;
    options.environment = _environmentName();
    if (_release.isNotEmpty) options.release = _release;

    // Performance + profiling. 10% in prod, 100% in dev/staging.
    options.tracesSampleRate = isProd ? 0.1 : 1.0;
    // ignore: experimental_member_use
    options.profilesSampleRate = isProd ? 0.1 : 1.0;

    // PII safety. `sendDefaultPii: false` keeps Dio + URL captures from
    // including auth headers, cookies, and query strings. Screenshots
    // and view hierarchies disabled — they often capture text fields
    // mid-typing (OTP digits, phone numbers).
    options.sendDefaultPii = false;
    options.attachScreenshot = false;
    // ignore: experimental_member_use
    options.attachViewHierarchy = false;

    // Breadcrumbs from `print`/`debugPrint` can include phone numbers
    // and tokens from the existing log statements. Keep them out of
    // Sentry — local stdout is still fine for ops.
    options.enablePrintBreadcrumbs = false;

    options.beforeSend = _beforeSend;
  }, appRunner: appRunner);
}

// =============================================================================
// PII scrubber — same key list as apps/api/src/instrument.ts and the two
// Next.js apps. Keep in lockstep.
// =============================================================================

final Set<String> _sensitiveKeys = {
  'password',
  'token',
  'accesstoken',
  'refreshtoken',
  'authorization',
  'cookie',
  'set-cookie',
  'code',
  'otp',
  'verificationid',
  'phonenumber',
  'phone',
  'email',
  'twofactorsecret',
  'twofactorpendingsecret',
  'twofactorbackupcodes',
  'backupcodes',
};

const _dropExceptionTypes = {
  'HandshakeException',
  'SocketException',
  'TimeoutException',
  'DioException',
};

FutureOr<SentryEvent?> _beforeSend(SentryEvent event, Hint hint) {
  // Drop transient network noise — these are not bugs, they're user
  // connectivity. Capturing them eats quota and masks real signals.
  final type = event.exceptions?.firstOrNull?.type;
  if (type != null && _dropExceptionTypes.contains(type)) return null;

  // Scrub event payload in place. SentryEvent exposes mutable maps for
  // tags and breadcrumb data, so we walk and redact. `extra` is the
  // legacy structured-data field on SentryEvent — Sentry recommends
  // migrating to Contexts long-term, but the field is still emitted by
  // older integrations so we scrub it defensively.
  // ignore: deprecated_member_use
  if (event.extra != null) _scrubMap(event.extra!);
  if (event.tags != null) _scrubStringMap(event.tags!);

  if (event.breadcrumbs != null) {
    for (final crumb in event.breadcrumbs!) {
      if (crumb.data != null) _scrubMap(crumb.data!);
    }
  }

  return event;
}

void _scrubMap(Map<String, dynamic> input) {
  for (final key in input.keys.toList()) {
    if (_sensitiveKeys.contains(key.toLowerCase())) {
      input[key] = '[Filtered]';
      continue;
    }
    final value = input[key];
    if (value is Map<String, dynamic>) {
      _scrubMap(value);
    } else if (value is Map) {
      _scrubMap(Map<String, dynamic>.from(value));
    } else if (value is List) {
      for (final item in value) {
        if (item is Map<String, dynamic>) _scrubMap(item);
      }
    }
  }
}

void _scrubStringMap(Map<String, String> input) {
  for (final key in input.keys.toList()) {
    if (_sensitiveKeys.contains(key.toLowerCase())) {
      input[key] = '[Filtered]';
    }
  }
}
