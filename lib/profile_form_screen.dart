import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'dashboard_screen.dart';

// Full nationality list — exported so profile_screen can reuse it
const List<String> kNationalities = [
  "Afghan",
  "Albanian",
  "Algerian",
  "American",
  "Andorran",
  "Angolan",
  "Argentinian",
  "Armenian",
  "Australian",
  "Austrian",
  "Azerbaijani",
  "Bahamian",
  "Bahraini",
  "Bangladeshi",
  "Barbadian",
  "Belarusian",
  "Belgian",
  "Belizean",
  "Beninese",
  "Bhutanese",
  "Bolivian",
  "Bosnian",
  "Botswanan",
  "Brazilian",
  "Bruneian",
  "Bulgarian",
  "Burkinabe",
  "Burundian",
  "Cambodian",
  "Cameroonian",
  "Canadian",
  "Cape Verdean",
  "Central African",
  "Chadian",
  "Chilean",
  "Chinese",
  "Colombian",
  "Comorian",
  "Congolese",
  "Costa Rican",
  "Croatian",
  "Cuban",
  "Cypriot",
  "Czech",
  "Danish",
  "Djiboutian",
  "Dominican",
  "Dutch",
  "Ecuadorian",
  "Egyptian",
  "Emirati",
  "Eritrean",
  "Estonian",
  "Ethiopian",
  "Fijian",
  "Finnish",
  "French",
  "Gabonese",
  "Gambian",
  "Georgian",
  "German",
  "Ghanaian",
  "Greek",
  "Grenadian",
  "Guatemalan",
  "Guinean",
  "Guyanese",
  "Haitian",
  "Honduran",
  "Hungarian",
  "Icelander",
  "Indian",
  "Indonesian",
  "Iranian",
  "Iraqi",
  "Irish",
  "Israeli",
  "Italian",
  "Ivorian",
  "Jamaican",
  "Japanese",
  "Jordanian",
  "Kazakhstani",
  "Kenyan",
  "Korean",
  "Kuwaiti",
  "Kyrgyz",
  "Laotian",
  "Latvian",
  "Lebanese",
  "Liberian",
  "Libyan",
  "Lithuanian",
  "Luxembourgish",
  "Malagasy",
  "Malawian",
  "Malaysian",
  "Maldivian",
  "Malian",
  "Maltese",
  "Mauritanian",
  "Mauritian",
  "Mexican",
  "Moldovan",
  "Mongolian",
  "Montenegrin",
  "Moroccan",
  "Mozambican",
  "Namibian",
  "Nepalese",
  "New Zealander",
  "Nicaraguan",
  "Nigerian",
  "Norwegian",
  "Omani",
  "Pakistani",
  "Palestinian",
  "Panamanian",
  "Paraguayan",
  "Peruvian",
  "Philippine",
  "Polish",
  "Portuguese",
  "Qatari",
  "Romanian",
  "Russian",
  "Rwandan",
  "Salvadoran",
  "Saudi Arabian",
  "Senegalese",
  "Serbian",
  "Sierra Leonean",
  "Singaporean",
  "Slovak",
  "Slovenian",
  "Somali",
  "South African",
  "South Sudanese",
  "Spanish",
  "Sri Lankan",
  "Sudanese",
  "Swedish",
  "Swiss",
  "Syrian",
  "Taiwanese",
  "Tajik",
  "Tanzanian",
  "Thai",
  "Togolese",
  "Tunisian",
  "Turkish",
  "Turkmen",
  "Ugandan",
  "Ukrainian",
  "Uruguayan",
  "Uzbekistani",
  "Venezuelan",
  "Vietnamese",
  "Yemeni",
  "Zambian",
  "Zimbabwean",
];

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});
  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _gender = "Male";
  String _goal = "Weight Loss";
  String _nationality = "";

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ── Validate age ≥ 16 ──────────────────────────────────────────────
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    if (age < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "You must be at least 16 years old to use FitStation.",
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }
    if (_nationality.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select your nationality."),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter your phone number."),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'age': age,
            'weight': double.tryParse(_weightCtrl.text) ?? 0.0,
            'height': double.tryParse(_heightCtrl.text) ?? 0.0,
            'gender': _gender,
            'goal': _goal,
            'nationality': _nationality,
            'phone': _phoneCtrl.text.trim(),
            'profileCompleted': true,
          });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _pickNationality() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NationalityPicker(),
    );
    if (result != null) setState(() => _nationality = result);
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          "Complete Your Profile",
          style: AppTheme.subheading.copyWith(fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: AppTheme.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // avatar placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tell us about yourself",
              style: AppTheme.body.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 28),

            // age — with hint about 16+
            _input(
              _ageCtrl,
              "Age (must be 16+)",
              Icons.calendar_today_outlined,
              TextInputType.number,
            ),
            const SizedBox(height: 14),
            _input(
              _weightCtrl,
              "Weight (kg)",
              Icons.monitor_weight_outlined,
              TextInputType.number,
            ),
            const SizedBox(height: 14),
            _input(
              _heightCtrl,
              "Height (cm)",
              Icons.height_rounded,
              TextInputType.number,
            ),
            const SizedBox(height: 14),
            _input(
              _phoneCtrl,
              "Phone Number",
              Icons.phone_outlined,
              TextInputType.phone,
            ),
            const SizedBox(height: 14),

            // nationality picker
            GestureDetector(
              onTap: _pickNationality,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _nationality.isEmpty
                            ? "Select Nationality"
                            : _nationality,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _nationality.isEmpty
                              ? AppTheme.muted
                              : AppTheme.dark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.muted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // gender — Male / Female only
            _sectionLabel("Gender"),
            const SizedBox(height: 10),
            Row(
              children: ["Male", "Female"].map((g) {
                final sel = _gender == g;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: g == "Male" ? 8 : 0,
                      left: g == "Female" ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary : AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel ? AppTheme.primary : AppTheme.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              g == "Male"
                                  ? Icons.male_rounded
                                  : Icons.female_rounded,
                              color: sel ? AppTheme.accent : AppTheme.muted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              g,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: sel ? Colors.white : AppTheme.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // goal
            _sectionLabel("Your Goal"),
            const SizedBox(height: 10),
            ...["Weight Loss", "Muscle Gain", "Maintenance"].map((g) {
              final sel = _goal == g;
              return GestureDetector(
                onTap: () => setState(() => _goal = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? AppTheme.primary : AppTheme.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _goalIcon(g),
                        color: sel ? AppTheme.accent : AppTheme.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        g,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: sel ? Colors.white : AppTheme.dark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      if (sel)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                ),
                onPressed: _submit,
                child: const Text(
                  "SAVE PROFILE",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String hint,
    IconData icon,
    TextInputType type,
  ) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: TextStyle(
        color: AppTheme.dark,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
      decoration: AppTheme.inputDecoration(hint, icon),
    );
  }

  Widget _sectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label, style: AppTheme.label.copyWith(fontSize: 12)),
  );

  IconData _goalIcon(String g) {
    switch (g) {
      case "Weight Loss":
        return Icons.trending_down_rounded;
      case "Muscle Gain":
        return Icons.trending_up_rounded;
      default:
        return Icons.balance_rounded;
    }
  }
}

// ── Nationality Bottom-Sheet Picker ──────────────────────────────────────────
class _NationalityPicker extends StatefulWidget {
  const _NationalityPicker();
  @override
  State<_NationalityPicker> createState() => _NationalityPickerState();
}

class _NationalityPickerState extends State<_NationalityPicker> {
  final _ctrl = TextEditingController();
  List<String> _list = List.from(kNationalities);

  void _filter(String q) => setState(() {
    _list = q.isEmpty
        ? List.from(kNationalities)
        : kNationalities
              .where((n) => n.toLowerCase().contains(q.toLowerCase()))
              .toList();
  });

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    minChildSize: 0.5,
    builder: (_, scroll) => Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text("Select Nationality", style: AppTheme.subheading),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            onChanged: _filter,
            style: TextStyle(
              color: AppTheme.dark,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            decoration: AppTheme.inputDecoration(
              "Search nationality...",
              Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: _list.length,
              itemBuilder: (_, i) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(
                  _list[i],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppTheme.dark,
                    fontSize: 14,
                  ),
                ),
                onTap: () => Navigator.pop(context, _list[i]),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.muted,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
