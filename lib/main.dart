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
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ShopState(),
      child: const MaterialApp(home: ViziagApp(), debugShowCheckedModeBanner: false),
    ),
  );
}

class ShopState extends ChangeNotifier {
  bool shopOpen = true;
  List cart = [];

  void toggleShop(bool val) async {
    shopOpen = val;
    notifyListeners();
    var p = await SharedPreferences.getInstance();
    p.setBool('shopOpen', val);
    FirebaseDatabase.instance.ref('shop_status').set({'isOpen': val});
  }

  void addToCart(Map item) {
    cart.add(item);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }
}

class ViziagApp extends StatefulWidget {
  const ViziagApp({super.key});
  @override
  State<ViziagApp> createState() => _ViziagAppState();
}

class _ViziagAppState extends State<ViziagApp> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      bool savedStatus = p.getBool('shopOpen') ?? true;
      Provider.of<ShopState>(context, listen: false).shopOpen = savedStatus;
    });
  }

  @override
  Widget build(context) {
    final state = Provider.of<ShopState>(context);
    List screens = [
      const _ShopTab(),
      const _VendorTab(),
      const _RiderTab(),
      const _CartTab(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Viziag Mart', style: TextStyle(color: Colors.amber)), backgroundColor: Colors.black87),
      body: screens[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black87,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
          const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Vendor'),
          const BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Rider'),
          BottomNavigationBarItem(
            icon: Badge(label: Text('${state.cart.length}'), child: const Icon(Icons.shopping_cart)),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}

class _ShopTab extends StatelessWidget {
  const _ShopTab();
  @override
  Widget build(context) {
    final state = Provider.of<ShopState>(context);
    if (!state.shopOpen) return const Center(child: Text('Shop is CLOSED!', style: TextStyle(color: Colors.red, fontSize: 18)));
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('products').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
        if (!snap.hasData || snap.data!.snapshot.value == null) return const Center(child: CircularProgressIndicator());
        Map map = snap.data!.snapshot.value as Map;
        var keys = map.keys.toList();
        return ListView.builder(
          itemCount: keys.length,
          itemBuilder: (c, i) {
            var item = map[keys[i]];
            bool inStock = item['inStock'] ?? true;
            return ListTile(
              leading: item['image'] != null && item['image'].toString().isNotEmpty
                  ? CachedNetworkImage(imageUrl: item['image'], width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 50),
              title: Text(item['name'], style: const TextStyle(color: Colors.white)),
              subtitle: Text('₹${item['price']} | ${inStock ? "In Stock" : "Out of Stock"}', style: TextStyle(color: inStock ? Colors.green : Colors.red)),
              trailing: ElevatedButton(
                onPressed: !inStock ? null : () => state.addToCart(item),
                child: const Text('Add'),
              ),
            );
          },
        );
      },
    );
  }
}

class _VendorTab extends StatefulWidget {
  const _VendorTab();
  @override
  State<_VendorTab> createState() => _VendorTabState();
}

class _VendorTabState extends State<_VendorTab> {
  final nameC = TextEditingController();
  final priceC = TextEditingController();

  void _addProd() async {
    if (nameC.text.isEmpty || priceC.text.isEmpty) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    String imgPath = pickedFile != null ? pickedFile.path : '';
    
    FirebaseDatabase.instance.ref('products').push().set({
      'name': nameC.text, 
      'price': priceC.text, 
      'inStock': true,
      'image': imgPath,
    });
    nameC.clear(); priceC.clear();
  }

  @override
  Widget build(context) {
    final state = Provider.of<ShopState>(context);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SwitchListTile(title: const Text('Shop Status'), value: state.shopOpen, onChanged: state.toggleShop, activeColor: Colors.amber),
          TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Item Name')),
          TextField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
          ElevatedButton(onPressed: _addProd, child: const Text('Add Product & Pick Image')),
          const Divider(),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('products').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
                if (!snap.hasData || snap.data!.snapshot.value == null) return const SizedBox();
                Map map = snap.data!.snapshot.value as Map;
                var keys = map.keys.toList();
                return ListView.builder(
                  itemCount: keys.length,
                  itemBuilder: (c, i) {
                    var k = keys[i]; var item = map[k];
                    return ListTile(
                      title: Text(item['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(value: item['inStock'] ?? true, onChanged: (v) => FirebaseDatabase.instance.ref('products/$k').update({'inStock': v})),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseDatabase.instance.ref('products/$k').remove()),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _RiderTab extends StatelessWidget {
  const _RiderTab();
  @override
  Widget build(context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('orders').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
        if (!snap.hasData || snap.data!.snapshot.value == null) return const Center(child: Text('No Orders'));
        Map map = snap.data!.snapshot.value as Map;
        var keys = map.keys.toList();
        return ListView.builder(
          itemCount: keys.length,
          itemBuilder: (c, i) {
            HapticFeedback.vibrate();
            var ord = map[keys[i]];
            return Card(child: ListTile(
              title: Text('Order Total: ₹${ord['total']}'), 
              subtitle: Text('Status: ${ord['status']}'),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: Colors.amber),
                onPressed: () => launchUrl(Uri.parse('tel:9971968060')),
              ),
            ));
          },
        );
      },
    );
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab();
  @override
  Widget build(context) {
    final state = Provider.of<ShopState>(context);
    double total = state.cart.fold(0, (sum, i) => sum + double.parse(i['price'].toString()));
    return Column(
      children: [
        Expanded(child: ListView.builder(itemCount: state.cart.length, itemBuilder: (c, i) => ListTile(title: Text(state.cart[i]['name']), subtitle: Text('₹${state.cart[i]['price']}')))),
        ElevatedButton(
          onPressed: () {
            if (state.cart.isEmpty) return;
            FirebaseDatabase.instance.ref('orders').push().set({'items': state.cart, 'total': total, 'status': 'Pending'});
            state.clearCart();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Placed!')));
          },
          child: Text('Checkout Total ₹$total'),
        ),
      ],
    );
  }
}
