// ================= FILE: database_models.dart =================
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class EnterpriseDatabase {
  // Firebase REST URL 
  static String firebaseRestUrl = "https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com";

  // वेंडर सेशन मैनेजमेंट
  static String? currentVendorId = "9999999999";
  static String? currentShopName = "मेरी दुकान";

  // एडमिन और मास्टर डैशबोर्ड के लिए एक्टिव शॉप प्रोफाइल
  static Map<String, dynamic> activeShopProfile = {
    'shopName': 'मेरी दुकान',
    'phone': '9999999999',
    'address': 'Faridabad, Haryana',
    'shopImage': '',
    'ownerImage': '',
  };

  // ग्राहक और आर्डर से जुड़े वेरिएबल्स
  static String currentCustomerName = "ग्राहक";
  static String currentUserPhone = "9999999999";
  static String currentDeliveryAddress = "Faridabad";

  // ग्लोबल लिस्ट और डेटा स्ट्रक्चर्स
  static List<Map<String, dynamic>> activeCart = [];
  
  static List<Map<String, dynamic>> orderLedger = [
    {
      'orderId': 'ORD-1001',
      'customerName': 'राहुल कुमार',
      'phone': '9876543210',
      'items': 'डैशबोर्ड पॉलिश (1)',
      'totalAmount': '350',
      'status': 'Processing',
      'date': '2026-06-07'
    }
  ];

  static List<Map<String, dynamic>> globalInventory = [
    {
      'id': 'p1',
      'name': 'जेट ब्लैक टायर पॉलिश (Jet Black)',
      'price': 250,
      'stock': 50,
      'category': 'Automotive Care',
      'image': '',
      'isInStock': true,
    },
    {
      'id': 'p2',
      'name': 'डैशबोर्ड क्लीनर एंड शाइन',
      'price': 350,
      'stock': 30,
      'category': 'Automotive Care',
      'image': '',
      'isInStock': true,
    },
    {
      'id': 'p3',
      'name': 'लिक्विड वैक्स कार शैम्पू',
      'price': 400,
      'stock': 25,
      'category': 'Cleaning',
      'image': '',
      'isInStock': true,
    }
  ];

  // =========================================================================
  // यूनिवर्सल इमेज रेंडरर (Universal Image Helper Widget)
  // इसे आप अपनी किसी भी फाइल (वेंडर या शॉप व्यू) में इस्तेमाल कर सकते हैं।
  // =========================================================================
  static Widget buildUniversalImage(String? imageSource, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (imageSource == null || imageSource.trim().isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.image, color: Colors.amber, size: 30),
      );
    }

    try {
      // 1. अगर यह लोकल फाइल पाथ है (जैसे /data/user/0/...)
      if (imageSource.startsWith('/')) {
        final file = File(imageSource);
        if (file.existsSync()) {
          return Image.file(file, fit: fit, width: width, height: height);
        }
      } 
      // 2. अगर यह Base64 स्ट्रिंग है
      else {
        // कभी-कभी बेस64 के आगे डेटा हेडर होता है, उसे साफ़ करने के लिए
        String cleanBase64 = imageSource;
        if (imageSource.contains(',')) {
          cleanBase64 = imageSource.split(',').last;
        }
        
        final decodedBytes = base64Decode(cleanBase64);
        return Image.memory(decodedBytes, fit: fit, width: width, height: height);
      }
    } catch (e) {
      debugPrint('Image Rendering Error: $e');
    }

    // अगर ऊपर का दोनों फेल हो जाए तो फॉलबैक आइकॉन दिखाएं
    return SizedBox(
      width: width,
      height: height,
      child: const Icon(Icons.broken_image, color: Colors.redAccent, size: 30),
    );
  }
}
