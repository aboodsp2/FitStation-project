import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dashboard_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────────────────────────────────────
class Specialist {
  final String id;
  final String name;
  final String specialty;
  final String shortBio;
  final String longBio;
  final double rating;
  final double price;
  final String type;
  final int reviews;
  final List<String> tags;
  final String avatarBg;
  final String avatarFg;
  final String initials;
  final String experience;
  final String certifications;

  const Specialist({
    required this.id,
    required this.name,
    required this.specialty,
    required this.shortBio,
    required this.longBio,
    required this.rating,
    required this.price,
    required this.type,
    required this.reviews,
    required this.tags,
    required this.avatarBg,
    required this.avatarFg,
    required this.initials,
    required this.experience,
    required this.certifications,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  8 PERSONAL TRAINERS
// ─────────────────────────────────────────────────────────────────────────────
const List<Specialist> _pts = [
  Specialist(
    id: 'pt_ahmed',
    name: 'Ahmed Al-Rashid',
    specialty: 'Strength & Conditioning',
    shortBio: 'Elite powerlifting coach with 10+ years of experience.',
    longBio:
        'Ahmed has worked with national-level powerlifters and beginners alike. He builds structured periodisation programmes focused on injury-free progressive overload, so you gain strength without burning out. His sessions are data-driven and he tracks every metric to keep you on target.',
    rating: 4.9,
    price: 25,
    type: 'pt',
    reviews: 138,
    tags: ['Powerlifting', 'Hypertrophy', 'Rehab'],
    avatarBg: 'EDE8FE',
    avatarFg: '6C63FF',
    initials: 'AA',
    experience: '10 years',
    certifications: 'NSCA-CSCS, USAW',
  ),
  Specialist(
    id: 'pt_khalid',
    name: 'Khalid Nasser',
    specialty: 'Muscle Building',
    shortBio: 'Helps busy professionals pack on lean muscle efficiently.',
    longBio:
        'Khalid specialises in hypertrophy-focused training for people with demanding schedules. His 4-day programmes are time-efficient and built around compound lifts, with smart accessory work to address imbalances. He pairs training with basic nutrition guidance so results come faster.',
    rating: 4.7,
    price: 30,
    type: 'pt',
    reviews: 94,
    tags: ['Hypertrophy', 'Body Recomp', 'Busy Schedules'],
    avatarBg: 'E1F5EE',
    avatarFg: '1D9E75',
    initials: 'KN',
    experience: '7 years',
    certifications: 'NSCA-CSCS, CPT',
  ),
  Specialist(
    id: 'pt_omar',
    name: 'Omar Khalil',
    specialty: 'HIIT & Fat Loss',
    shortBio: 'Ex-professional footballer, metabolic conditioning expert.',
    longBio:
        'Omar\'s background in professional football gives him a deep understanding of sport-specific conditioning and explosive fat loss. He designs high-intensity interval circuits that torch calories in minimal time, perfect for those who want maximum results with limited gym hours.',
    rating: 4.8,
    price: 22,
    type: 'pt',
    reviews: 76,
    tags: ['HIIT', 'Fat Loss', 'Sports'],
    avatarBg: 'FAECE7',
    avatarFg: 'D85A30',
    initials: 'OK',
    experience: '6 years',
    certifications: 'NASM-CPT, SFG',
  ),
  Specialist(
    id: 'pt_maya',
    name: 'Nadia Farouk',
    specialty: 'Pre & Postnatal Fitness',
    shortBio: 'Certified prenatal coach keeping moms strong at every stage.',
    longBio:
        'Nadia holds specialist pre and postnatal fitness certifications and has guided hundreds of mothers through safe, effective training before and after delivery. She addresses pelvic floor health, diastasis recti recovery and progressive return-to-training with compassion.',
    rating: 4.9,
    price: 30,
    type: 'pt',
    reviews: 112,
    tags: ['Prenatal', 'Postnatal', 'Pelvic Health'],
    avatarBg: 'FBEAF0',
    avatarFg: 'D4537E',
    initials: 'NF',
    experience: '8 years',
    certifications: 'PPN, NASM-CPT',
  ),
  Specialist(
    id: 'pt_ziad',
    name: 'Ziad Mansouri',
    specialty: 'Calisthenics & Bodyweight',
    shortBio: 'Master of bodyweight movement — no gym required.',
    longBio:
        'Ziad believes your body is the best piece of equipment you own. He teaches progressive calisthenics from push-ups to planche, handstands to muscle-ups. His programmes are adaptable to any environment and loved by travellers, home-trainers and anyone who wants to move freely.',
    rating: 4.6,
    price: 36,
    type: 'pt',
    reviews: 88,
    tags: ['Calisthenics', 'Handstands', 'Home Training'],
    avatarBg: 'E6F1FB',
    avatarFg: '185FA5',
    initials: 'ZM',
    experience: '5 years',
    certifications: 'ACE-CPT, GMB Coach',
  ),
  Specialist(
    id: 'pt_reem',
    name: 'Reem Al-Amin',
    specialty: 'CrossFit & Functional Fitness',
    shortBio: 'CrossFit Level 2 coach — elite fitness for everyone.',
    longBio:
        'Reem is passionate about functional fitness that translates directly to real life. Her sessions blend Olympic lifting, gymnastics and metabolic conditioning in varied, challenging workouts. She scales every session to your level so whether you are brand new or a seasoned athlete, you will be pushed the right way.',
    rating: 4.8,
    price: 29,
    type: 'pt',
    reviews: 95,
    tags: ['CrossFit', 'Olympic Lifting', 'Conditioning'],
    avatarBg: 'EAF3DE',
    avatarFg: '3B6D11',
    initials: 'RA',
    experience: '7 years',
    certifications: 'CF-L2, USAW L1',
  ),
  Specialist(
    id: 'pt_hassan',
    name: 'Hassan Qasim',
    specialty: 'Senior & Adaptive Fitness',
    shortBio: 'Safe, effective training for seniors and special needs.',
    longBio:
        'Hassan dedicates his practice to populations often overlooked: older adults, individuals with disabilities and those managing chronic conditions. His gentle, science-backed programmes improve balance, bone density, joint health and quality of life. He coordinates with physiotherapists for the safest outcomes.',
    rating: 4.7,
    price: 37,
    type: 'pt',
    reviews: 67,
    tags: ['Senior Fitness', 'Adaptive', 'Balance'],
    avatarBg: 'F1EFE8',
    avatarFg: '5F5E5A',
    initials: 'HQ',
    experience: '11 years',
    certifications: 'ACSM-CEP, ACE-SFC',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  8 NUTRITIONISTS
// ─────────────────────────────────────────────────────────────────────────────
const List<Specialist> _nutritionists = [
  Specialist(
    id: 'nut_sara',
    name: 'Sara Mansour',
    specialty: 'Weight Loss & Lifestyle',
    shortBio: 'Registered dietitian — evidence-based, zero gimmicks.',
    longBio:
        'Sara holds an MSc in Clinical Nutrition and has guided over 500 clients through sustainable fat loss. She firmly rejects fad diets, building personalised eating plans around foods you love. Her coaching covers mindful eating, habit formation and long-term weight maintenance.',
    rating: 4.8,
    price: 33,
    type: 'nutritionist',
    reviews: 212,
    tags: ['Weight Loss', 'Gut Health', 'Meal Plans'],
    avatarBg: 'E1F5EE',
    avatarFg: '1D9E75',
    initials: 'SM',
    experience: '9 years',
    certifications: 'RD, MSc Clinical Nutrition',
  ),
  Specialist(
    id: 'nut_rania',
    name: 'Rania Aziz',
    specialty: 'Sports & Performance Nutrition',
    shortBio: 'Fuel strategy for competitive athletes — training to race day.',
    longBio:
        'Rania works exclusively with serious athletes, from marathon runners to powerlifters. She designs periodised nutrition plans aligned with your training cycle, optimises pre- and post-workout fuelling and provides evidence-based supplementation protocols.',
    rating: 4.9,
    price: 70,
    type: 'nutritionist',
    reviews: 165,
    tags: ['Performance', 'Endurance', 'Supplements'],
    avatarBg: 'E6F1FB',
    avatarFg: '185FA5',
    initials: 'RA',
    experience: '10 years',
    certifications: 'RD, CSSD, MSc',
  ),
  Specialist(
    id: 'nut_hana',
    name: 'Hana Yousef',
    specialty: 'Plant-Based & Vegan Nutrition',
    shortBio: 'Whole-food plant-based eating with zero nutritional compromise.',
    longBio:
        'Hana shows that a plant-based diet can fully support any fitness goal. She ensures optimal intake of protein, B12, iron, zinc, omega-3 and calcium through clever food combining and targeted supplementation. Her meal plans are practical and culturally adapted to the Middle Eastern palate.',
    rating: 4.6,
    price: 31,
    type: 'nutritionist',
    reviews: 89,
    tags: ['Vegan', 'Gut Health', 'Anti-inflammatory'],
    avatarBg: 'FBEAF0',
    avatarFg: 'D4537E',
    initials: 'HY',
    experience: '6 years',
    certifications: 'RD, Plant-Based Cert.',
  ),
  Specialist(
    id: 'nut_tarek',
    name: 'Tarek Salim',
    specialty: 'Medical Nutrition Therapy',
    shortBio: 'Clinical dietitian for diabetes, PCOS & metabolic health.',
    longBio:
        'Tarek partners with endocrinologists and GPs to deliver integrated nutrition therapy for diabetes Type 1 and 2, PCOS, non-alcoholic fatty liver disease and metabolic syndrome. His plans are evidence-based and adapted as your labs improve.',
    rating: 4.7,
    price: 40,
    type: 'nutritionist',
    reviews: 143,
    tags: ['Diabetes', 'PCOS', 'Clinical'],
    avatarBg: 'FAECE7',
    avatarFg: 'D85A30',
    initials: 'TS',
    experience: '12 years',
    certifications: 'RD, CDE, PhD candidate',
  ),
  Specialist(
    id: 'nut_layla',
    name: 'Layla Nour',
    specialty: 'Child & Adolescent Nutrition',
    shortBio: 'Helping young athletes and picky eaters thrive nutritionally.',
    longBio:
        'Layla has dedicated her career to paediatric and adolescent nutrition, working with growing athletes, picky eaters and children with food allergies. Her sessions are family-centred with practical strategies that make healthy eating achievable and enjoyable at home.',
    rating: 4.8,
    price: 27,
    type: 'nutritionist',
    reviews: 101,
    tags: ['Kids', 'Adolescents', 'Allergies'],
    avatarBg: 'EAF3DE',
    avatarFg: '3B6D11',
    initials: 'LN',
    experience: '7 years',
    certifications: 'RD, Paediatric Nutrition Cert.',
  ),
];

const List<String> _timeSlots = [
  '8:00 AM',
  '9:00 AM',
  '10:00 AM',
  '11:00 AM',
  '12:00 PM',
  '1:00 PM',
  '2:00 PM',
  '3:00 PM',
  '4:00 PM',
  '5:00 PM',
  '6:00 PM',
];

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});
  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen>
    with SingleTickerProviderStateMixin {
  static const Color orange = Color(0xFFF37E33);
  static const Color bg = Color(0xFFF8F4EF);
  static const Color dark = Color(0xFF1A1A1A);

  late TabController _tabController;
  Specialist? _selected;
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _loadingSlots = false;
  bool _confirming = false;
  Map<String, bool> _slotAvailability = {};

  final _scrollCtrl = ScrollController();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabSwitch);
  }

  void _onTabSwitch() {
    if (!_tabController.indexIsChanging) return;
    setState(() {
      _selected = null;
      _selectedDate = null;
      _selectedTime = null;
      _slotAvailability = {};
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabSwitch)
      ..dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _dateKey => _selectedDate == null
      ? ''
      : DateFormat('yyyy-MM-dd').format(_selectedDate!);

  Future<void> _loadAvailability() async {
    if (_selected == null || _selectedDate == null) return;
    setState(() {
      _loadingSlots = true;
      _slotAvailability = {};
    });
    try {
      final doc = await _db
          .collection('specialists')
          .doc(_selected!.id)
          .collection('availability')
          .doc(_dateKey)
          .get();
      const defaultWorking = [
        '9:00 AM',
        '10:00 AM',
        '11:00 AM',
        '2:00 PM',
        '3:00 PM',
        '4:00 PM',
        '5:00 PM',
      ];
      final Map<String, bool> result = {};
      for (final slot in _timeSlots) {
        if (!doc.exists) {
          result[slot] = defaultWorking.contains(slot);
        } else {
          result[slot] = doc.data()?[slot] != false;
        }
      }
      if (mounted) {
        setState(() {
          _slotAvailability = result;
          _loadingSlots = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
      _loadAvailability();
    }
  }

  Future<void> _confirmAndPay() async {
    final s = _selected!;
    final uid = _auth.currentUser?.uid ?? 'guest';
    final slotRef = _db
        .collection('specialists')
        .doc(s.id)
        .collection('availability')
        .doc(_dateKey);
    final bookingRef = _db.collection('bookings').doc();

    setState(() => _confirming = true);

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(slotRef);
        if (snap.data()?[_selectedTime!] == false) {
          throw Exception('slot_taken');
        }
        tx.set(slotRef, {_selectedTime!: false}, SetOptions(merge: true));
        tx.set(bookingRef, {
          'userId': uid,
          'specialistId': s.id,
          'specialistName': s.name,
          'specialistType': s.type,
          'specialty': s.specialty,
          'date': _dateKey,
          'time': _selectedTime,
          'price': s.price,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      setState(() {
        _confirming = false;
        _slotAvailability[_selectedTime!] = false;
        _selected = null;
        _selectedDate = null;
        _selectedTime = null;
        _slotAvailability = {};
      });

      // Show success bottom sheet — booking goes only to My Bookings
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        builder: (_) => Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF1D9E75),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Submitted!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your session with ${s.name} is pending confirmation.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MyBookingsScreen(uid: _auth.currentUser?.uid ?? ''),
                      ),
                    );
                  },
                  child: const Text(
                    'View My Bookings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back to Consultation',
                  style: TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      final isTaken = e.toString().contains('slot_taken');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTaken
                ? '⚠️ That slot was just taken — please choose another time.'
                : 'Something went wrong. Please try again.',
          ),
          backgroundColor: isTaken ? Colors.orange : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      if (isTaken) _loadAvailability();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Consultation',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MyBookingsScreen(uid: _auth.currentUser?.uid ?? ''),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: orange.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.history_rounded, color: orange, size: 16),
                    SizedBox(width: 5),
                    Text(
                      'My Bookings',
                      style: TextStyle(
                        color: orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildList(_pts), _buildList(_nutritionists)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(30),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Personal Trainer'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Nutritionist'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Specialist> list) {
    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Choose a Specialist',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: dark,
            ),
          ),
        ),
        ...list.map(
          (s) => _SpecialistCard(
            specialist: s,
            isSelected: _selected?.id == s.id,
            onTap: () {
              setState(() {
                if (_selected?.id == s.id) {
                  _selected = null;
                } else {
                  _selected = s;
                  _selectedTime = null;
                  _slotAvailability = {};
                  if (_selectedDate != null) _loadAvailability();
                }
              });
              if (_selected != null) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            },
          ),
        ),
        if (_selected != null) ...[
          const SizedBox(height: 4),
          _buildBookingSection(),
        ],
      ],
    );
  }

  Widget _buildBookingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Pick Date & Time',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: dark,
          ),
        ),
        const SizedBox(height: 12),

        // Date picker
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: orange,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  _selectedDate == null
                      ? 'Select a date'
                      : DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!),
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.black38 : dark,
                    fontWeight: _selectedDate == null
                        ? FontWeight.normal
                        : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: Colors.black26),
              ],
            ),
          ),
        ),

        if (_selectedDate != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Available Times',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: dark,
                ),
              ),
              const SizedBox(width: 10),
              _dot(Colors.green.shade400),
              const SizedBox(width: 4),
              const Text(
                'Free',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
              const SizedBox(width: 8),
              _dot(Colors.red.shade300),
              const SizedBox(width: 4),
              const Text(
                'Booked',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingSlots)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: orange, strokeWidth: 2),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final available = _slotAvailability[slot] ?? true;
                final chosen = slot == _selectedTime;
                return GestureDetector(
                  onTap: available
                      ? () => setState(() => _selectedTime = slot)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: chosen
                          ? orange
                          : available
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: chosen
                            ? orange
                            : available
                            ? Colors.green.shade300
                            : Colors.red.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: chosen ? FontWeight.bold : FontWeight.w500,
                        color: chosen
                            ? Colors.white
                            : available
                            ? Colors.green.shade700
                            : Colors.red.shade300,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],

        const SizedBox(height: 24),
        if (_selectedTime != null) _buildConfirmCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildConfirmCard() {
    final s = _selected!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: dark,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Specialist', s.name),
          _summaryRow('Specialty', s.specialty),
          _summaryRow(
            'Date',
            DateFormat('EEE, d MMM yyyy').format(_selectedDate!),
          ),
          _summaryRow('Time', _selectedTime!),
          _summaryRow(
            'Session Fee',
            '\$${s.price.toStringAsFixed(0)}/hr',
            highlight: true,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: orange.withValues(alpha: 0.4),
              ),
              onPressed: _confirming ? null : _confirmAndPay,
              child: _confirming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Confirm & Pay  →',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black45),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: highlight ? orange : dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SPECIALIST CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SpecialistCard extends StatelessWidget {
  const _SpecialistCard({
    required this.specialist,
    required this.isSelected,
    required this.onTap,
  });

  final Specialist specialist;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color orange = Color(0xFFF37E33);
  static const Color dark = Color(0xFF1A1A1A);

  Color _hex(String h) => Color(int.parse('FF$h', radix: 16));

  @override
  Widget build(BuildContext context) {
    final s = specialist;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? orange.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? orange : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? orange.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _hex(s.avatarBg),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      s.initials,
                      style: TextStyle(
                        color: _hex(s.avatarFg),
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.specialty,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.shortBio,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        children: s.tags
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Rating / price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: orange),
                        const SizedBox(width: 2),
                        Text(
                          '${s.rating}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '(${s.reviews})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${s.price.toStringAsFixed(0)}/hr',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: dark,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Expanded bio
            if (isSelected) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text(
                s.longBio,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.black54,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip(Icons.work_outline_rounded, s.experience),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _chip(Icons.verified_outlined, s.certifications),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? _pill(
                          key: const ValueKey('sel'),
                          label: 'Selected',
                          icon: Icons.check_circle_rounded,
                          bg: orange,
                          fg: Colors.white,
                        )
                      : _pill(
                          key: const ValueKey('unsel'),
                          label: 'Select',
                          bg: orange.withValues(alpha: 0.1),
                          fg: orange,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    Key? key,
    required String label,
    IconData? icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: orange),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: orange,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MY BOOKINGS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MyBookingsScreen extends StatelessWidget {
  final String uid;
  const MyBookingsScreen({super.key, required this.uid});

  static const Color orange = Color(0xFFF37E33);
  static const Color bg = Color(0xFFF8F4EF);
  static const Color dark = Color(0xFF1A1A1A);

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF1D9E75);
      case 'cancelled':
        return Colors.red;
      default:
        return orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  IconData _typeIcon(String type) => type == 'nutritionist'
      ? Icons.restaurant_menu_rounded
      : Icons.fitness_center_rounded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: orange),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Could not load bookings.\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            );
          }
          final docs = (snap.data?.docs ?? [])
            ..sort((a, b) {
              final aTs = a.data()['createdAt'];
              final bTs = b.data()['createdAt'];
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return (bTs as dynamic).compareTo(aTs as dynamic);
            });
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 40,
                      color: orange.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No bookings yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your consultation bookings will appear here',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final status = d['status'] as String? ?? 'pending';
              final name = d['specialistName'] as String? ?? '—';
              final type = d['specialistType'] as String? ?? 'pt';
              final spec = d['specialty'] as String? ?? '—';
              final date = d['date'] as String? ?? '—';
              final time = d['time'] as String? ?? '—';
              final price = (d['price'] as num?)?.toDouble() ?? 0;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        _BookingDetailScreen(docId: docs[i].id, data: d),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── Card header ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          children: [
                            // Type icon circle
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: orange.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                _typeIcon(type),
                                color: orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name + specialty
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: dark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    spec,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  status,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusColor(
                                    status,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _statusIcon(status),
                                    size: 12,
                                    color: _statusColor(status),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(status),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.06),
                      ),

                      // ── Date / time / price row ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Colors.black38,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: Colors.black38,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${price.toStringAsFixed(0)}/hr',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: dark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.black26,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BOOKING DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _BookingDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _BookingDetailScreen({required this.docId, required this.data});

  static const Color orange = Color(0xFFF37E33);
  static const Color bg = Color(0xFFF8F4EF);
  static const Color dark = Color(0xFF1A1A1A);

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
        return const Color(0xFF1D9E75);
      case 'cancelled':
        return Colors.red;
      default:
        return orange;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String _statusMessage(String s) {
    switch (s) {
      case 'confirmed':
        return 'Your session is confirmed! The specialist will be in touch soon.';
      case 'cancelled':
        return 'This booking has been cancelled.';
      default:
        return 'Your booking is awaiting confirmation. We\'ll notify you shortly.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pull data fields
    final status = data['status'] as String? ?? 'pending';
    final name = data['specialistName'] as String? ?? '—';
    final type = data['specialistType'] as String? ?? 'pt';
    final spec = data['specialty'] as String? ?? '—';
    final date = data['date'] as String? ?? '—';
    final time = data['time'] as String? ?? '—';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final typeIcon = type == 'nutritionist'
        ? Icons.restaurant_menu_rounded
        : Icons.fitness_center_rounded;

    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Status banner ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _statusMessage(status),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Specialist card ────────────────────────────────────────────────
          _section(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(typeIcon, color: orange, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        spec,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Session info ───────────────────────────────────────────────────
          _section(
            child: Column(
              children: [
                _row(Icons.calendar_today_rounded, 'Date', date),
                const SizedBox(height: 12),
                _row(Icons.access_time_rounded, 'Time', time),
                const SizedBox(height: 12),
                _row(
                  Icons.attach_money_rounded,
                  'Session Fee',
                  '\$${price.toStringAsFixed(0)}/hr',
                  valueStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: dark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Booking ref ────────────────────────────────────────────────────
          _section(
            child: _row(
              Icons.confirmation_number_outlined,
              'Booking ID',
              docId,
              mono: true,
            ),
          ),

          const SizedBox(height: 28),

          // ── Status steps tracker ───────────────────────────────────────────
          _section(child: _buildStatusTracker(status)),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(String status) {
    const steps = ['pending', 'confirmed'];
    final isCancelled = status == 'cancelled';

    if (isCancelled) {
      return Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_rounded,
              color: Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Booking cancelled',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ],
      );
    }

    final currentIdx = steps.indexOf(status);
    final stepLabels = ['Pending', 'Confirmed'];
    final stepIcons = [Icons.hourglass_top_rounded, Icons.check_circle_rounded];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i ~/ 2 < currentIdx ? orange : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx <= currentIdx;
        return Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: done ? orange : Colors.black12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                stepIcons[idx],
                size: 17,
                color: done ? Colors.white : Colors.black38,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              stepLabels[idx],
              style: TextStyle(
                fontSize: 10,
                fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                color: done ? orange : Colors.black38,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _section({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget _row(
    IconData icon,
    String label,
    String value, {
    TextStyle? valueStyle,
    bool mono = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: orange),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style:
                valueStyle ??
                TextStyle(
                  fontFamily: mono ? 'monospace' : null,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dark,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
