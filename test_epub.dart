import 'dart:io';
import 'package:epubx/epubx.dart' as epub;

String stripHtmlTags(String html) {
  final bodyMatch = RegExp(r'<body[^>]*>(.*?)</body>', dotAll: true).firstMatch(html);
  String content = bodyMatch != null ? bodyMatch.group(1)! : html;
  return content
      .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
      .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
      .replaceAll(RegExp(r'<head[^>]*>.*?</head>', dotAll: true), '')
      .replaceAll(RegExp(r'<br\s*/?\s*>'), '\n')
      .replaceAll(RegExp(r'<p[^>]*>'), '\n')
      .replaceAll(RegExp(r'</p>'), '\n')
      .replaceAll(RegExp(r'<div[^>]*>'), '\n')
      .replaceAll(RegExp(r'</div>'), '\n')
      .replaceAll(RegExp(r'<h[1-6][^>]*>'), '\n')
      .replaceAll(RegExp(r'</h[1-6]>'), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'&#\d+;'), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
      .split('\n')
      .map((l) => l.trim())
      .join('\n')
      .trim();
}

void extractChapters(List<epub.EpubChapter>? chList, List<String> chapters) {
  if (chList == null) return;
  for (final ch in chList) {
    String title = ch.Title ?? '未命名章节';
    String content = '';
    if (ch.HtmlContent != null) {
      content = stripHtmlTags(ch.HtmlContent!);
    }
    final textOnly = content.replaceAll(RegExp(r'\s'), '');
    if (textOnly.isNotEmpty) {
      chapters.add('$title\n\n$content');
    }
    if (ch.SubChapters != null && ch.SubChapters!.isNotEmpty) {
      extractChapters(ch.SubChapters, chapters);
    }
  }
}

void main() async {
  final bytes = await File(r'D:\test.epub').readAsBytes();
  final book = await epub.EpubReader.readBook(bytes);
  
  print('Book: ${book.Title}');
  print('Top-level chapters: ${book.Chapters?.length ?? 0}');
  
  final chapters = <String>[];
  extractChapters(book.Chapters, chapters);
  
  print('Chapters after filter: ${chapters.length}\n');
  
  for (int i = 0; i < chapters.length && i < 3; i++) {
    final ch = chapters[i];
    final preview = ch.length > 300 ? '${ch.substring(0, 300)}...' : ch;
    print('=== Chapter $i ===');
    print(preview);
    print('');
  }
}
