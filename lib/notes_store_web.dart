import 'dart:convert';
import 'dart:html' as html;

String _storageKey(String boardId) {
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(boardId)) {
    throw ArgumentError.value(boardId, 'boardId', 'Invalid board ID');
  }
  return 'pinout-map-notes-$boardId';
}

Map<int, String> _decodeNotes(String boardId, String content) {
  final decoded = jsonDecode(content);
  if (decoded is! Map || decoded['boardId'] != boardId) {
    throw FormatException('Invalid notes data for board "$boardId".');
  }

  final notesJson = decoded['notes'];
  if (notesJson is! Map) {
    throw FormatException('Notes for board "$boardId" must be an object.');
  }

  final notes = <int, String>{};
  for (final entry in notesJson.entries) {
    final number = int.tryParse(entry.key.toString());
    if (number == null || entry.value is! String) {
      throw FormatException('Invalid pin note in notes data for "$boardId".');
    }
    notes[number] = entry.value as String;
  }
  return notes;
}

Future<Map<int, String>> loadBoardNotes(String boardId) async {
  final content = html.window.localStorage[_storageKey(boardId)];
  if (content == null) return {};
  return _decodeNotes(boardId, content);
}

Future<void> saveBoardNotes(String boardId, Map<int, String> notes) async {
  final key = _storageKey(boardId);
  if (notes.isEmpty) {
    html.window.localStorage.remove(key);
    return;
  }

  html.window.localStorage[key] = jsonEncode({
    'boardId': boardId,
    'notes': {
      for (final entry in notes.entries) '${entry.key}': entry.value,
    },
  });
}
