// ================= FILE: database_models.dart =================
class EnterpriseDatabase {
  // Firebase REST URL (इसे नॉन-कॉन्स्टेंट बनाया गया है ताकि एडमिन डैशबोर्ड से मॉडिफाई हो सके)
  static String firebaseRestUrl = "https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com";

  // वेंडर सेशन मैनेजमेंट (डेटा आइसोलेशन के लिए)
  static String? currentVendorId;
  static String? currentShopName;

  // एडमिन और मास्टर डैशबोर्ड के लिए एक्टिव शॉप प्रोफाइल
  static Map<String, dynamic> activeShopProfile = {
    'shopName': 'मेरी दुकान',
    'phone': '',
    'address': '',
  };

  // ग्राहक और आर्डर से जुड़े वेरिएबल्स
  static String currentCustomerName = "";
  static String currentUserPhone = "";
  static String currentDeliveryAddress = "";

  // ग्लोबल लिस्ट और डेटा स्ट्रक्चर्स
  static List<Map<String, dynamic>> activeCart = [];
  static List<Map<String, dynamic>> orderLedger = [];
  static List<Map<String, dynamic>> globalInventory = [];
}
