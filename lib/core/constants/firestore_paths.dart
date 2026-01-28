class FirestorePaths {
  static const String events = 'events';

  static String talk(String eventId, String talkId) =>
      'events/$eventId/talks/$talkId';

  static String talks(String eventId) => 'events/$eventId/talks';
}
