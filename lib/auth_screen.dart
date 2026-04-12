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
            onVerificationSent: (name) {
              setState(() => _tempName = name);
              _go(3);
            },
          ),
          VerifyEmailPage(onBackToLogin: () => _go(2), fullName: _tempName),
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

      // ── Check if this user is an admin ──────────────────────────────────
      final email = _emailCtrl.text.trim().toLowerCase();
      final adminRole = await AdminChecker.check(email);

      if (!mounted) return;

      if (adminRole != null) {
        // Route to Admin Panel
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminScreen(role: adminRole)),
        );
      } else {
        // Regular user — go to Dashboard
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
class SignUpPage extends StatefulWidget {
  final VoidCallback onLoginTap;
  final Function(String) onVerificationSent;
  const SignUpPage({
    super.key,
    required this.onLoginTap,
    required this.onVerificationSent,
  });
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _signUp() async {
    if (_emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _confirmPassCtrl.text.isEmpty ||
        _nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    if (_passwordCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      await cred.user?.sendEmailVerification();
      widget.onVerificationSent(_nameCtrl.text.trim());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Sign Up Failed")));
    } catch (e) {
      debugPrint("Firestore Error: $e");
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
                const SizedBox(height: 80),
                const Text(
                  "SIGN UP",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                _Input(
                  icon: Icons.person_outline,
                  hint: "Full Name",
                  controller: _nameCtrl,
                ),
                _Input(
                  icon: Icons.email_outlined,
                  hint: "Email",
                  controller: _emailCtrl,
                ),
                // Password with show/hide
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 8,
                  ),
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
                        onTap: () =>
                            setState(() => _showPassword = !_showPassword),
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
                // Confirm Password with show/hide
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _confirmPassCtrl,
                    obscureText: !_showConfirmPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        ),
                        child: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      hintText: "Confirm Password",
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
                const SizedBox(height: 30),
                _Button(
                  label: "SIGN UP",
                  color: Colors.black,
                  textColor: Colors.white,
                  onTap: _signUp,
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: widget.onLoginTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
