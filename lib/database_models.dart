// ================= FILE: database_models.dart =================
class EnterpriseDatabase {
  static String firebaseRestUrl = 'https://viziagmart-default-rtdb.firebaseio.com';

  // वर्तमान में लॉगिन वेंडर की जानकारी (डैशबोर्ड आइसोलेशन के लिए)
  static String? currentVendorId;
  static String? currentShopName;

  static Map<String, dynamic> activeShopProfile = {
    'shopName': '',
    'ownerName': '',
    'mobileNumber': '',
    'pin': '',
  };

  static List<Map<String, dynamic>> allOrders = [];
}
