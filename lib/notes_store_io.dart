import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> _notesFile(String boardId) async {
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(boardId)) {
    throw ArgumentError.value(boardId, 'boardId', 'Invalid board ID');
  }

  final supportDirectory = await getApplicationSupportDirectory();
  final notesDirectory = Directory(
    '${supportDirectory.path}${Platform.pathSeparator}pinout_notes',
  );
  return File(
    '${notesDirectory.path}${Platform.pathSeparator}$boardId.json',
  );
}

Future<Map<int, String>> loadBoardNotes(String boardId) async {
  final file = await _notesFile(boardId);
  if (!await file.exists()) return {};

  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map || decoded['boardId'] != boardId) {
    throw FormatException('Invalid notes file for board "$boardId".');
  }

  final notesJson = decoded['notes'];
  if (notesJson is! Map) {
    throw FormatException('Notes for board "$boardId" must be an object.');
  }

  final notes = <int, String>{};
  for (final entry in notesJson.entries) {
    final number = int.tryParse(entry.key.toString());
    if (number == null || entry.value is! String) {
      throw FormatException('Invalid pin note in notes file for "$boardId".');
    }
    notes[number] = entry.value as String;
  }
  return notes;
}

Future<void> saveBoardNotes(String boardId, Map<int, String> notes) async {
  final file = await _notesFile(boardId);
  if (notes.isEmpty) {
    if (await file.exists()) await file.delete();
    return;
  }

  await file.parent.create(recursive: true);
  final json = jsonEncode({
    'boardId': boardId,
    'notes': {
      for (final entry in notes.entries) '${entry.key}': entry.value,
    },
  });
  final temporaryFile = File('${file.path}.tmp');
  await temporaryFile.writeAsString(json, flush: true);
  await temporaryFile.rename(file.path);
}
