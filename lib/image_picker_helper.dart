import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  // 🚀 गैलरी से इमेज पिक करके Base64 में बदलने का मेन फंक्शन
  static Future<String?> pickImageAsBase64() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // क्वालिटी थोड़ी ऑप्टिमाइज़ की है ताकि ऐप भारी न हो
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) {
        debugPrint('⚠️ उपयोगकर्ता ने इमेज चयन रद्द कर दिया है।');
        return null;
      }

      // वेब और मोबाइल दोनों के लिए सुरक्षित बाइट्स रीडिंग
      final Uint8List bytes = await pickedFile.readAsBytes();
      
      if (bytes.isEmpty) {
        debugPrint('⚠️ चुनी गई इमेज खाली है।');
        return null;
      }

      String base64String = base64Encode(bytes);
      String finalImageFormat = 'data:image/jpeg;base64,$base64String';
      
      debugPrint('✅ इमेज सफलतापूर्वक Base64 में बदल दी गई है!');
      return finalImageFormat;
      
    } catch (e) {
      debugPrint('❌ इमेज पिक करने या कन्वर्ट करने में एरर आया: $e');
      return null;
    }
  }

  // 📸 कैमरे से फोटो खींचकर Base64 में बदलने के लिए एडवांस फंक्शन
  static Future<String?> captureImageAsBase64() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? capturedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (capturedFile == null) {
        debugPrint('⚠️ कैमरे से फोटो खींचना रद्द कर दिया गया।');
        return null;
      }

      final Uint8List bytes = await capturedFile.readAsBytes();
      if (bytes.isEmpty) return null;

      String base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
      
    } catch (e) {
      debugPrint('❌ कैमरा एरर: $e');
      return null;
    }
  }

  // 🖼️ UI पर इमेज दिखाने के लिए सेफ विजेट हेल्पर
  static Widget buildCachedOrMemoryImage(String? path, double height, double width, IconData fallbackIcon) {
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) {
        return Image.network(
          path,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height,
            width: width,
            color: const Color(0xFF334155),
            child: Icon(fallbackIcon, size: height * 0.4, color: const Color(0xFFF59E0B)),
          ),
        );
      } else if (path.startsWith('data:image')) {
        try {
          final base64String = path.contains(',') ? path.split(',').last : path;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            height: height,
            width: width,
            fit: BoxFit.cover,
          );
        } catch (e) {
          debugPrint('Base64 Decoding Error in Widget: $e');
        }
      } else if (!kIsWeb && File(path).existsSync()) {
        return Image.file(
          File(path),
          height: height,
          width: width,
          fit: BoxFit.cover,
        );
      }
    }
    
    // फॉलबैक कंटेनर अगर इमेज न मिले
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
}
