import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    super.name,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return EventModel(
      id: doc.id,
      name: data?['name'] as String?,
    );
  }

  Event toEntity() {
    return Event(
      id: id,
      name: name,
    );
  }
}
