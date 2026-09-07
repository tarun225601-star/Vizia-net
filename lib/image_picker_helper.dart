import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> pickAndConvertToBase64() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
  if (pickedFile != null) {
    final bytes = await File(pickedFile.path).readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
  return null;
}

Widget buildShopOrProdImage(String? path, double height, double width, IconData fallbackIcon) {
  if (path != null && path.isNotEmpty) {
    if (path.startsWith('http')) {
      return Image.network(path, height: height, width: width, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: const Color(0xFF334155), child: Icon(fallbackIcon, size: height * 0.4, color: const Color(0xFFF59E0B))));
    } else if (path.startsWith('data:image')) {
      try {
        final base64String = path.contains(',') ? path.split(',').last : path;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, height: height, width: width, fit: BoxFit.cover);
      } catch (_) {}
    } else if (File(path).existsSync()) {
      return Image.file(File(path), height: height, width: width, fit: BoxFit.cover);
    }
  }
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)]),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(fallbackIcon, size: height * 0.4, color: const Color(0xFFF59E0B)),
  );
}
