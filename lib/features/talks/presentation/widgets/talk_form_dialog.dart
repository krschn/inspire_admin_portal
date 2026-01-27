import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/speaker.dart';
import '../../domain/entities/talk.dart';
import 'speakers_input_field.dart';

class TalkFormDialog extends StatefulWidget {
  final Talk? talk;
  final Future<bool> Function(Talk) onSubmit;

  const TalkFormDialog({
    super.key,
    this.talk,
    required this.onSubmit,
  });

  @override
  State<TalkFormDialog> createState() => _TalkFormDialogState();
}

class _TalkFormDialogState extends State<TalkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _liveLinkController;
  late final TextEditingController _durationController;
  late final TextEditingController _trackController;
  late final TextEditingController _venueController;

  late DateTime _selectedDate;
  late List<Speaker> _speakers;
  bool _isSubmitting = false;

  bool get _isEditing => widget.talk != null;

  @override
  void initState() {
    super.initState();
    final talk = widget.talk;

    _titleController = TextEditingController(text: talk?.title ?? '');
    _descriptionController =
        TextEditingController(text: talk?.description ?? '');
    _liveLinkController = TextEditingController(text: talk?.liveLink ?? '');
    _durationController = TextEditingController(text: talk?.duration ?? '');
    _trackController = TextEditingController(text: talk?.track ?? '');
    _venueController = TextEditingController(text: talk?.venue ?? '');

    _selectedDate = talk?.date ?? DateTime.now();
    _speakers = talk?.speakers ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _liveLinkController.dispose();
    _durationController.dispose();
    _trackController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final talk = Talk(
      id: widget.talk?.id,
      date: _selectedDate,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      speakers: _speakers,
      liveLink: _liveLinkController.text.trim(),
      duration: _durationController.text.trim(),
      track: _trackController.text.trim(),
      venue: _venueController.text.trim(),
    );

    final success = await widget.onSubmit(talk);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditing ? 'Edit Talk' : 'Create Talk',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(dateFormat.format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _durationController,
                                decoration: const InputDecoration(
                                  labelText: 'Duration',
                                  hintText: 'e.g., 40 min',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _trackController,
                                decoration: const InputDecoration(
                                  labelText: 'Track',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _venueController,
                          decoration: const InputDecoration(
                            labelText: 'Venue',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _liveLinkController,
                          decoration: const InputDecoration(
                            labelText: 'Live Link',
                            hintText: 'https://',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 24),
                        SpeakersInputField(
                          initialSpeakers: _speakers,
                          onChanged: (speakers) {
                            _speakers = speakers;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? 'Update' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
