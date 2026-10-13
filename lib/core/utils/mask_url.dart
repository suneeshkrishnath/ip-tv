/// Shows only the host so the full playlist address is not exposed on screen.
String maskUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) return '••••••••';
  return '${uri.scheme}://${uri.host}/••••••••';
}
