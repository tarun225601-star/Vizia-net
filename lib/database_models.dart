import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CakeDatabase {
  static String firebaseRestUrl = "https://viziagmart-default-rtdb.firebaseio.com"; 

  static String currentUserPhone = "9971968060";
  static String currentCustomerName = "Tarun Kumar";
  static String currentDeliveryAddress = "Sector 15A Faridabad";

  static Map<String, dynamic> bakeryShop = {
    'shopId': 'shop_cake_01',
    'shopName': 'Tarun Fruit & Vegetable Shop',
    'ownerName': 'Tarun Kumar',
    'ownerPhone': '9971968060',
    'ownerPhotoPath': '', 
    'bannerPhotoPath': '',
    'shopPhotoPath': '',
    'phone': '9971968060',
    'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
    'bio': 'ताज़ा फल, सब्जियां और उत्पाद उपलब्ध।',
    'isOpen': true,
  };

  static List<Map<String, dynamic>> productInventory = [];
  static List<Map<String, dynamic>> cartItems = [];
  
  // 🟢 यह लोकल ऑर्डर्स की लिस्ट है जो हमेशा परमानेंट सेव रहेगी
  static List<Map<String, dynamic>> localOrdersCache = [];

  // ==========================================
  // 1. परमानेंट लोकल मेमोरी सेविंग (एक बार आ गया तो हमेशा के लिए सेव)
  // ==========================================
  static Future<void> saveOrdersLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String encodedData = json.encode(localOrdersCache);
      await prefs.setString('permanent_orders_cache', encodedData);
    } catch (e) {
      debugPrint("Error saving orders locally: $e");
    }
  }

  // ==========================================
  // 2. ऐप खुलते ही 0 सेकंड में पुराना सेव्ड डेटा लोड करना
  // ==========================================
  static Future<void> loadOrdersLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString('permanent_orders_cache');
      
      if (cachedData != null && cachedData.isNotEmpty) {
        List<dynamic> decodedList = json.decode(cachedData);
        localOrdersCache = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint("Error loading orders locally: $e");
    }
  }

  // ==========================================
  // 3. स्मार्ट फेच: सिर्फ और सिर्फ बिल्कुल नया 1 ऑर्डर लाना (डेटा की बचत)
  // ==========================================
  static Future<Map<String, dynamic>?> fetchSingleLatestOrderOnly() async {
    try {
      // Firebase REST API पर limitToLast=1 लगाकर सिर्फ सबसे आखिरी/नया रिकॉर्ड मांग रहे हैं
      final response = await http.get(
        Uri.parse('$firebaseRestUrl/customer_orders.json?orderBy="\$key"&limitToLast=1'),
      );

      if (response.statusCode == 200 && response.body != 'null' && response.body.isNotEmpty) {
        Map<String, dynamic> data = json.decode(response.body);
        
        // चूँकि डेटा एक मैप के रूप में मिलता है, उसका की और वैल्यू निकालें
        String? latestKey;
        Map<String, dynamic>? latestValue;
        
        data.forEach((key, value) {
          latestKey = key;
          latestValue = Map<String, dynamic>.from(value);
        });

        if (latestKey != null && latestValue != null) {
          latestValue['orderId'] = latestKey;

          // चेक करें कि क्या यह ऑर्डर पहले से हमारी लोकल मेमोरी में है या नहीं
          bool alreadyExists = localOrdersCache.any((ord) => ord['orderId'] == latestKey);

          if (!alreadyExists) {
            // अगर नया ऑर्डर है, तो उसे लिस्ट में सबसे ऊपर जोड़ें
            localOrdersCache.insert(0, latestValue);
            // तुरंत परमानेंट लोकल मेमोरी में सेव कर दें ताकि डिलीट न हो
            await saveOrdersLocally();
            return latestValue; // नया ऑर्डर रिटर्न कर देगा ताकि स्क्रीन पर घंटी बज सके
          }
        }
      }
    } catch (e) {
      debugPrint("Smart fetch single order error: $e");
    }
    return null; // कोई नया ऑर्डर नहीं है तो कुछ नहीं करेगा (नेट बचेगा)
  }
}
