/// Maps an incoming https://tekka.ug/* URI to an in-app GoRouter path.
///
/// Returns null when the URI has no matching in-app destination, which lets
/// callers ignore the link (the router stays on the current screen).
///
/// Supported:
///   /listing/:id            -> /listing/:id
///   /listing/:id/*          -> /listing/:id   (strips sub-paths like /edit)
///   /chat/:id               -> /chat/:id
///   /user/:id               -> /user/:id
///   /profile                -> /profile
///   /profile/:sub           -> /profile/:sub  (settings, help, etc.)
///   /notifications          -> /notifications
///   /notifications/:id      -> /notifications/:id
///   /meetups                -> /meetups
///   /meetups/:id            -> /meetups/:id
///   /meetups/locations      -> /meetups/locations
///   /reviews/:userId        -> /reviews/:userId
///   /browse, /home, /saved  -> passthrough
String? mapDeepLinkUri(Uri uri) {
  if (uri.host.isNotEmpty &&
      uri.host != 'tekka.ug' &&
      uri.host != 'www.tekka.ug') {
    return null;
  }
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return '/home';

  final first = segments[0];
  switch (first) {
    case 'listing':
      if (segments.length >= 2) return '/listing/${segments[1]}';
      return null;
    case 'chat':
      if (segments.length >= 2) return '/chat/${segments[1]}';
      return '/chat';
    case 'user':
      if (segments.length >= 2) return '/user/${segments[1]}';
      return null;
    case 'reviews':
      if (segments.length >= 2) return '/reviews/${segments[1]}';
      return null;
    case 'notifications':
      if (segments.length >= 2) return '/notifications/${segments[1]}';
      return '/notifications';
    case 'meetups':
      if (segments.length >= 2) return '/meetups/${segments[1]}';
      return '/meetups';
    case 'profile':
      if (segments.length >= 2) return '/profile/${segments[1]}';
      return '/profile';
    case 'home':
    case 'browse':
    case 'saved':
      return '/$first';
    default:
      return null;
  }
}
