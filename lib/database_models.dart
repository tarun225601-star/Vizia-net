// ================= FILE: database_models.dart =================
import 'dart:convert';

class EnterpriseDatabase {
  // Firebase REST API URL
  static String firebaseRestUrl = 'https://viziagmart-default-rtdb.firebaseio.com';

  // एक्टिव वेंडर / शॉप प्रोफाइल (बेस64 इमेज और फुल एड्रेस के साथ)
  static Map<String, dynamic> activeShopProfile = {
    'shopName': 'Viziag Fresh Mart',
    'ownerName': 'Tarun Kumar',
    'ownerPhoto': '', // Base64 String
    'shopPhoto': '',  // Base64 String
    'address': 'Main Market, Faridabad, Haryana',
    'phone': '9876543210',
  };

  // ग्लोबल इन्वेंट्री (उत्पाद सूची)
  static List<Map<String, dynamic>> globalInventory = [];

  // एक्टिव कार्ट (ग्राहकों का सामान)
  static List<Map<String, dynamic>> activeCart = [];

  // सभी ऑर्डर्स की सूची (वेंडर डैशबोर्ड के लिए)
  static List<Map<String, dynamic>> allOrders = [];

  // कार्ट और ऑर्डर व्यू के लिए जरूरी कस्टमर डेटा वेरिएबल्स
  static String currentCustomerName = 'Tarun Kumar';
  static String currentUserPhone = '9876543210';
  static String currentDeliveryAddress = 'Main Market, Faridabad, Haryana';

  // लोकल ऑर्डर लेजर (Order History)
  static List<Map<String, dynamic>> orderLedger = [];
}
