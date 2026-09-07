// ============================================================================
// FILE: image_picker_helper.dart
// ============================================================================

import 'package:flutter/material.dart';

class ImagePickerHelper {
  
  // डैशबोर्ड व्यू की मांग के अनुसार pickImageFromGallery फंक्शन
  static Future<String?> pickImageFromGallery() async {
    // चूंकि अभी प्रोजेक्ट में इमेज पिकर पैकेज या पाथ लॉजिक यहाँ सेट है,
    // यह डायरेक्ट गैलरी पाथ या डिफ़ॉल्ट एसेट/सैंपल पाथ रिटर्न करेगा।
    // जरूरत पड़ने पर यहाँ file_picker या image_picker पैकेज जोड़ा जा सकता है।
    return 'assets/sample_product.png'; 
  }

  // वैकल्पिक नाम ताकि कहीं भी एरर न आए
  static Future<String?> pickImage() async {
    return await pickImageFromGallery();
  }

  // भविष्य में गैलरी या कैमरे से इमेज पिक करने के लिए बेस लॉजिक / डायलॉग
  static Future<void> showImageSourceDialog(
    BuildContext context, {
    required Function(String selectedPath) onImageSelected,
  }) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'इमेज चुनें (Select Image Source)',
          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFF59E0B)),
              title: const Text('कैमरा (Camera)', style: TextStyle(color: Colors.white, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                onImageSelected('assets/camera_placeholder.png');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFF59E0B)),
              title: const Text('गैलरी (Gallery)', style: TextStyle(color: Colors.white, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                onImageSelected('assets/gallery_placeholder.png');
              },
            ),
          ],
        ),
      ),
    );
  }
}
