import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  List<Object?> get props => [uid, email, displayName];
}
