import 'package:flutter/material.dart';

import '../../domain/entities/speaker.dart';

class SpeakersInputField extends StatefulWidget {
  final List<Speaker> initialSpeakers;
  final ValueChanged<List<Speaker>> onChanged;

  const SpeakersInputField({
    super.key,
    required this.initialSpeakers,
    required this.onChanged,
  });

  @override
  State<SpeakersInputField> createState() => _SpeakersInputFieldState();
}

class _SpeakersInputFieldState extends State<SpeakersInputField> {
  late List<_SpeakerEntry> _speakers;

  @override
  void initState() {
    super.initState();
    _speakers = widget.initialSpeakers
        .map((s) => _SpeakerEntry(
              nameController: TextEditingController(text: s.name),
              imageController: TextEditingController(text: s.image),
            ))
        .toList();

    if (_speakers.isEmpty) {
      _addSpeaker();
    }
  }

  @override
  void dispose() {
    for (final speaker in _speakers) {
      speaker.nameController.dispose();
      speaker.imageController.dispose();
    }
    super.dispose();
  }

  void _addSpeaker() {
    setState(() {
      _speakers.add(_SpeakerEntry(
        nameController: TextEditingController(),
        imageController: TextEditingController(),
      ));
    });
  }

  void _removeSpeaker(int index) {
    setState(() {
      _speakers[index].nameController.dispose();
      _speakers[index].imageController.dispose();
      _speakers.removeAt(index);
    });
    _notifyChange();
  }

  void _notifyChange() {
    final speakers = _speakers
        .where((s) => s.nameController.text.isNotEmpty)
        .map((s) => Speaker(
              name: s.nameController.text.trim(),
              image: s.imageController.text.trim(),
            ))
        .toList();
    widget.onChanged(speakers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Speakers',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton.icon(
              onPressed: _addSpeaker,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Speaker'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._speakers.asMap().entries.map((entry) {
          final index = entry.key;
          final speaker = entry.value;
          return _buildSpeakerRow(index, speaker);
        }),
      ],
    );
  }

  Widget _buildSpeakerRow(int index, _SpeakerEntry speaker) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: speaker.nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _notifyChange(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: speaker.imageController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _notifyChange(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _speakers.length > 1 ? () => _removeSpeaker(index) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: Theme.of(context).colorScheme.error,
            tooltip: 'Remove speaker',
          ),
        ],
      ),
    );
  }
}

class _SpeakerEntry {
  final TextEditingController nameController;
  final TextEditingController imageController;

  _SpeakerEntry({
    required this.nameController,
    required this.imageController,
  });
}
