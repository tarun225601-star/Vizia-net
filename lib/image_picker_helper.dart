// ================= FILE 12: image_picker_helper.dart =================
import 'package:flutter/material.dart';

class ImagePickerHelper {
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
                // यहाँ कैमरा पैकेज का कोड इंटीग्रेट किया जा सकता है
                onImageSelected('assets/camera_placeholder.png');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFF59E0B)),
              title: const Text('गैलरी (Gallery)', style: TextStyle(color: Colors.white, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                // यहाँ इमेज पिकर पैकेज का कोड इंटीग्रेट किया जा सकता है
                onImageSelected('assets/gallery_placeholder.png');
              },
            ),
          ],
        ),
      ),
    );
  }
}
