import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/event_model.dart';
import '../models/talk_model.dart';

abstract class TalkRemoteDataSource {
  Future<List<EventModel>> getEvents();
  Future<List<TalkModel>> getTalks(String eventId);
  Future<TalkModel> createTalk(String eventId, TalkModel talk);
  Future<TalkModel> updateTalk(String eventId, TalkModel talk);
  Future<void> deleteTalk(String eventId, String talkId);
  Future<TalkModel?> findTalkByTitleAndDate(
    String eventId,
    String title,
    DateTime date,
  );
}

class TalkRemoteDataSourceImpl implements TalkRemoteDataSource {
  final FirebaseFirestore firestore;

  TalkRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<EventModel>> getEvents() async {
    try {
      final snapshot =
          await firestore.collection(FirestorePaths.events).get();
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch events');
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<List<TalkModel>> getTalks(String eventId) async {
    try {
      final snapshot = await firestore
          .collection(FirestorePaths.talks(eventId))
          .orderBy('date', descending: false)
          .get();
      return snapshot.docs.map((doc) => TalkModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch talks');
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<TalkModel> createTalk(String eventId, TalkModel talk) async {
    try {
      // Generate Firestore auto-ID for uniqueness suffix
      final autoId =
          firestore.collection(FirestorePaths.talks(eventId)).doc().id;

      // Create custom ID: YYYYMMDD_HHMM_track_autoId
      final dateStr = DateFormat('yyyyMMdd').format(talk.date);
      final timeStr = DateFormat('HHmm').format(talk.date);
      final customId = '${dateStr}_${timeStr}_${talk.track}_$autoId';

      // Use .set() instead of .add() to use our custom ID
      final docRef =
          firestore.collection(FirestorePaths.talks(eventId)).doc(customId);
      await docRef.set(talk.toFirestore());

      final doc = await docRef.get();
      return TalkModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to create talk');
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<TalkModel> updateTalk(String eventId, TalkModel talk) async {
    try {
      if (talk.id == null) {
        throw const ServerException('Talk ID is required for update');
      }

      await firestore
          .collection(FirestorePaths.talks(eventId))
          .doc(talk.id)
          .update(talk.toFirestore());

      final doc = await firestore
          .collection(FirestorePaths.talks(eventId))
          .doc(talk.id)
          .get();

      return TalkModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to update talk');
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<void> deleteTalk(String eventId, String talkId) async {
    try {
      await firestore
          .collection(FirestorePaths.talks(eventId))
          .doc(talkId)
          .delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to delete talk');
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<TalkModel?> findTalkByTitleAndDate(
    String eventId,
    String title,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await firestore
          .collection(FirestorePaths.talks(eventId))
          .where('title', isEqualTo: title)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return TalkModel.fromFirestore(snapshot.docs.first);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to find talk');
    } on SocketException {
      throw const NetworkException();
    }
  }
}
