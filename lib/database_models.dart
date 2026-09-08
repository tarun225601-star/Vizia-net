import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CakeDatabase {
  static String firebaseRestUrl = "https://viziagmart-default-rtdb.firebaseio.com/"; 

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

  // 🚀 1. लोकल मेमोरी में प्रोडक्ट्स सेव करने का फंक्शन (ताकि ऐप बंद होने पर भी डेटा उड़े नहीं)
  static Future<void> saveInventoryLocally() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = json.encode(productInventory);
    await prefs.setString('cached_product_inventory', encodedData);
  }

  // ⚡ 2. 0 सेकंड में लोकल मेमोरी से प्रोडक्ट्स लोड करने का फंक्शन
  static Future<List<Map<String, dynamic>>> loadInventoryLocally() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cached_product_inventory');
    
    if (cachedData != null && cachedData.isNotEmpty) {
      List<dynamic> decodedList = json.decode(cachedData);
      productInventory = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return productInventory;
  }
}
