import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String? name;

  const Event({
    required this.id,
    this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
