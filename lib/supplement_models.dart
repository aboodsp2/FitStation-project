import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

// ─── DATA MODEL ──────────────────────────────────────────────────────────────
class SupplementItem {
  final String id, name, category, unit, imageUrl, description;
  final double price, rating;
  final int quantity;
  final double? discountPrice;

  const SupplementItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.rating,
    required this.quantity,
    this.imageUrl = '',
    this.description = '',
    this.discountPrice,
  });

  bool get isOnSale => discountPrice != null && discountPrice! < price;
  double get effectivePrice => discountPrice ?? price;

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory SupplementItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final dp = d['discountPrice'] != null
        ? _toDouble(d['discountPrice'])
        : null;
    return SupplementItem(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      category: d['category']?.toString() ?? '',
      unit: d['unit']?.toString() ?? '',
      price: _toDouble(d['price']),
      rating: _toDouble(d['rating']),
      quantity: _toInt(d['quantity']),
      imageUrl: d['imageUrl']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      discountPrice: dp,
    );
  }
}

// ─── SMART IMAGE WIDGET ──────────────────────────────────────────────────────
class SupplementImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const SupplementImage({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.borderRadius,
    this.fit = BoxFit.contain,
  });

  bool get _isAsset => imageUrl.startsWith('assets/');
  bool get _isNetwork => imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Icon(Icons.science_rounded, color: AppTheme.accent, size: size);
    }

    Widget img = _isAsset
        ? Image.asset(
            imageUrl,
            fit: fit,
            errorBuilder: (_, _, _) =>
                Icon(Icons.science_rounded, color: AppTheme.accent, size: size),
          )
        : _isNetwork
        ? Image.network(
            imageUrl,
            fit: fit,
            errorBuilder: (_, _, _) =>
                Icon(Icons.science_rounded, color: AppTheme.accent, size: size),
          )
        : Icon(Icons.science_rounded, color: AppTheme.accent, size: size);

    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}
