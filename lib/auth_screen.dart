import 'package:fitness_app/welcome_screens.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'admin_screen.dart';

// ─── GUEST MANAGER ───────────────────────────────────────────────────────────
class GuestManager {
  static final GuestManager _instance = GuestManager._internal();
  factory GuestManager() => _instance;
  GuestManager._internal();

  bool _isGuest = false;
  bool get isGuest => _isGuest;

  void setGuest(bool value) => _isGuest = value;

  /// Shows a sign-in required dialog. Returns true if user is NOT a guest
  /// (i.e. the action should proceed). Returns false if guest and dialog shown.
  bool requireAuth(BuildContext context) {
    if (!_isGuest) return true;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 22),
            SizedBox(width: 10),
            Text(
              'Sign In Required',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppTheme.dark,
              ),
            ),
          ],
        ),
        content: const Text(
          'This feature is only available for registered users.\nSign in or create an account to continue.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppTheme.muted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe later',
              style: TextStyle(fontFamily: 'Poppins', color: AppTheme.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              GuestManager().setGuest(false);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthFlowHandler()),
                (route) => false,
              );
            },
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return false;
  }
}

class AuthFlowHandler extends StatefulWidget {
  const AuthFlowHandler({super.key});
  @override
  State<AuthFlowHandler> createState() => _AuthFlowHandlerState();
}

class _AuthFlowHandlerState extends State<AuthFlowHandler> {
  final _pageCtrl = PageController();
  String _tempName = "";
  String _tempRole = "customer";

  void _go(int page) => _pageCtrl.animateToPage(
    page,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          IntroPage(onGetStarted: () => _go(1)),
          SignInPage(onSignUpTap: () => _go(2)),
          SignUpPage(
            onLoginTap: () => _go(1),
            onVerificationSent: (name, role) {
              setState(() {
                _tempName = name;
                _tempRole = role;
              });
              _go(3);
            },
          ),
          _tempRole == 'restaurant'
              ? RestaurantApplicationSentPage(onBackToLogin: () => _go(1))
              : VerifyEmailPage(
                  onBackToLogin: () => _go(2),
                  fullName: _tempName,
                ),
        ],
      ),
    );
  }
}

// ─── VERIFY EMAIL PAGE ───────────────────────────────────────────────────────
class VerifyEmailPage extends StatefulWidget {
  final VoidCallback onBackToLogin;
  final String fullName;
  const VerifyEmailPage({
    super.key,
    required this.onBackToLogin,
    required this.fullName,
  });
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage>
    with SingleTickerProviderStateMixin {
  bool _loading = false, _resending = false;
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    final updated = FirebaseAuth.instance.currentUser;

    if (updated?.emailVerified ?? false) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updated!.uid)
          .set({
            'name': widget.fullName,
            'email': updated.email,
            'createdAt': FieldValue.serverTimestamp(),
            'isVerified': true,
          });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreens()),
        );
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Email not verified yet. Please check your inbox.",
            ),
            backgroundColor: AppTheme.primary.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Verification email resent!"),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please wait before resending."),
            backgroundColor: AppTheme.primaryLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _resending = false);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: GestureDetector(
                  onTap: () async {
                    await FirebaseAuth.instance.currentUser?.delete();
                    widget.onBackToLogin();
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: AppTheme.card(radius: 14),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              "Verify Your Email",
              style: AppTheme.heading.copyWith(
                fontSize: 28,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "We've sent a verification link to:",
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                email,
                textAlign: TextAlign.center,
                style: AppTheme.subheading.copyWith(
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  _hint(
                    Icons.inbox_rounded,
                    "Check your inbox (and spam folder)",
                  ),
                  const SizedBox(height: 8),
                  _hint(Icons.touch_app_rounded, "Tap the link in the email"),
                  const SizedBox(height: 8),
                  _hint(
                    Icons.check_circle_outline_rounded,
                    "Come back and press the button below",
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: AppTheme.primary.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 6,
                    shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "I'VE VERIFIED MY EMAIL",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resending ? null : _resend,
              child: _resending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.muted,
                      ),
                    )
                  : Text(
                      "Didn't receive it? Resend Email",
                      style: AppTheme.body.copyWith(
                        color: AppTheme.accent,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.accent,
                      ),
                    ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _hint(IconData icon, String text) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: AppTheme.body.copyWith(fontSize: 13))),
    ],
  );
}

