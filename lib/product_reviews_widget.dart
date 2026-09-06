// ================= FILE 8 OF 10: product_reviews_widget.dart =================
import 'package:flutter/material.dart';

class ProductReviewsManager {
  static final Map<String, List<Map<String, dynamic>>> productReviewsMap = {};

  static void addReview(String productName, String customerName, double rating, String comment) {
    if (!productReviewsMap.containsKey(productName)) {
      productReviewsMap[productName] = [];
    }
    productReviewsMap[productName]!.insert(0, {
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'timestamp': DateTime.now().toString().substring(0, 16),
    });
  }

  static List<Map<String, dynamic>> getReviews(String productName) {
    return productReviewsMap[productName] ?? [];
  }

  static double getAverageRating(String productName) {
    var reviews = productReviewsMap[productName];
    if (reviews == null || reviews.isEmpty) return 5.0;
    double sum = reviews.fold(0.0, (total, item) => total + (item['rating'] as double));
    return sum / reviews.length;
  }
}

class ProductReviewsViewScreen extends StatefulWidget {
  final String productName;

  const ProductReviewsViewScreen({super.key, required this.productName});

  @override
  State<ProductReviewsViewScreen> createState() => _ProductReviewsViewScreenState();
}

class _ProductReviewsViewScreenState extends State<ProductReviewsViewScreen> {
  double _currentRating = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(text: 'Tarun Kumar');

  @override
  void dispose() {
    _reviewController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (_reviewController.text.trim().isEmpty) return;

    setState(() {
      ProductReviewsManager.addReview(
        widget.productName,
        _nameController.text.trim(),
        _currentRating,
        _reviewController.text.trim(),
      );
      _reviewController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⭐ समीक्षा सफलतापूर्वक जोड़ी गई!'), backgroundColor: Color(0xFFF59E0B)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var reviews = ProductReviewsManager.getReviews(widget.productName);
    double avgRating = ProductReviewsManager.getAverageRating(widget.productName);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: Text('${widget.productName} - समीक्षाएं', style: const TextStyle(fontSize: 14, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 36),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${avgRating.toStringAsFixed(1)} / 5.0', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('${reviews.length} कुल समीक्षाएं (Reviews)', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('अपनी समीक्षा लिखें (Write Review)', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'आपका नाम (Name)', isDense: true),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('रेटिंग (Rating): ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ...List.generate(5, (index) {
                      int starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= _currentRating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF59E0B),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _currentRating = starVal.toDouble()),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewController,
                  decoration: const InputDecoration(labelText: 'उत्पाद के बारे में लिखें...', isDense: true),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                    onPressed: _submitReview,
                    child: const Text('समीक्षा भेजें (Submit Review)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('ग्राहकों की प्रतिक्रियाएं:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          reviews.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('अभी तक कोई समीक्षा नहीं है।', style: TextStyle(color: Colors.grey, fontSize: 11))))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    var rev = reviews[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(rev['customerName'], style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 11)),
                              const Spacer(),
                              Text('⭐ ${rev['rating']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(rev['comment'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(rev['timestamp'], style: const TextStyle(color: Colors.grey, fontSize: 9)),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
