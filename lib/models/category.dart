import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  String? name;
  String? thumbnailUrl;
  String? timestamp;

  Category({
    required this.name,
    this.thumbnailUrl,
    this.timestamp
  });

  factory Category.fromFirestore(DocumentSnapshot snap) {
    Map d = snap.data() as Map<dynamic, dynamic>;
    return Category(
        name: d['name'],
        thumbnailUrl: d['thumbnail'],
        timestamp: d['timestamp']);
  }

  static Map<String, dynamic> getMap(Category d) {
    return {
      'name': d.name,
      'thumbnail': d.thumbnailUrl,
      'timestamp': d.timestamp
    };
  }
}