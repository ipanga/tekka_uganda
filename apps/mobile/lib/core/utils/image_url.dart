/// Force a remote image URL to HTTPS. iOS App Transport Security is locked
/// to HTTPS-only (`NSAllowsArbitraryLoads = false` in `Runner/Info.plist`),
/// so any legacy `http://` row in the DB renders as a broken image on iOS
/// while still loading on older Android builds with cleartext enabled.
/// No-op for already-secure URLs.
String toHttps(String url) =>
    url.startsWith('http://') ? 'https://${url.substring(7)}' : url;

String? toHttpsOrNull(Object? url) {
  if (url is! String) return null;
  return toHttps(url);
}