// ─── INTRO PAGE ──────────────────────────────────────────────────────────────
class IntroPage extends StatefulWidget {
  final VoidCallback onGetStarted;
  const IntroPage({super.key, required this.onGetStarted});
  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  late VideoPlayerController _vc;

  @override
  void initState() {
    super.initState();
    _vc = VideoPlayerController.asset('assets/intro.mp4')
      ..initialize().then((_) {
        _vc.setLooping(true);
        _vc.play();
        _vc.setVolume(0);
        setState(() {});
      });
  }

  @override
  void dispose() {
    _vc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      SizedBox.expand(
        child: _vc.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _vc.value.size.width,
                  height: _vc.value.size.height,
                  child: VideoPlayer(_vc),
                ),
              )
            : Container(color: Colors.black),
      ),
      Container(color: Colors.black26),
      Column(
        children: [
          const SizedBox(height: 60),
          _LogoHeader(),
          const Spacer(),
          const Text(
            "LET'S MOVE",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const Text(
            "Fitness and wellness for\nyou anytime, anywhere.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 30),
          _Button(
            label: "GET STARTED",
            color: Colors.white,
            textColor: Colors.black,
            onTap: widget.onGetStarted,
          ),
          const SizedBox(height: 60),
        ],
      ),
    ],
  );
}

// ─── SIGN IN PAGE — saved email + show/hide password ────────────────────────
class SignInPage extends StatefulWidget {
  final VoidCallback onSignUpTap;
  const SignInPage({super.key, required this.onSignUpTap});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberEmail = false;
  bool _showPassword = false;
  bool _loading = false;

