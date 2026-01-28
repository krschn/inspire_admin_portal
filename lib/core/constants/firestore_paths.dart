class FirestorePaths {
  static const String events = 'events';

  static String talk(String eventId, String talkId) =>
      'events/$eventId/talks/$talkId';

  static String talks(String eventId) => 'events/$eventId/talks';

  static String track(String eventId, String trackId) =>
      'events/$eventId/tracks/$trackId';

  static String tracks(String eventId) => 'events/$eventId/tracks';
}
