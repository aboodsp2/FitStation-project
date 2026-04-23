import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Order Status Extensions ─────────────────────────────────────────────────
enum OrderStatus {
  processing,
  confirmed,
  assigned,    // Driver assigned
  pickedUp,    // Driver picked up
  inTransit,   // Driver delivering
  shipped,     // Keep for backward compatibility
  delivered,
  cancelled
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.assigned:
        return 'assigned';
      case OrderStatus.pickedUp:
        return 'pickedUp';
      case OrderStatus.inTransit:
        return 'inTransit';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'assigned':
        return OrderStatus.assigned;
      case 'pickedup':
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'intransit':
      case 'in_transit':
        return OrderStatus.inTransit;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.processing;
    }
  }
}

// ─── Delivery Order ──────────────────────────────────────────────────────────
class DeliveryOrder {
  final String id;
  final String userId;
  final String? driverId;
  final DateTime date;
  final double total;
  final List<OrderLineItem> items;
  final OrderStatus status;
  final String deliveryAddress;
  final String customerPhone;
  final String customerName;
  final String paymentMethod;
  final double? latitude;
  final double? longitude;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final double deliveryFee;
  final double? orderRating;
  final double? driverRating;

  const DeliveryOrder({
    required this.id,
    required this.userId,
    this.driverId,
    required this.date,
    required this.total,
    required this.items,
    required this.status,
    required this.deliveryAddress,
    required this.customerPhone,
    this.customerName = '',
    this.paymentMethod = 'cod',
    this.latitude,
    this.longitude,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.deliveryFee = 2.0,
    this.orderRating,
    this.driverRating,
  });

  factory DeliveryOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];

    return DeliveryOrder(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      driverId: data['driverId'] as String?,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      items: rawItems.map((e) {
        final m = e as Map<String, dynamic>;
        return OrderLineItem(
          name: m['name'] as String? ?? '',
          qty: (m['qty'] as num?)?.toInt() ?? 1,
          price: (m['price'] as num?)?.toDouble() ?? 0,
          imageUrl: m['imageUrl'] as String? ?? '',
        );
      }).toList(),
      status: OrderStatusExtension.fromString(data['status'] as String? ?? 'processing'),
      deliveryAddress: data['address'] as String? ?? '',
      customerPhone: data['phone'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      paymentMethod: data['payMethod'] as String? ?? 'cod',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      pickedUpAt: (data['pickedUpAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 2.0,
      orderRating: (data['orderRating'] as num?)?.toDouble(),
      driverRating: (data['driverRating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'driverId': driverId,
      'date': Timestamp.fromDate(date),
      'total': total,
      'items': items.map((item) => {
        'name': item.name,
        'qty': item.qty,
        'price': item.price,
        'imageUrl': item.imageUrl,
      }).toList(),
      'status': status.value,
      'address': deliveryAddress,
      'phone': customerPhone,
      'customerName': customerName,
      'payMethod': paymentMethod,
      'latitude': latitude,
      'longitude': longitude,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'deliveryFee': deliveryFee,
      'orderRating': orderRating,
      'driverRating': driverRating,
    };
  }
}

// ─── Order Line Item ─────────────────────────────────────────────────────────
class OrderLineItem {
  final String name;
  final int qty;
  final double price;
  final String imageUrl;

  const OrderLineItem({
    required this.name,
    required this.qty,
    required this.price,
    this.imageUrl = '',
  });
}

// ─── Driver Profile ──────────────────────────────────────────────────────────
class DriverProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final String? photoUrl;
  final bool isActive;
  final bool isAvailable;
  final double rating;
  final int ratingCount;
  final double totalRatingPoints;
  final int totalDeliveries;
  final double totalEarnings;
  final DateTime joinedDate;

  const DriverProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    this.photoUrl,
    this.isActive = true,
    this.isAvailable = true,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.totalRatingPoints = 0.0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0.0,
    required this.joinedDate,
  });

  factory DriverProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DriverProfile(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      vehicleType: data['vehicleType'] as String? ?? '',
      vehicleNumber: data['vehicleNumber'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      isAvailable: data['isAvailable'] as bool? ?? true,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      totalRatingPoints: (data['totalRatingPoints'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: (data['totalDeliveries'] as num?)?.toInt() ?? 0,
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      joinedDate: (data['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'rating': rating,
      'ratingCount': ratingCount,
      'totalRatingPoints': totalRatingPoints,
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
      'joinedDate': Timestamp.fromDate(joinedDate),
    };
  }
}
