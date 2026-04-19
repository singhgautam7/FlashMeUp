/// Strips common Markdown syntax to return plain readable text.
/// Used for table view descriptions and card previews.
String stripMarkdown(String markdown) {
  var text = markdown
      .replaceAll(RegExp(r'#{1,6}\s*'), '')
      .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
      .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
      .replaceAll(RegExp(r'`(.+?)`'), r'$1')
      .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1')
      .replaceAll(RegExp(r'^\s*[-*>]\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\n+'), ' ')
      .trim();
  return text;
}
