import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/track.dart';

class TrackFormDialog extends StatefulWidget {
  final Track? track;
  final Future<bool> Function(Track) onSubmit;

  const TrackFormDialog({super.key, this.track, required this.onSubmit});

  @override
  State<TrackFormDialog> createState() => _TrackFormDialogState();
}

class _TrackFormDialogState extends State<TrackFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _trackNumberController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _colorController;

  bool _isSubmitting = false;
  Color? _previewColor;

  bool get _isEditing => widget.track != null;

  static const _defaultColor = '#2E6CA4';

  @override
  void initState() {
    super.initState();
    final track = widget.track;

    _trackNumberController = TextEditingController(
      text: track?.trackNumber.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: track?.trackDescription ?? '',
    );
    _colorController = TextEditingController(
      text: track?.trackColor ?? _defaultColor,
    );

    _updateColorPreview(_colorController.text);
    _colorController.addListener(() {
      _updateColorPreview(_colorController.text);
    });
  }

  @override
  void dispose() {
    _trackNumberController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _updateColorPreview(String colorText) {
    final color = _parseColor(colorText);
    if (color != _previewColor) {
      setState(() {
        _previewColor = color;
      });
    }
  }

  Color? _parseColor(String hexColor) {
    if (!_isValidHexColor(hexColor)) return null;
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return null;
    }
  }

  bool _isValidHexColor(String color) {
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditing ? 'Edit Track' : 'Create Track',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _trackNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Track Number *',
                            hintText: 'e.g., 1, 2, 3',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Track number is required';
                            }
                            final number = int.tryParse(value.trim());
                            if (number == null || number <= 0) {
                              return 'Enter a valid positive number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            hintText: 'e.g., Data & Analytics',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _colorController,
                                decoration: const InputDecoration(
                                  labelText: 'Color *',
                                  hintText: '#2E6CA4',
                                  border: OutlineInputBorder(),
                                  helperText: 'Hex format: #RRGGBB',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Color is required';
                                  }
                                  if (!_isValidHexColor(value.trim())) {
                                    return 'Invalid format (use #RRGGBB)';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _previewColor ?? Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                  width: 1,
                                ),
                              ),
                              child: _previewColor == null
                                  ? Icon(
                                      Icons.color_lens,
                                      color: Colors.grey.shade600,
                                    )
                                  : null,
                            ),
                          ],
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final track = Track(
      id: widget.track?.id,
      trackNumber: int.parse(_trackNumberController.text.trim()),
      trackDescription: _descriptionController.text.trim(),
      trackColor: _colorController.text.trim(),
    );

    final success = await widget.onSubmit(track);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.of(context).pop();
      }
    }
  }
}
