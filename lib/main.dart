import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShopState()..initializePreferences()),
        ChangeNotifierProvider(create: (_) => CartState()),
      ],
      child: const ViziagMartEnterpriseApp(),
    ),
  );
}

class ShopState extends ChangeNotifier {
  bool _shopOpen = true;
  bool get shopOpen => _shopOpen;

  Future<void> initializePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _shopOpen = prefs.getBool('shopOpen') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint("Pref read error: $e");
    }
  }

  void toggleShop(bool value) async {
    _shopOpen = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shopOpen', value);
      await FirebaseDatabase.instance.ref('shop_status').set({'isOpen': value});
    } catch (e) {
      debugPrint("Shop toggle error: $e");
    }
  }
}

class CartState extends ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> item) {
    try {
      _cartItems.add(item);
      notifyListeners();
    } catch (e) {
      debugPrint("Add to cart error: $e");
    }
  }

  void removeFromCart(int index) {
    try {
      if (index >= 0 && index < _cartItems.length) {
        _cartItems.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Remove from cart error: $e");
    }
  }

  void clearCart() {
    try {
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Clear cart error: $e");
    }
  }

  double get totalPrice {
    try {
      double total = 0.0;
      for (var item in _cartItems) {
        total += double.tryParse(item['price'].toString()) ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }
}

class ViziagMartEnterpriseApp extends StatelessWidget {
  const ViziagMartEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart Hyperlocal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 2,
          titleTextStyle: TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E293B),
          selectedItemColor: Color(0xFFF59E0B),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainNavigationHub(),
    );
  }
}

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MarketplaceTabScreen(),
    VendorDashboardTab(),
    RiderDeliveryTab(),
    CartCheckoutTab(),
    UserProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final shopState = Provider.of<ShopState>(context);
    final cartCount = Provider.of<CartState>(context).cartItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.store, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            const Text('VIZIAG MART (Tarun)'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: shopState.shopOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: shopState.shopOpen ? Colors.green : Colors.red),
              ),
              child: Text(
                shopState.shopOpen ? 'OPEN' : 'CLOSED',
                style: TextStyle(color: shopState.shopOpen ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Shop'),
          const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Vendor'),
          const BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Rider'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class MarketplaceTabScreen extends StatelessWidget {
  const MarketplaceTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopState = Provider.of<ShopState>(context);
    final cartState = Provider.of<CartState>(context);

    if (!shopState.shopOpen) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory, size: 70, color: Colors.redAccent),
            SizedBox(height: 12),
            Text('Shop is currently CLOSED!', style: TextStyle(fontSize: 20, color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('products').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(
            child: Text('No products listed yet. Add items from Vendor tab.', style: TextStyle(color: Colors.grey)),
          );
        }

        try {
          Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<String> keys = values.keys.cast<String>().toList();

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              String key = keys[index];
              var product = values[key];
              bool inStock = product['inStock'] ?? true;
              String imageUrl = product['image'] ?? '';

              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: imageUrl.isNotEmpty && !imageUrl.startsWith('/')
                      ? CachedNetworkImage(imageUrl: imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 50, color: Color(0xFFF59E0B)),
                  title: Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('₹${product['price']} | ${inStock ? "Available" : "Out of Stock"}',
                      style: TextStyle(color: inStock ? Colors.greenAccent : Colors.redAccent)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                    onPressed: !inStock
                        ? null
                        : () {
                            try {
                              cartState.addToCart({
                                'id': key,
                                'name': product['name'],
                                'price': product['price'],
                                'image': imageUrl,
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Added to Cart!'), duration: Duration(milliseconds: 600)),
                              );
                            } catch (e) {
                              debugPrint("Add button error: $e");
                            }
                          },
                    child: const Text('Add'),
                  ),
                ),
              );
            },
          );
        } catch (e) {
          return Center(child: Text('Data error: $e', style: const TextStyle(color: Colors.red)));
        }
      },
    );
  }
}

class VendorDashboardTab extends StatefulWidget {
  const VendorDashboardTab({super.key});

  @override
  State<VendorDashboardTab> createState() => _VendorDashboardTabState();
}

