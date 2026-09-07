// ================= FILE: database_models.dart =================
class EnterpriseDatabase {
  // Firebase REST URL - अपनी प्रोजेक्ट आईडी यहाँ सही रखें
  static const String firebaseRestUrl = "https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com";

  // वेंडर सेशन मैनेजमेंट (डेटा आइसोलेशन के लिए)
  static String? currentVendorId;
  static String? currentShopName;

  // ग्लोबल लिस्ट और डेटा स्ट्रक्चर्स जो आपके ऐप्स में उपयोग हो रहे हैं
  static List<Map<String, dynamic>> activeCart = [];
  static List<Map<String, dynamic>> orderLedger = [];
  static List<Map<String, dynamic>> globalInventory = [];

  // डिलीवरी एड्रेस संदर्भ
  static String currentDeliveryAddress = "";
}
