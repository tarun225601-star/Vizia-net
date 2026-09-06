// ================= FILE 2 OF 10: database_models.dart =================
class EnterpriseDatabase {
  static String firebaseRestUrl = 'https://viziagmart-default-rtdb.firebaseio.com';
  
  static Map<String, dynamic> activeShopProfile = {
    'shopName': 'Tarun Fruit & Vegetable Shop',
    'phone': '9971000000',
    'address': 'Sector 15A Ajronda Sabji Mandi, Faridabad',
  };

  static String currentCustomerName = 'Tarun Kumar';
  static String currentUserPhone = '9971000000';
  static String currentDeliveryAddress = 'Sector 15A, Faridabad';

  static List<Map<String, dynamic>> globalInventory = [];
  static List<Map<String, dynamic>> activeCart = [];
  static List<Map<String, dynamic>> orderLedger = [];
}
