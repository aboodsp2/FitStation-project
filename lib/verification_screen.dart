import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screens.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isChecking = false;

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);

    // Get the current user and force Firebase to refresh their data
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    if (user?.emailVerified ?? false) {
      // If verified, proceed to the Welcome Screens!
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreens()),
        );
      }
    } else {
      // If not verified yet, show an error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Email not verified yet. Please check your inbox and spam folder.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) setState(() => _isChecking = false);
  }

  Future<void> _resendEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email resent!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please wait a moment before resending."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: Colors.pink,
            ),
            const SizedBox(height: 20),
            const Text(
              "Verify Your Email",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "We've sent a verification link to:\n${widget.email}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // CHECK STATUS BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkVerificationStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: const StadiumBorder(),
                ),
                child: _isChecking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "I'VE VERIFIED MY EMAIL",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // RESEND EMAIL BUTTON
            Center(
              child: TextButton(
                onPressed: _resendEmail,
                child: const Text(
                  "Didn't receive it? Resend Email",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
