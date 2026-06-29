import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickedImageUpload {
  const PickedImageUpload({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';

  Map<String, dynamic> toJson() => {
        'name': name,
        'dataUrl': dataUrl,
      };
}

class ImageUploadField extends StatelessWidget {
  const ImageUploadField({
    super.key,
    required this.label,
    required this.image,
    required this.onChanged,
    this.helperText,
  });

  final String label;
  final PickedImageUpload? image;
  final ValueChanged<PickedImageUpload?> onChanged;
  final String? helperText;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    onChanged(PickedImageUpload(
      name: picked.name,
      mimeType: picked.mimeType ?? _mimeTypeForName(picked.name),
      bytes: bytes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                image!.bytes,
                height: 132,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: Text(image == null ? 'Choose image' : 'Change image'),
                ),
              ),
              if (image != null) ...[
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove image',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String _mimeTypeForName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
