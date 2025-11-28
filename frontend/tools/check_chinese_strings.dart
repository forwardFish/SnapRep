import 'dart:io';

/// Automated checker for Chinese strings in Dart code
/// This script scans all .dart files and reports Chinese strings outside comments
void main() async {
  print('🔍 Scanning for Chinese strings in code...\n');

  final lib = Directory('lib');
  final violations = <String>[];

  await for (final file in lib.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart') && !file.path.contains('.backup')) {
      final content = await file.readAsString();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lineNumber = i + 1;

        // Skip if line is a comment
        final trimmed = line.trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('///') || trimmed.startsWith('*')) {
          continue;
        }

        // Check for Chinese characters in code (not in comments)
        final chinesePattern = RegExp(r'[\u4e00-\u9fff]+');
        final matches = chinesePattern.allMatches(line);

        for (final match in matches) {
          // Check if it's inside a comment
          final beforeMatch = line.substring(0, match.start);
          if (beforeMatch.contains('//') || beforeMatch.contains('/*')) {
            continue; // It's in a comment, skip
          }

          // It's a violation - Chinese in code
          final chineseText = match.group(0);
          violations.add('${file.path}:$lineNumber - "$chineseText"');
        }
      }
    }
  }

  if (violations.isEmpty) {
    print('✅ No Chinese strings found in code! Great job!');
  } else {
    print('❌ Found ${violations.length} violations:\n');
    for (final violation in violations) {
      print('  $violation');
    }
    print('\n💡 Please replace all Chinese strings with English equivalents.');
    print('   Chinese is only allowed in comments (// or /// or /* */)');
    exit(1);
  }
}
