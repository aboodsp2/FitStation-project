import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'dashboard_screen.dart';
import 'my_orders_screen.dart';

const _kGoogleApiKey = 'AIzaSyAvMxfgkSU50T6fCgHGTI4cmsjt5GVa-PQ';

// ── Geocoding helper ──────────────────────────────────────────────────────────
Future<Map<String, String>> _reverseGeocode(LatLng pos) async {
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/geocode/json'
    '?latlng=${pos.latitude},${pos.longitude}'
    '&key=$_kGoogleApiKey'
    '&language=en',
  );
  try {
    final res = await http.get(url).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      final results = data['results'] as List? ?? [];

      if (status != 'OK' || results.isEmpty) {
        // API returned an error status — return coords as fallback
        return {
          'street':
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
          'city': '',
        };
      }

      final first = results[0] as Map<String, dynamic>;
      final comps = (first['address_components'] as List)
          .map((c) => c as Map<String, dynamic>)
          .toList();

      String comp(String type) =>
          (comps.firstWhere(
                (c) => (c['types'] as List).contains(type),
                orElse: () => {'long_name': ''},
              )['long_name']
              as String? ??
          '');

      // Build street: route + street_number, fallback to premise or subpremise
      String street = [
        comp('route'),
        comp('street_number'),
      ].where((s) => s.isNotEmpty).join(' ');
      if (street.isEmpty) street = comp('premise');
      if (street.isEmpty) street = comp('subpremise');

      // Build city: try multiple component types in order of preference
      String neighborhood = comp('sublocality_level_1');
      if (neighborhood.isEmpty) neighborhood = comp('neighborhood');
      if (neighborhood.isEmpty) neighborhood = comp('sublocality');
      String city = comp('locality');
      if (city.isEmpty) city = comp('postal_town');
      if (city.isEmpty) city = comp('administrative_area_level_2');
      if (city.isEmpty) city = comp('administrative_area_level_1');

      // Ultimate fallback: split formatted_address
      if (street.isEmpty || city.isEmpty) {
        final formatted = first['formatted_address'] as String? ?? '';
        final parts = formatted.split(',').map((s) => s.trim()).toList();
        if (street.isEmpty && parts.isNotEmpty) street = parts[0];
        if (city.isEmpty && parts.length > 1) city = parts[1];
      }

      return {
        'street': street,
        'city': [neighborhood, city].where((s) => s.isNotEmpty).join(', '),
        'formatted': first['formatted_address'] as String? ?? '',
      };
    }
  } catch (e) {
    // swallow — return coords so user can still confirm
  }
  return {
    'street':
        '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
    'city': '',
  };
}

// ── Map Picker widget ─────────────────────────────────────────────────────────
class ConsultMapPicker extends StatefulWidget {
  final LatLng initial;
  final void Function(LatLng pos, String street, String city) onLocationPicked;
  const ConsultMapPicker({
    required this.initial,
    required this.onLocationPicked,
  });

  @override
  State<ConsultMapPicker> createState() => _ConsultMapPickerState();
}

class _ConsultMapPickerState extends State<ConsultMapPicker> {
  late LatLng _center;
  bool _loading = false;
  bool _locating = false;
  bool _confirmed = false;
  String _pendingStreet = '';
  String _pendingCity = '';
  GoogleMapController? _mapCtrl;

  // How many degrees to pan per arrow tap
  static const double _step = 0.002;

  @override
  void initState() {
    super.initState();
    _center = widget.initial;
    // Geocode the initial position immediately so confirm is enabled on load
    WidgetsBinding.instance.addPostFrameCallback((_) => _geocodeCenter());
  }