class _VendorDashboardTabState extends State<VendorDashboardTab> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  bool isLoading = false;

  void addProduct() async {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      String imgPath = pickedFile != null ? pickedFile.path : '';

      await FirebaseDatabase.instance.ref('products').push().set({
        'name': nameCtrl.text.trim(),
        'price': priceCtrl.text.trim(),
        'inStock': true,
        'image': imgPath,
      });
      nameCtrl.clear();
      priceCtrl.clear();
    } catch (e) {
      debugPrint("Add product error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(context) {
    final shopState = Provider.of<ShopState>(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Shop Online Status', style: TextStyle(fontWeight: FontWeight.bold)),
            value: shopState.shopOpen,
            onChanged: shopState.toggleShop,
            activeColor: const Color(0xFFF59E0B),
          ),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name (e.g. Apple)')),
          TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)')),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
            onPressed: isLoading ? null : addProduct,
            child: Text(isLoading ? 'Processing...' : 'Add Item with Image'),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('products').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('Inventory is empty. Add products above.', style: TextStyle(color: Colors.grey)));
                }
                try {
                  Map map = snapshot.data!.snapshot.value as Map;
                  List keys = map.keys.toList();

                  return ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      String k = keys[index];
                      var item = map[k];
                      bool inStock = item['inStock'] ?? true;

                      return Card(
                        color: const Color(0xFF1E293B),
                        child: ListTile(
                          title: Text(item['name'] ?? '', style: const TextStyle(color: Colors.white)),
                          subtitle: Text('₹${item['price']}', style: const TextStyle(color: Color(0xFFF59E0B))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: inStock,
                                activeColor: const Color(0xFFF59E0B),
                                onChanged: (val) {
                                  try {
                                    FirebaseDatabase.instance.ref('products/$k').update({'inStock': val});
                                  } catch (e) {
                                    debugPrint("Stock update error: $e");
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  try {
                                    FirebaseDatabase.instance.ref('products/$k').remove();
                                  } catch (e) {
                                    debugPrint("Delete error: $e");
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } catch (e) {
                  return Center(child: Text('Render error: $e', style: const TextStyle(color: Colors.red)));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RiderDeliveryTab extends StatelessWidget {
  const RiderDeliveryTab({super.key});

  @override
  Widget build(context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('orders').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No active delivery orders found.', style: TextStyle(color: Colors.grey)));
        }
        try {
          Map map = snapshot.data!.snapshot.value as Map;
          List keys = map.keys.toList();

          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              try {
                HapticFeedback.mediumImpact();
              } catch (_) {}
              
              String key = keys[index];
              var ord = map[key];

              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Order Total: ₹${ord['total']}', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${ord['status']}\nLocation: Faridabad Hub'),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone, color: Color(0xFFF59E0B)),
                    onPressed: () async {
                      try {
                        final Uri phoneUri = Uri.parse('tel:9971968060');
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        }
                      } catch (e) {
                        debugPrint("Phone launch error: $e");
                      }
                    },
                  ),
                ),
              );
            },
          );
        } catch (e) {
          return Center(child: Text('Order load error: $e', style: const TextStyle(color: Colors.red)));
        }
      },
    );
  }
}

class CartCheckoutTab extends StatelessWidget {
  const CartCheckoutTab({super.key});

  @override
  Widget build(context) {
    final cart = Provider.of<CartState>(context);

    if (cart.cartItems.isEmpty) {
      return const Center(child: Text('Your Cart is Empty.', style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cart.cartItems.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(cart.cartItems[i]['name'], style: const TextStyle(color: Colors.white)),
              subtitle: Text('₹${cart.cartItems[i]['price']}', style: const TextStyle(color: Colors.grey)),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => cart.removeFromCart(i),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
              onPressed: () async {
                try {
                  await FirebaseDatabase.instance.ref('orders').push().set({
                    'items': cart.cartItems,
                    'total': cart.totalPrice,
                    'status': 'Pending',
                  });
                  cart.clearCart();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Placed Successfully!')));
                  }
                } catch (e) {
                  debugPrint("Checkout error: $e");
                }
              },
              child: Text('Checkout Total ₹${cart.totalPrice} ➔', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

class UserProfileTab extends StatelessWidget {
  const UserProfileTab({super.key});

  @override
  Widget build(context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Center(child: CircleAvatar(radius: 40, backgroundColor: Color(0xFFF59E0B), child: Icon(Icons.person, size: 50, color: Colors.black))),
          SizedBox(height: 14),
          Center(child: Text('Tarun Kumar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
          Center(child: Text('Faridabad, India', style: TextStyle(color: Colors.grey))),
          Divider(height: 30),
          ListTile(
            leading: Icon(Icons.phone, color: Color(0xFFF59E0B)),
            title: Text('Contact Number', style: TextStyle(color: Colors.white)),
            subtitle: Text('9971968060', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
