import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      children: [
        Text("About & Contact",
            style: AppTheme.heading.copyWith(fontSize: 24)),
        const SizedBox(height: 6),
        Text("Everything you need to know about FitStation.",
            style: AppTheme.body.copyWith(fontSize: 13)),
        const SizedBox(height: 28),

        // ── Who We Are ────────────────────────────────────────────────
        _card(
          icon: Icons.fitness_center_rounded,
          title: "Who We Are",
          child: Text(
            "FitStation is your all-in-one wellness companion. We provide personalized "
            "training plans, premium supplements, custom meal plans, and professional "
            "consultations — all in one place. Our mission is to help you achieve your "
            "health and fitness goals with expert guidance and community support.",
            style: AppTheme.body.copyWith(fontSize: 14, height: 1.65),
          ),
        ),
        const SizedBox(height: 16),

        // ── FAQ ───────────────────────────────────────────────────────
        _card(
          icon: Icons.help_outline_rounded,
          title: "FAQ",
          child: Column(children: [
            _faq("How do I get started?",
                "Sign up, complete your profile, and explore training plans, supplements, and meal options."),
            _faq("Can I change my plan anytime?",
                "Yes! Switch between plans at any time from your profile settings."),
            _faq("Are the supplements authentic?",
                "All supplements are sourced from certified manufacturers with full quality guarantees."),
            _faq("How do consultations work?",
                "Book a slot, confirm your location, and our certified trainers will connect with you."),
            _faq("Is my data secure?",
                "Absolutely. We use Firebase with encryption to keep your data private and safe."),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Contact ───────────────────────────────────────────────────
        _card(
          icon: Icons.contact_support_rounded,
          title: "Contact Us",
          child: Column(children: [
            _contact(Icons.phone_rounded, "Phone", "+962 7 9999 8888",
                onTap: () => launchUrl(Uri.parse("tel:+96279999888"))),
            const SizedBox(height: 14),
            _contact(Icons.email_outlined, "Email", "support@fitstation.com",
                onTap: () => launchUrl(Uri.parse("mailto:support@fitstation.com"))),
            const SizedBox(height: 14),
            _contact(Icons.location_on_outlined, "Location", "Amman, Jordan",
                onTap: null),
          ]),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _card({required IconData icon, required String title,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.card(radius: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Text(title, style: AppTheme.subheading.copyWith(fontSize: 16)),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _faq(String question, String answer) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: AppTheme.primary,
        collapsedIconColor: AppTheme.muted,
        title: Text(question,
            style: AppTheme.subheading.copyWith(
                fontSize: 14, fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(answer,
                style: AppTheme.body.copyWith(fontSize: 13, height: 1.55)),
          ),
        ],
      ),
    );
  }

  Widget _contact(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.label.copyWith(fontSize: 11)),
          Text(value,
              style: AppTheme.subheading.copyWith(
                fontSize: 14,
                color: onTap != null ? AppTheme.primary : AppTheme.dark,
                decoration: onTap != null
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: AppTheme.primary,
              )),
        ]),
      ]),
    );
  }
}
