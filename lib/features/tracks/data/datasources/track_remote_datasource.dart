import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/track_model.dart';

abstract class TrackRemoteDataSource {
  Future<TrackModel> createTrack(String eventId, TrackModel track);
  Future<void> deleteTrack(String eventId, String trackId);
  Future<TrackModel?> findTrackByNumber(String eventId, int trackNumber);
  Future<List<TrackModel>> getTracks(String eventId);
  Future<TrackModel> updateTrack(String eventId, TrackModel track);
}

class TrackRemoteDataSourceImpl implements TrackRemoteDataSource {
  final FirebaseFirestore firestore;

  TrackRemoteDataSourceImpl(this.firestore);

  @override
  Future<TrackModel> createTrack(String eventId, TrackModel track) async {
    try {
      // Generate Firestore auto-ID for uniqueness suffix
      final autoId = firestore
          .collection(FirestorePaths.tracks(eventId))
          .doc()
          .id;

      // Create custom ID: track_{trackNumber}_{autoId}
      final customId = 'track_${track.trackNumber}_$autoId';

      // Use .set() instead of .add() to use our custom ID
      final docRef = firestore
          .collection(FirestorePaths.tracks(eventId))
          .doc(customId);
      await docRef.set(track.toFirestore());

      final doc = await docRef.get();
      return TrackModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to create track');
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<void> deleteTrack(String eventId, String trackId) async {
    try {
      await firestore
          .collection(FirestorePaths.tracks(eventId))
          .doc(trackId)
          .delete();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to delete track');
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<TrackModel?> findTrackByNumber(
    String eventId,
    int trackNumber,
  ) async {
    try {
      final snapshot = await firestore
          .collection(FirestorePaths.tracks(eventId))
          .where('track_number', isEqualTo: trackNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return TrackModel.fromFirestore(snapshot.docs.first);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to find track');
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<List<TrackModel>> getTracks(String eventId) async {
    try {
      final snapshot = await firestore
          .collection(FirestorePaths.tracks(eventId))
          .orderBy('track_number', descending: false)
          .get();
      return snapshot.docs.map((doc) => TrackModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch tracks');
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  Future<TrackModel> updateTrack(String eventId, TrackModel track) async {
    try {
      if (track.id == null) {
        throw const ServerException('Track ID is required for update');
      }

      await firestore
          .collection(FirestorePaths.tracks(eventId))
          .doc(track.id)
          .update(track.toFirestore());

      final doc = await firestore
          .collection(FirestorePaths.tracks(eventId))
          .doc(track.id)
          .get();

      return TrackModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to update track');
    } on SocketException {
      throw const NetworkException();
    }
  }
}
