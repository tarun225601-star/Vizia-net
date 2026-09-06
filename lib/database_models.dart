// ================= FILE 2 OF 10: database_models.dart =================

class EnterpriseDatabase {
  // Firebase Realtime Database REST API URL
  static String firebaseRestUrl = "https://viziagmart-default-rtdb.firebaseio.com/";

  // Default User / Customer Profile Info
  static String currentUserPhone = "9971968060";
  static String currentCustomerName = "Tarun Kumar";
  static String currentDeliveryAddress = "Sector 15A Faridabad";

  // Default Shop Profile Configuration
  static Map<String, dynamic> activeShopProfile = {
    'shopId': 'shop_viziag_01',
    'shopName': 'Tarun Fruit & Vegetable Shop',
    'ownerName': 'Tarun Kumar',
    'ownerPhone': '9971968060',
    'ownerPhotoPath': '',
    'bannerPhotoPath': '',
    'shopPhotoPath': '',
    'phone': '9971968060',
    'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
    'bio': 'ताज़ा फल, सब्जियां और ऑर्गेनिक उत्पाद सीधे मंडी से।',
    'isOpen': true,
  };

  // Central Lists for Products, Cart Items, and Orders
  static List<Map<String, dynamic>> globalInventory = [];
  static List<Map<String, dynamic>> activeCart = [];
  static List<Map<String, dynamic>> orderLedger = [];
}
