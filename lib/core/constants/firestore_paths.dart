class FirestorePaths {
  static const String events = 'events';

  static String talks(String eventId) => 'events/$eventId/talk';

  static String talk(String eventId, String talkId) =>
      'events/$eventId/talk/$talkId';
}
