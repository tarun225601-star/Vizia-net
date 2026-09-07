// ================= FILE: database_models.dart =================
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
  };

  // ग्राहक और आर्डर से जुड़े वेरिएबल्स
  static String currentCustomerName = "ग्राहक";
  static String currentUserPhone = "9999999999";
  static String currentDeliveryAddress = "Faridabad";

  // ग्लोबल लिस्ट और डेटा स्ट्रक्चर्स (डिफ़ॉल्ट आइटम्स के साथ ताकि स्क्रीन खाली न रहे)
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
      'image': ''
    },
    {
      'id': 'p2',
      'name': 'डैशबोर्ड क्लीनर एंड शाइन',
      'price': 350,
      'stock': 30,
      'category': 'Automotive Care',
      'image': ''
    },
    {
      'id': 'p3',
      'name': 'लिक्विड वैक्स कार शैम्पू',
      'price': 400,
      'stock': 25,
      'category': 'Cleaning',
      'image': ''
    }
  ];
}