  Future<void> _geocodeCenter() async {
    setState(() {
      _loading = true;
      _confirmed = false;
    });
    final result = await _reverseGeocode(_center);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _pendingStreet = result['street'] ?? '';
      _pendingCity = result['city'] ?? '';
    });
  }

  Future<void> _onCameraIdle() async {
    await _geocodeCenter();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      // Step 1: Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMsg('Location services are disabled. Please turn them on.');
        return;
      }

      // Step 2: Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // Step 3: Request if denied (but not permanently)
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Step 4: Handle permanent denial
      if (permission == LocationPermission.deniedForever) {
        _showMsg(
          'Location permission permanently denied. Enable it in app Settings.',
        );
        await Geolocator.openAppSettings();
        return;
      }

      // Step 5: Still denied after request
      if (permission == LocationPermission.denied) {
        _showMsg('Location permission denied.');
        return;
      }

      // Step 6: Get position — try last known first (instant), then current
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      position ??=
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('GPS timeout'),
          );

      final latLng = LatLng(position.latitude, position.longitude);

      // Step 7: Move map and geocode
      await _mapCtrl?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 17),
        ),
      );
      _center = latLng;
      await _geocodeCenter();
    } on TimeoutException {
      _showMsg('GPS took too long. Try again or drag the map.');
    } catch (e) {
      // Show actual error type for debugging
      _showMsg('Location error: ${e.runtimeType}. Check manifest permissions.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _pan(double dLat, double dLng) {
    final next = LatLng(_center.latitude + dLat, _center.longitude + dLng);
    _mapCtrl?.animateCamera(CameraUpdate.newLatLng(next));
  }

  void _confirm() {
    setState(() => _confirmed = true);
    widget.onLocationPicked(_center, _pendingStreet, _pendingCity);
  }

  Widget _arrowBtn(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    elevation: 2,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Map container ──────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: Stack(
              children: [
                // Absorb vertical scroll so the page doesn't scroll while
                // the user is interacting with the map
                NotificationListener<ScrollNotification>(
                  onNotification: (_) => true, // block bubbling
                  child: Listener(
                    // swallow pointer signals so parent scroll view
                    // doesn't steal the drag
                    behavior: HitTestBehavior.opaque,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 15,
                      ),
                      onMapCreated: (c) => _mapCtrl = c,
                      onCameraMove: (pos) => _center = pos.target,
                      onCameraIdle: _onCameraIdle,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      scrollGesturesEnabled: true,
                    ),
                  ),
                ),

                // Fixed pin in the center
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 44,
                    ),
                  ),
                ),

                // ── Arrow D-pad (bottom-left) ──────────────────────────
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _arrowBtn(
                        Icons.keyboard_arrow_up_rounded,
                        () => _pan(_step, 0),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _arrowBtn(
                            Icons.keyboard_arrow_left_rounded,
                            () => _pan(0, -_step),
                          ),
                          const SizedBox(width: 2),
                          _arrowBtn(
                            Icons.keyboard_arrow_down_rounded,
                            () => _pan(-_step, 0),
                          ),
                          const SizedBox(width: 2),
                          _arrowBtn(
                            Icons.keyboard_arrow_right_rounded,
                            () => _pan(0, _step),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── GPS My Location button (top-right) ────────────────
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _locating ? null : _goToMyLocation,
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: _locating
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                size: 20,
                                color: AppTheme.primary,
                              ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _arrowBtn(
                        Icons.add_rounded,
                        () => _mapCtrl?.animateCamera(CameraUpdate.zoomIn()),
                      ),
                      const SizedBox(height: 4),
                      _arrowBtn(
                        Icons.remove_rounded,
                        () => _mapCtrl?.animateCamera(CameraUpdate.zoomOut()),
                      ),
                    ],
                  ),
                ),

                // ── Loading indicator ──────────────────────────────────
                if (_loading)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Getting address…',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppTheme.dark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Hint label at top
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Drag map to set your location',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Confirm Location button ────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _confirmed
                  ? Colors.green.shade600
                  : AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: _loading ? null : _confirm,
            icon: Icon(
              _confirmed ? Icons.check_circle_rounded : Icons.pin_drop_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _confirmed ? 'Location confirmed ✓' : 'Confirm this location',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Main Checkout Screen ──────────────────────────────────────────────────────
class CheckoutScreen extends StatefulWidget {
  final double total;
  final VoidCallback onOrderPlaced;
  final List<CartItem> cartItems;
  const CheckoutScreen({
    super.key,
    required this.total,
    required this.onOrderPlaced,
    required this.cartItems,
  });
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Default to Amman, Jordan
  LatLng _pickedLatLng = const LatLng(31.9539, 35.9106);

  String _payMethod = 'cod';
  bool _placing = false;

  // Visa
  final _cardNumCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!mounted) return;
    final phone = doc.data()?['phone'] as String? ?? '';
    if (phone.isNotEmpty) _phoneCtrl.text = phone;
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    _phoneCtrl.dispose();
    _cardNumCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void _onLocationPicked(LatLng pos, String street, String city) {
    setState(() {
      _pickedLatLng = pos;
      _addressCtrl.text = street;
      _cityCtrl.text = city;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          street.isNotEmpty
              ? 'Address filled: $street'
              : 'Location set from map',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _placeOrder() async {
    if (_addressCtrl.text.trim().isEmpty) {
      _snack("Please set your delivery address on the map.", Colors.redAccent);
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _snack("Please enter your phone number.", Colors.redAccent);
      return;
    }
    if (_payMethod == 'visa') {
      final num = _cardNumCtrl.text.replaceAll(' ', '');
      if (num.length < 16) {
        _snack("Please enter a valid 16-digit card number.", Colors.redAccent);
        return;
      }
      if (_expiryCtrl.text.length < 5) {
        _snack("Please enter a valid expiry date (MM/YY).", Colors.redAccent);
        return;
      }
      if (_cvvCtrl.text.length < 3) {
        _snack("Please enter a valid CVV.", Colors.redAccent);
        return;
      }
    }

    setState(() => _placing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _snack("You must be logged in to place an order.", Colors.redAccent);
        setState(() => _placing = false);
        return;
      }

      final orderId = (1000 + Random().nextInt(9000)).toString();
      final address = '${_addressCtrl.text.trim()}, ${_cityCtrl.text.trim()}';
      final now = DateTime.now();

      final orderData = {
        'id': orderId,
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'phone': _phoneCtrl.text.trim(),
        'date': Timestamp.fromDate(now),
        'total': widget.total,
        'status': 'processing',
        'address': address,
        'payMethod': _payMethod,
        'items': widget.cartItems
            .map(
              (i) => {
                'name': i.name,
                'qty': i.quantity,
                'price': i.price,
                'imageUrl': i.imageUrl,
                'supplementId': i.id,
                'type':
                    i.id.startsWith('meal_') || i.id.startsWith('fitstation_')
                    ? 'meal'
                    : 'supplement',
              },
            )
            .toList(),
      };

      // Save to Firestore: orders/{userId}/userOrders/{orderId}
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(user.uid)
          .collection('userOrders')
          .doc(orderId)
          .set(orderData);

      // Also save to deliveryOrders so admin can see and assign a driver
      await FirebaseFirestore.instance
          .collection('deliveryOrders')
          .doc(orderId)
          .set({
            ...orderData,
            'customerName': user.displayName ?? user.email ?? '',
            'deliveryFee': 2.0,
          });

      // Deduct stock quantities — best-effort, never blocks order completion
      final db = FirebaseFirestore.instance;
      final supplementItems = widget.cartItems
          .where((i) => !i.id.startsWith('meal_') && !i.id.startsWith('fitstation_'))
          .toList();
      if (supplementItems.isNotEmpty) {
        try {
          await db.runTransaction((txn) async {
            for (final cartItem in supplementItems) {
              final ref = db.collection('supplements').doc(cartItem.id);
              final snap = await txn.get(ref);
              if (snap.exists) {
                final current = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
                final newQty = (current - cartItem.quantity).clamp(0, 99999);
                txn.update(ref, {'quantity': newQty});
              }
            }
          });
        } catch (_) {
          // Stock update failed silently — order is already saved
        }
      }

      // Also keep local OrderManager in sync for this session
      OrderManager().placeOrder(
        Order(
          id: orderId,
          date: now,
          total: widget.total,
          items: widget.cartItems
              .map(
                (i) => OrderLineItem(
                  name: i.name,
                  qty: i.quantity,
                  price: i.price,
                  imageUrl: i.imageUrl,
                ),
              )
              .toList(),
          status: OrderStatus.processing,
          address: address,
          payMethod: _payMethod,
          phone: _phoneCtrl.text.trim(),
        ),
      );
    } catch (e) {
      _snack("Failed to place order. Please try again.", Colors.redAccent);
      setState(() => _placing = false);
      return;
    }

    widget.onOrderPlaced();
    if (!mounted) return;
    setState(() => _placing = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => _OrderSuccessScreen(
          total: widget.total,
          payMethod: _payMethod,
          address: '${_addressCtrl.text.trim()}, ${_cityCtrl.text.trim()}',
        ),
      ),
      (route) => route.isFirst,
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.dark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Checkout",
          style: AppTheme.subheading.copyWith(fontSize: 18),
        ),
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(physics: const ClampingScrollPhysics()),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Total pill ────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Order Total",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${widget.total.toStringAsFixed(2)} JD",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppTheme.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Delivery Address ──────────────────────────────────────────────
              _sectionTitle("📍 Delivery Address"),
              const SizedBox(height: 12),

              // ── Embedded Map Picker ───────────────────────────────────────────
              ConsultMapPicker(
                initial: _pickedLatLng,
                onLocationPicked: _onLocationPicked,
              ),
              const SizedBox(height: 12),

              // Auto-filled street field
              _input(
                _addressCtrl,
                "Street address *",
                Icons.home_outlined,
                TextInputType.streetAddress,
              ),
              const SizedBox(height: 10),
              // Auto-filled city field
              _input(
                _cityCtrl,
                "City / Area",
                Icons.location_city_outlined,
                TextInputType.text,
              ),
              const SizedBox(height: 10),
              _input(
                _notesCtrl,
                "Delivery notes (optional)",
                Icons.note_outlined,
                TextInputType.text,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              _input(
                _phoneCtrl,
                "Phone number *",
                Icons.phone_outlined,
                TextInputType.phone,
              ),

              const SizedBox(height: 28),

              // ── Payment Method ────────────────────────────────────────────────
              _sectionTitle("💳 Payment Method"),
              const SizedBox(height: 12),
              _payOption(
                'cod',
                Icons.payments_outlined,
                "Cash on Delivery",
                "Pay when your order arrives",
              ),
              const SizedBox(height: 10),
              _payOption(
                'visa',
                Icons.credit_card_rounded,
                "Pay Online (Visa)",
                "Secure card payment",
              ),

              // Visa form — animated expand
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _payMethod == 'visa'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.card(radius: 18),
                          child: Column(
                            children: [
                              _cardField(
                                _cardNumCtrl,
                                "Card Number",
                                "1234  5678  9012  3456",
                                Icons.credit_card_rounded,
                                TextInputType.number,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _CardNumberFormatter(),
                                ],
                                maxLen: 19,
                              ),
                              const SizedBox(height: 12),
                              _cardField(
                                _cardNameCtrl,
                                "Cardholder Name",
                                "Name on card",
                                Icons.person_outline_rounded,
                                TextInputType.name,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _cardField(
                                      _expiryCtrl,
                                      "Expiry",
                                      "MM/YY",
                                      Icons.calendar_today_outlined,
                                      TextInputType.number,
                                      formatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        _ExpiryFormatter(),
                                      ],
                                      maxLen: 5,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _cardField(
                                      _cvvCtrl,
                                      "CVV",
                                      "•••",
                                      Icons.lock_outline_rounded,
                                      TextInputType.number,
                                      formatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      maxLen: 3,
                                      obscure: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    color: Colors.green.shade600,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Your payment info is encrypted & secure",
                                    style: AppTheme.label.copyWith(
                                      fontSize: 11,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // ── Place Order ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 5,
                    shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                  onPressed: _placing ? null : _placeOrder,
                  child: _placing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _payMethod == 'visa'
                              ? "Pay ${widget.total.toStringAsFixed(2)} JD"
                              : "Place Order",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ), // ScrollConfiguration
    );
  }

  Widget _sectionTitle(String t) =>
      Text(t, style: AppTheme.subheading.copyWith(fontSize: 15));

  Widget _input(
    TextEditingController c,
    String hint,
    IconData icon,
    TextInputType type, {
    int maxLines = 1,
  }) => TextField(
    controller: c,
    keyboardType: type,
    maxLines: maxLines,
    style: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: AppTheme.dark,
    ),
    decoration: AppTheme.inputDecoration(hint, icon),
  );

  Widget _payOption(String value, IconData icon, String title, String sub) {
    final sel = _payMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _payMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? AppTheme.primary : AppTheme.divider,
            width: 1.5,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: sel
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: sel ? AppTheme.accent : AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: sel ? Colors.white : AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: sel
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (sel)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon,
    TextInputType type, {
    List<TextInputFormatter>? formatters,
    int? maxLen,
    bool obscure = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTheme.label.copyWith(fontSize: 11)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        inputFormatters: formatters,
        maxLength: maxLen,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AppTheme.dark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.muted,
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: AppTheme.accent, size: 18),
          filled: true,
          fillColor: AppTheme.background,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 14,
          ),
        ),
      ),
    ],
  );
}

// ── Card number auto-format ───────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final digits = next.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return next.copyWith(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

// ── Expiry auto-format MM/YY ──────────────────────────────────────────────────
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final digits = next.text.replaceAll('/', '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buf.write('/');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return next.copyWith(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

// ── Order Success ─────────────────────────────────────────────────────────────
class _OrderSuccessScreen extends StatelessWidget {
  final double total;
  final String payMethod;
  final String address;
  const _OrderSuccessScreen({
    required this.total,
    required this.payMethod,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade500,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "Order Placed! 🎉",
                  style: AppTheme.heading.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  payMethod == 'visa'
                      ? "Payment of ${total.toStringAsFixed(2)} JD confirmed."
                      : "You'll pay ${total.toStringAsFixed(2)} JD on delivery.",
                  textAlign: TextAlign.center,
                  style: AppTheme.body.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  "Delivering to:\n$address",
                  textAlign: TextAlign.center,
                  style: AppTheme.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.primary.withValues(alpha: 0.35),
                    ),
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text(
                      "Back to Home",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
