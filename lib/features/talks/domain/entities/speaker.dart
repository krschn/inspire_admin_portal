import 'package:equatable/equatable.dart';

class Speaker extends Equatable {
  final String name;
  final String image;

  const Speaker({
    required this.name,
    required this.image,
  });

  Speaker copyWith({
    String? name,
    String? image,
  }) {
    return Speaker(
      name: name ?? this.name,
      image: image ?? this.image,
    );
  }

  @override
  List<Object?> get props => [name, image];
}
