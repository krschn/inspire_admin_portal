import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event.dart';

final selectedEventProvider =
    NotifierProvider<SelectedEventNotifier, Event?>(SelectedEventNotifier.new);

class SelectedEventNotifier extends Notifier<Event?> {
  @override
  Event? build() => null;

  void select(Event? event) {
    state = event;
  }
}