  static const _kEmail = 'saved_email';
  static const _kRemember = 'remember_email';

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kEmail) ?? '';
    final remember = prefs.getBool(_kRemember) ?? false;
    if (mounted) {
      setState(() {
        _rememberEmail = remember;
        if (remember && saved.isNotEmpty) _emailCtrl.text = saved;
      });
    }
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    setState(() => _loading = true);
    try {
      // Save email preference
      final prefs = await SharedPreferences.getInstance();
      if (_rememberEmail) {
        await prefs.setString(_kEmail, _emailCtrl.text.trim());
        await prefs.setBool(_kRemember, true);
      } else {
        await prefs.remove(_kEmail);
        await prefs.setBool(_kRemember, false);
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      GuestManager().setGuest(false);

      // Check if admin
      final adminRole = await AdminChecker.check(
        _emailCtrl.text.trim().toLowerCase(),
      );

      if (!mounted) return;
      if (adminRole != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminScreen(role: adminRole)),
        );
      } else {
        // Check if this is a pending restaurant application
        final pendingSnap = await FirebaseFirestore.instance
            .collection('registrationRequests')
            .where('ownerEmail', isEqualTo: _emailCtrl.text.trim().toLowerCase())
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();

        if (!mounted) return;

        if (pendingSnap.docs.isNotEmpty) {
          final messenger = ScaffoldMessenger.of(context);
          await FirebaseAuth.instance.signOut();
          setState(() => _loading = false);
          messenger.showSnackBar(const SnackBar(
            content: Text(
              'Your restaurant application is still pending admin approval.',
            ),
          ));
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? "Login Failed")));
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthBg(
      image: 'assets/Sign_in.jpg',
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _LogoHeader(),
            const SizedBox(height: 80),
            const Text(
              "LOG IN",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // email field
            _Input(
              icon: Icons.email_outlined,
              hint: "Email",
              controller: _emailCtrl,
            ),
            // password field with show/hide
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: TextField(
                controller: _passwordCtrl,
                obscureText: !_showPassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _showPassword = !_showPassword),
                    child: Icon(
                      _showPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                  hintText: "Password",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black45,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Remember email checkbox
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberEmail,
                      onChanged: (v) =>
                          setState(() => _rememberEmail = v ?? false),
                      checkColor: Colors.white,
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? Colors.white30
                            : Colors.transparent,
                      ),
                      side: const BorderSide(color: Colors.white60, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Remember my email",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : _Button(
                    label: "LOG IN",
                    color: Colors.black,
                    textColor: Colors.white,
                    onTap: _login,
                  ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                GuestManager().setGuest(true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
              child: const Text(
                "Continue as Guest",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: widget.onSignUpTap,
              child: const Text(
                "Don't have an account? SIGN UP",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SIGN UP PAGE ─────────────────────────────────────────────────────────────
// ─── SIGN UP PAGE ─────────────────────────────────────────────────────────────
class SignUpPage extends StatefulWidget {
  final VoidCallback onLoginTap;
  final Function(String, String) onVerificationSent; // name, role
  const SignUpPage({
    super.key,
    required this.onLoginTap,
    required this.onVerificationSent,
  });
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _step = 0; // 0 = role selection, 1 = fill form
  String _role = 'customer';

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _restNameCtrl = TextEditingController();
  final _restCuisineCtrl = TextEditingController();
  final _restPhoneCtrl = TextEditingController();
  final _restAddressCtrl = TextEditingController();
  final _restDescCtrl = TextEditingController();

  bool _showPass = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _restNameCtrl.dispose();
    _restCuisineCtrl.dispose();
    _restPhoneCtrl.dispose();
    _restAddressCtrl.dispose();
    _restDescCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Future<void> _signUp() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) {
      _snack('Please fill all fields');
      return;
    }

    if (_passwordCtrl.text != _confirmCtrl.text) {
      _snack('Passwords do not match');
      return;
    }

    if (_passwordCtrl.text.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }

    if (_role == 'restaurant' &&
        (_restNameCtrl.text.trim().isEmpty ||
            _restCuisineCtrl.text.trim().isEmpty ||
            _restPhoneCtrl.text.trim().isEmpty ||
            _restAddressCtrl.text.trim().isEmpty)) {
      _snack('Please fill all restaurant details');
      return;
    }

    setState(() => _loading = true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      final name = _nameCtrl.text.trim();

      // ── RESTAURANT FLOW: create Firebase Auth account then wait for approval ──
      if (_role == 'restaurant') {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Sign out immediately — they cannot use the app until admin approves
        await FirebaseAuth.instance.signOut();

        await FirebaseFirestore.instance
            .collection('registrationRequests')
            .add({
              'type': 'restaurant',
              'status': 'pending',
              'ownerName': name,
              'ownerEmail': email,
              'uid': cred.user!.uid,
              'restaurantName': _restNameCtrl.text.trim(),
              'cuisine': _restCuisineCtrl.text.trim(),
              'phone': _restPhoneCtrl.text.trim(),
              'address': _restAddressCtrl.text.trim(),
              'description': _restDescCtrl.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });

        widget.onVerificationSent(name, _role);
        return;
      }

      // ── CUSTOMER FLOW: create FirebaseAuth account normally ──
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.sendEmailVerification();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'name': name,
            'email': email,
            'role': _role,
            'createdAt': FieldValue.serverTimestamp(),
          });

      widget.onVerificationSent(name, _role);
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Sign Up Failed');
    } catch (e) {
      debugPrint('Error: $e');
      _snack('Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthBg(
      image: 'assets/Sign_up.jpg',
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                _LogoHeader(),
                const SizedBox(height: 36),

                if (_step == 0) ...[
                  // ── Step 0: Role selection ────────────────────────────────
                  const Text(
                    'JOIN AS',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose how you want to sign up',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  _RoleCard(
                    icon: Icons.person_rounded,
                    title: 'Customer',
                    subtitle:
                        'Browse supplements, meal plans\n& book consultations',
                    selected: _role == 'customer',
                    onTap: () => setState(() => _role = 'customer'),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.restaurant_rounded,
                    title: 'Restaurant Partner',
                    subtitle:
                        'List your restaurant & serve\nhealthy meals on FitStation',
                    selected: _role == 'restaurant',
                    onTap: () => setState(() => _role = 'restaurant'),
                  ),
                  const SizedBox(height: 36),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: GestureDetector(
                      onTap: () => setState(() => _step = 1),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'CONTINUE AS ${_role == 'restaurant' ? 'RESTAURANT' : 'CUSTOMER'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // ── Step 1: Form ──────────────────────────────────────────
                  Text(
                    _role == 'restaurant' ? 'RESTAURANT\nSIGN UP' : 'SIGN UP',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Input(
                    icon: Icons.person_outline,
                    hint: 'Full Name',
                    controller: _nameCtrl,
                  ),
                  _Input(
                    icon: Icons.email_outlined,
                    hint: 'Email',
                    controller: _emailCtrl,
                  ),

                  // Password
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _passwordCtrl,
                      obscureText: !_showPass,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _showPass = !_showPass),
                          child: Icon(
                            _showPass
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black45,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Confirm password
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _confirmCtrl,
                      obscureText: !_showConfirm,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              setState(() => _showConfirm = !_showConfirm),
                          child: Icon(
                            _showConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        hintText: 'Confirm Password',
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black45,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Restaurant extra fields
                  if (_role == 'restaurant') ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(height: 1, color: Colors.white24),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'RESTAURANT DETAILS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Input(
                      icon: Icons.storefront_rounded,
                      hint: 'Restaurant Name',
                      controller: _restNameCtrl,
                    ),
                    _Input(
                      icon: Icons.restaurant_menu_rounded,
                      hint: 'Cuisine Type (e.g. Healthy · Bowls)',
                      controller: _restCuisineCtrl,
                    ),
                    _Input(
                      icon: Icons.phone_rounded,
                      hint: 'Phone Number',
                      controller: _restPhoneCtrl,
                    ),
                    _Input(
                      icon: Icons.location_on_rounded,
                      hint: 'Address',
                      controller: _restAddressCtrl,
                    ),
                    _Input(
                      icon: Icons.description_rounded,
                      hint: 'Brief Description (optional)',
                      controller: _restDescCtrl,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.4),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your application will be reviewed by our team. You will receive an email once approved.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : _Button(
                          label: _role == 'restaurant'
                              ? 'SUBMIT APPLICATION'
                              : 'SIGN UP',
                          color: Colors.black,
                          textColor: Colors.white,
                          onTap: _signUp,
                        ),
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),

          // Back button
          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _step == 1
                    ? () => setState(() => _step = 0)
                    : widget.onLoginTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role card widget ──────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.95)
                : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.white : Colors.white30,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF5C3D2E)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? const Color(0xFF3B2214)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: selected
                            ? const Color(0xFF7A5C3E)
                            : Colors.white60,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF5C3D2E),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── RESTAURANT APPLICATION SENT PAGE ───────────────────────────────────────
class RestaurantApplicationSentPage extends StatelessWidget {
  final VoidCallback onBackToLogin;
  const RestaurantApplicationSentPage({super.key, required this.onBackToLogin});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: GestureDetector(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    onBackToLogin();
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: AppTheme.card(radius: 14),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Icon
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Application Submitted! 🎉',
              style: AppTheme.heading.copyWith(
                fontSize: 24,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                'Your restaurant application has been sent to FitStation for review.',
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(fontSize: 15, height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            // Email box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'We will notify you soon ',
                    style: AppTheme.body.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: AppTheme.subheading.copyWith(
                      fontSize: 2,
                      color: AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Steps
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  _appStep(
                    Icons.hourglass_top_rounded,
                    'Our team reviews your application',
                  ),
                  const SizedBox(height: 10),
                  _appStep(
                    Icons.email_rounded,
                    'You receive an approval or feedback email',
                  ),
                  const SizedBox(height: 10),
                  _appStep(
                    Icons.check_circle_rounded,
                    'If approved, log in and manage your restaurant',
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Also verify email notice
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please also verify your email by clicking the link we sent you.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppTheme.dark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    onBackToLogin();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 6,
                    shadowColor: AppTheme.primary.withOpacity(0.4),
                  ),
                  child: const Text(
                    'BACK TO LOGIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.8,
                    ),
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

  Widget _appStep(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(text, style: AppTheme.body.copyWith(fontSize: 13)),
        ),
      ),
    ],
  );
}

// ─── REUSABLE WIDGETS ────────────────────────────────────────────────────────
class _LogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.change_history, color: Colors.white, size: 30),
      SizedBox(width: 10),
      Text(
        "FITSTATION",
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ],
  );
}

class _Input extends StatelessWidget {
  final IconData icon;
  final String hint;
  final bool isPass;
  final TextEditingController controller;
  final TextInputType keyboardType;
  const _Input({
    required this.icon,
    required this.hint,
    required this.controller,
  }) : keyboardType = TextInputType.text,
       isPass = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
    child: TextField(
      controller: controller,
      obscureText: isPass,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black45,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

class _Button extends StatelessWidget {
  final String label;
  final Color color, textColor;
  final VoidCallback onTap;
  const _Button({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    height: 55,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ),
  );
}

class _AuthBg extends StatelessWidget {
  final String image;
  final Widget child;
  const _AuthBg({required this.image, required this.child});
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      SizedBox.expand(child: Image.asset(image, fit: BoxFit.cover)),
      Container(color: Colors.black38),
      SafeArea(child: child),
    ],
  );
}
