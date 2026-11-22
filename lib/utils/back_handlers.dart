/// Screens can register a back-press handler per route; returning `true`
/// means the press was handled and default navigation should be skipped.
final Map<String, Future<bool> Function()> routeBackHandlers = {};
