import 'notes_store_stub.dart'
    if (dart.library.io) 'notes_store_io.dart'
    if (dart.library.html) 'notes_store_web.dart' as platform;

class NotesStore {
  Future<Map<int, String>> loadBoardNotes(String boardId) =>
      platform.loadBoardNotes(boardId);

  Future<void> saveBoardNotes(String boardId, Map<int, String> notes) =>
      platform.saveBoardNotes(boardId, notes);
}
