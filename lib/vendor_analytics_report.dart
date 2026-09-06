// ================= FILE 9 OF 10: vendor_analytics_report.dart =================
import 'package:flutter/material.dart';
import 'database_models.dart';

class VendorAnalyticsReportScreen extends StatefulWidget {
  const VendorAnalyticsReportScreen({super.key});

  @override
  State<VendorAnalyticsReportScreen> createState() => _VendorAnalyticsReportScreenState();
}

class _VendorAnalyticsReportScreenState extends State<VendorAnalyticsReportScreen> {
  @override
  Widget build(BuildContext context) {
    double totalRevenue = EnterpriseDatabase.orderLedger.fold(
      0.0,
      (sum, order) => sum + ((order['totalAmount'] as num?)?.toDouble() ?? 0.0),
    );

    int totalOrdersCount = EnterpriseDatabase.orderLedger.length;
    int totalInventoryItems = EnterpriseDatabase.globalInventory.length;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          '📊 वेंडर एनालिटिक्स और रिपोर्ट्स',
          style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.currency_rupee, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(height: 8),
                    Text(
                      '₹${totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    const Text('कुल कमाई (Revenue)', style: TextStyle(color: Colors.grey, fontSize: 9)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Color(0xFFEC4899), size: 20),
                    const SizedBox(height: 8),
                    Text(
                      '$totalOrdersCount',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    const Text('कुल ऑर्डर (Orders)', style: TextStyle(color: Colors.grey, fontSize: 9)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalInventoryItems उत्पाद',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Text('वर्तमान कैटलॉग स्टॉक (Active Inventory)', style: TextStyle(color: Colors.grey, fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'पिछले लेन-देन (Recent Transaction Ledger):',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 8),
        totalOrdersCount == 0
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('कोई बिक्री डेटा उपलब्ध नहीं है।', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalOrdersCount,
                itemBuilder: (context, index) {
                  var ord = EnterpriseDatabase.orderLedger[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(ord['orderId'] ?? '', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 11)),
                        const Spacer(),
                        Text('₹${(ord['totalAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
