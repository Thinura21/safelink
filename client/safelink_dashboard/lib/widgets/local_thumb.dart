import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LocalThumb extends StatelessWidget {
  final XFile x;
  final VoidCallback onRemove;
  const LocalThumb({super.key, required this.x, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (kIsWeb) {
      img = FutureBuilder<Uint8List>(
        future: x.readAsBytes(),
        builder: (_, s) {
          if (!s.hasData) {
            return const SizedBox(width: 120, height: 90, child: ColoredBox(color: Colors.black12));
          }
          return Image.memory(s.data!, width: 120, height: 90, fit: BoxFit.cover);
        },
      );
    } else {
      img = Image.file(File(x.path), width: 120, height: 90, fit: BoxFit.cover);
    }
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: img),
        Positioned(
          right: 4,
          top: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
