import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'dashboard_screen.dart';
import 'meal_cart_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class _RestaurantMeal {
  final String name;
  final String description;
  final double price;
  final String kcal;
  final String protein;
  final String tag;
  final Color tagColor;
  final IconData tagIcon;
  final String mealAsset; // local asset path from Firestore

  const _RestaurantMeal({
    required this.name,
    required this.description,
    required this.price,
    required this.kcal,
    required this.protein,
    required this.tag,
    required this.tagColor,
    required this.tagIcon,
    this.mealAsset = '',
  });
}

class _Restaurant {
  final String id, name, cuisine, deliveryTime;
  final double rating;
  final Color brandColor;
  final IconData icon;
  final String logoAsset;
  final List<_RestaurantMeal> meals;

  const _Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    required this.brandColor,
    required this.icon,
    this.logoAsset = '',
    this.meals = const [],
  });

  _Restaurant withFirestoreMeals(Map<String, String> assetMap) {
    final updated = meals.asMap().entries.map((e) {
      final key = 'm${e.key + 1}';
      return _RestaurantMeal(
        name: e.value.name,
        description: e.value.description,
        price: e.value.price,
        kcal: e.value.kcal,
        protein: e.value.protein,
        tag: e.value.tag,
        tagColor: e.value.tagColor,
        tagIcon: e.value.tagIcon,
        mealAsset: assetMap[key] ?? e.value.mealAsset,
      );
    }).toList();
    return _Restaurant(
      id: id,
      name: name,
      cuisine: cuisine,
      rating: rating,
      deliveryTime: deliveryTime,
      brandColor: brandColor,
      icon: icon,
      logoAsset: logoAsset,
      meals: updated,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATIC DATA
// ═══════════════════════════════════════════════════════════════════════════

final List<_Restaurant> _restaurants = [
  _Restaurant(
    id: 'r1',
    name: 'GreenBowl Kitchen',
    cuisine: 'Healthy · Bowls · Salads',
    rating: 4.8,
    deliveryTime: '20–30 min',
    brandColor: const Color(0xFF2D6A4F),
    icon: Icons.eco_rounded,
    logoAsset: 'assets/Rest_logo/green_bowl.jpg',
    meals: [
      _RestaurantMeal(
        name: 'Lean Green Box',
        description:
            'Grilled chicken, quinoa, avocado, mixed greens & lemon tahini dressing.',
        price: 12.99,
        kcal: '420 kcal',
        protein: '38g protein',
        tag: 'Weight Loss',
        tagColor: Color(0xFF2D6A4F),
        tagIcon: Icons.trending_down_rounded,
        mealAsset: 'assets/Rest_meals/r1_meals/r1_m1.jpg',
      ),
      _RestaurantMeal(
        name: 'Steak & Sweet Potato',
        description:
            'Grilled flank steak, roasted sweet potatoes, charred broccoli & herb chimichurri.',
        price: 14.99,
        kcal: '610 kcal',
        protein: '45g protein',
        tag: 'Lean Gain',
        tagColor: Color(0xFF4A7C59),
        tagIcon: Icons.trending_up_rounded,
        mealAsset: 'assets/Rest_meals/r1_meals/r1_m2.jpg',
      ),
      _RestaurantMeal(
        name: 'Salmon & Cauli-Rice',
        description:
            'Flaky grilled salmon, seasoned cauliflower rice, asparagus & dill-yogurt crema.',
        price: 15.49,
        kcal: '480 kcal',
        protein: '40g protein',
        tag: 'Weight Loss',
        tagColor: Color(0xFF2D6A4F),
        tagIcon: Icons.trending_down_rounded,
        mealAsset: 'assets/Rest_meals/r1_meals/r1_m3.jpg',
      ),
      _RestaurantMeal(
        name: 'Mediterranean Shrimp',
        description:
            'Grilled shrimp skewers, herb-roasted chickpeas, cucumber-tomato salad & feta crumbles.',
        price: 13.99,
        kcal: '390 kcal',
        protein: '35g protein',
        tag: 'Heart Healthy',
        tagColor: Color(0xFF1B6CA8),
        tagIcon: Icons.favorite_rounded,
        mealAsset: 'assets/Rest_meals/r1_meals/r1_m4.jpg',
      ),
      _RestaurantMeal(
        name: 'Vegan Tofu & Bean',
        description:
            'Marinated pan-seared tofu, black beans, sweet corn, red peppers & avocado-lime crema.',
        price: 11.99,
        kcal: '410 kcal',
        protein: '32g protein',
        tag: 'Plant-Based',
        tagColor: Color(0xFF6B8E23),
        tagIcon: Icons.eco_rounded,
        mealAsset: 'assets/Rest_meals/r1_meals/r1_m5.jpg',
      ),
    ],
  ),
  _Restaurant(
    id: 'r2',
    name: 'Protein Palace',
    cuisine: 'High-Protein · Grills · Wraps',
    rating: 4.6,
    deliveryTime: '25–35 min',
    brandColor: const Color(0xFF8B1A1A),
    icon: Icons.local_fire_department_rounded,
    logoAsset: 'assets/Rest_logo/protein_palace.jpg',
    meals: [
      _RestaurantMeal(
        name: 'Slim Grill Plate',
        description:
            'Grilled white fish, steamed broccoli, cherry tomatoes & fresh lemon drizzle.',
        price: 13.49,
        kcal: '380 kcal',
        protein: '42g protein',
        tag: 'Weight Loss',
        tagColor: Color(0xFF8B1A1A),
        tagIcon: Icons.trending_down_rounded,
        mealAsset: 'assets/Rest_meals/r2_meals/r2_m1.jpg',
      ),
      _RestaurantMeal(
        name: 'Classic Wrap Duo',
        description:
            'Two whole-wheat wraps with grilled chicken, melted cheese, fresh greens & ranch.',
        price: 14.99,
        kcal: '620 kcal',
        protein: '46g protein',
        tag: 'Maintain',
        tagColor: Color(0xFFB5651D),
        tagIcon: Icons.balance_rounded,
        mealAsset: 'assets/Rest_meals/r2_meals/r2_m2.jpg',
      ),
      _RestaurantMeal(
        name: 'Bulk Bomber Plate',
        description:
            'Triple beef patty, double eggs, sweet potato fries & house protein shake.',
        price: 19.99,
        kcal: '1100 kcal',
        protein: '95g protein',
        tag: 'Muscle Gain',
        tagColor: Color(0xFF6B2737),
        tagIcon: Icons.trending_up_rounded,
        mealAsset: 'assets/Rest_meals/r2_meals/r2_m3.jpg',
      ),
      _RestaurantMeal(
        name: 'BBQ Chicken Stack',
        description:
            'Smoky BBQ chicken thighs, corn, coleslaw & crispy onion strings.',
        price: 15.99,
        kcal: '720 kcal',
        protein: '58g protein',
        tag: 'High Protein',
        tagColor: Color(0xFF8B1A1A),
        tagIcon: Icons.fitness_center_rounded,
        mealAsset: 'assets/Rest_meals/r2_meals/r2_m4.jpg',
      ),
      _RestaurantMeal(
        name: 'Tuna Power Salad',
        description:
            'Seared tuna loin, mixed greens, boiled eggs, olives, capers & mustard vinaigrette.',
        price: 13.99,
        kcal: '440 kcal',
        protein: '48g protein',
        tag: 'Weight Loss',
        tagColor: Color(0xFF8B1A1A),
        tagIcon: Icons.trending_down_rounded,
        mealAsset: 'assets/Rest_meals/r2_meals/r2_m5.jpg',
      ),
    ],
  ),
  _Restaurant(
    id: 'r3',
    name: 'Zen Nourish',
    cuisine: 'Asian Fusion · Clean Eating',
    rating: 4.9,
    deliveryTime: '15–25 min',
    brandColor: const Color(0xFF1B3A4B),
    icon: Icons.spa_rounded,
    logoAsset: 'assets/Rest_logo/zen_nourish.jpg',
    meals: [
      _RestaurantMeal(
        name: 'Miso Detox Bowl',
        description:
            'Edamame, cucumber, soba noodles, poached egg & light miso broth.',
        price: 11.99,
        kcal: '360 kcal',
        protein: '24g protein',
        tag: 'Weight Loss',
        tagColor: Color(0xFF1B3A4B),
        tagIcon: Icons.trending_down_rounded,
        mealAsset: 'assets/Rest_meals/r3_meals/r3_m1.jpg',
      ),
      _RestaurantMeal(
        name: 'Teriyaki Harmony',
        description:
            'Glazed teriyaki salmon, jasmine rice, bok choy & sesame ginger dressing.',
        price: 15.49,
        kcal: '590 kcal',
        protein: '44g protein',
        tag: 'Maintain',
        tagColor: Color(0xFF2E6DA4),
        tagIcon: Icons.balance_rounded,
        mealAsset: 'assets/Rest_meals/r3_meals/r3_m2.jpg',
      ),
      _RestaurantMeal(
        name: 'Dragon Gains Bowl',
        description:
            'Beef bulgogi, double jasmine rice, kimchi, fried eggs & spicy peanut sauce.',
        price: 18.49,
        kcal: '920 kcal',
        protein: '78g protein',
        tag: 'Muscle Gain',
        tagColor: Color(0xFF1B3A4B),
        tagIcon: Icons.trending_up_rounded,
        mealAsset: 'assets/Rest_meals/r3_meals/r3_m3.jpg',
      ),
      _RestaurantMeal(
        name: 'Tofu Ramen Bowl',
        description:
            'Rich umami broth, silken tofu, bok choy, bamboo shoots, nori & soft egg.',
        price: 12.99,
        kcal: '410 kcal',
        protein: '22g protein',
        tag: 'Plant-Based',
        tagColor: Color(0xFF4CAF50),
        tagIcon: Icons.eco_rounded,
        mealAsset: 'assets/Rest_meals/r3_meals/r3_m4.jpg',
      ),
      _RestaurantMeal(
        name: 'Chicken Katsu Rice',
        description:
            'Panko-crusted chicken, steamed rice, shredded cabbage & tonkatsu sauce.',
        price: 14.49,
        kcal: '680 kcal',
        protein: '52g protein',
        tag: 'High Protein',
        tagColor: Color(0xFF1B3A4B),
        tagIcon: Icons.fitness_center_rounded,
        mealAsset: 'assets/Rest_meals/r3_meals/r3_m5.jpg',
      ),
    ],
  ),
  _Restaurant(
    id: 'r4',
    name: 'The Macro Hub',
    cuisine: 'Meal Prep · Macros · Plans',
    rating: 4.7,
    deliveryTime: '30–40 min',
    brandColor: const Color(0xFF4A3728),
    icon: Icons.calculate_rounded,
    logoAsset: 'assets/Rest_logo/macro_hub.jpg',
    meals: [
      _RestaurantMeal(
        name: 'Cut Phase Plate',
        description:
            'Tilapia fillet, asparagus, cauliflower rice & apple cider vinegar salad.',
        price: 12.49,
        kcal: '340 kcal',
        protein: '36g protein',
        tag: 'Weight Loss',
        tagColor: Color(0xFF4A3728),
        tagIcon: Icons.trending_down_rounded,
        mealAsset: 'assets/Rest_meals/r4_meals/r4_m1.jpg',
      ),
      _RestaurantMeal(
        name: 'Recomp Meal',
        description:
            'Lean turkey mince, wholegrain pasta, baby spinach & light tomato basil sauce.',
        price: 13.99,
        kcal: '560 kcal',
        protein: '48g protein',
        tag: 'Maintain',
        tagColor: Color(0xFF7A5C3E),
        tagIcon: Icons.balance_rounded,
        mealAsset: 'assets/Rest_meals/r4_meals/r4_m2.jpg',
      ),
      _RestaurantMeal(
        name: 'Mass Builder',
        description:
            'Steak bites, jasmine rice, roasted sweet potato, two fried eggs & avocado slices.',
        price: 21.99,
        kcal: '1050 kcal',
        protein: '88g protein',
        tag: 'Muscle Gain',
        tagColor: Color(0xFF4A3728),
        tagIcon: Icons.trending_up_rounded,
        mealAsset: 'assets/Rest_meals/r4_meals/r4_m3.jpg',
      ),
      _RestaurantMeal(
        name: 'Overnight Oat Box',
        description:
            'Rolled oats, Greek yogurt, chia seeds, honey, mixed berries & almond butter.',
        price: 8.99,
        kcal: '480 kcal',
        protein: '26g protein',
        tag: 'Balanced',
        tagColor: Color(0xFFC9A87C),
        tagIcon: Icons.wb_sunny_rounded,
        mealAsset: 'assets/Rest_meals/r4_meals/r4_m4.jpg',
      ),
      _RestaurantMeal(
        name: 'Power Egg Stack',
        description:
            'Five scrambled eggs, crispy turkey bacon, sautéed spinach & avocado on sourdough.',
        price: 14.49,
        kcal: '620 kcal',
        protein: '54g protein',
        tag: 'High Protein',
        tagColor: Color(0xFF4A3728),
        tagIcon: Icons.fitness_center_rounded,
        mealAsset: 'assets/Rest_meals/r4_meals/r4_m5.jpg',
      ),
    ],
  ),
  _Restaurant(
    id: 'r5',
    name: 'Flame & Harvest',
    cuisine: 'Mediterranean · Grills · Fresh',
    rating: 4.5,
    deliveryTime: '20–30 min',
    brandColor: const Color(0xFF7D4E1A),
    icon: Icons.whatshot_rounded,
    logoAsset: 'assets/Rest_logo/Flame_harvest.jpg',
    meals: [
      _RestaurantMeal(
        name: 'Mediterranean Light',
        description:
            'Grilled sea bass, tabbouleh, tzatziki sauce & warm whole-wheat pita.',
        price: 14.49,
        kcal: '410 kcal',
        protein: '40g protein',
        tag: 'Weight Loss',
        tagColor: Color(0xFF7D4E1A),
        tagIcon: Icons.trending_down_rounded,
        mealAsset: 'assets/Rest_meals/r5_meals/r5_m1.jpg',
      ),
      _RestaurantMeal(
        name: 'Harvest Platter',
        description:
            'Lamb kofta, couscous, roasted peppers, hummus & pomegranate glaze.',
        price: 16.49,
        kcal: '640 kcal',
        protein: '42g protein',
        tag: 'Maintain',
        tagColor: Color(0xFFAD6F3B),
        tagIcon: Icons.balance_rounded,
        mealAsset: 'assets/Rest_meals/r5_meals/r5_m2.jpg',
      ),
      _RestaurantMeal(
        name: 'Warrior Feast',
        description:
            'Mixed grill — chicken, lamb & beef kebabs, fragrant rice & garlic sauce.',
        price: 22.99,
        kcal: '980 kcal',
        protein: '86g protein',
        tag: 'Muscle Gain',
        tagColor: Color(0xFF7D4E1A),
        tagIcon: Icons.trending_up_rounded,
        mealAsset: 'assets/Rest_meals/r5_meals/r5_m3.jpg',
      ),
      _RestaurantMeal(
        name: 'Falafel Power Bowl',
        description:
            'Crispy falafel, roasted chickpeas, brown rice, pickled veg & tahini dressing.',
        price: 12.49,
        kcal: '530 kcal',
        protein: '28g protein',
        tag: 'Plant-Based',
        tagColor: Color(0xFF5E8C31),
        tagIcon: Icons.eco_rounded,
        mealAsset: 'assets/Rest_meals/r5_meals/r5_m4.jpg',
      ),
      _RestaurantMeal(
        name: 'Shawarma Plate',
        description:
            'Slow-roasted chicken shawarma, garlic sauce, pickled cabbage & parsley on rice.',
        price: 13.99,
        kcal: '680 kcal',
        protein: '52g protein',
        tag: 'High Protein',
        tagColor: Color(0xFF7D4E1A),
        tagIcon: Icons.fitness_center_rounded,
        mealAsset: 'assets/Rest_meals/r5_meals/r5_m5.jpg',
      ),
    ],
  ),
  _Restaurant(
    id: 'r6',
    name: 'NutriBowl Co.',
    cuisine: 'Smoothie Bowls · Wraps · Juices',
    rating: 4.4,
    deliveryTime: '10–20 min',
    brandColor: const Color(0xFF5B4FCF),
    icon: Icons.blender_rounded,
    logoAsset: 'assets/Rest_logo/nutri_bowl.jpg',
    meals: [
      _RestaurantMeal(
        name: 'Berry Slim Bowl',
        description:
            'Acai, strawberry, banana, chia seeds, crunchy granola & raw honey.',
        price: 9.99,
        kcal: '390 kcal',
        protein: '14g protein',
        tag: 'Weight Loss',
        tagColor: Color(0xFF5B4FCF),
        tagIcon: Icons.trending_down_rounded,
        mealAsset: 'assets/Rest_meals/r6_meals/r6_m1.jpg',
      ),
      _RestaurantMeal(
        name: 'Tropical Balance',
        description:
            'Mango, pineapple, coconut yogurt, oats, flaxseed & passion fruit coulis.',
        price: 11.49,
        kcal: '520 kcal',
        protein: '18g protein',
        tag: 'Maintain',
        tagColor: Color(0xFF7B6FCF),
        tagIcon: Icons.balance_rounded,
        mealAsset: 'assets/Rest_meals/r6_meals/r6_m2.jpg',
      ),
      _RestaurantMeal(
        name: 'Protein Surge Bowl',
        description:
            'Peanut butter banana base, double whey scoop, oats, cacao nibs & dark chocolate.',
        price: 13.99,
        kcal: '720 kcal',
        protein: '52g protein',
        tag: 'Muscle Gain',
        tagColor: Color(0xFF3B2FA8),
        tagIcon: Icons.trending_up_rounded,
        mealAsset: 'assets/Rest_meals/r6_meals/r6_m3.jpg',
      ),
      _RestaurantMeal(
        name: 'Green Detox Wrap',
        description:
            'Spinach tortilla, hummus, cucumber, avocado, sprouts & lemon herb dressing.',
        price: 10.49,
        kcal: '350 kcal',
        protein: '16g protein',
        tag: 'Plant-Based',
        tagColor: Color(0xFF4CAF50),
        tagIcon: Icons.eco_rounded,
        mealAsset: 'assets/Rest_meals/r6_meals/r6_m4.jpg',
      ),
      _RestaurantMeal(
        name: 'Citrus Boost Juice',
        description:
            'Cold-pressed orange, ginger, turmeric, carrot & lemon — energising immunity combo.',
        price: 7.49,
        kcal: '180 kcal',
        protein: '4g protein',
        tag: 'Detox',
        tagColor: Color(0xFFE67E22),
        tagIcon: Icons.wb_sunny_rounded,
        mealAsset: 'assets/Rest_meals/r6_meals/r6_m5.jpg',
      ),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// FIRESTORE HELPER
// ═══════════════════════════════════════════════════════════════════════════

Future<Map<String, String>> _fetchMealAssets(String restaurantId) async {
  final snap = await FirebaseFirestore.instance
      .collection('resturants')
      .doc(restaurantId)
      .collection('meals')
      .get();
  return {
    for (final doc in snap.docs)
      doc.id: (doc.data()['mealAsset'] as String? ?? ''),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// MEAL DETAIL BOTTOM SHEET  (mirrors _ProductDetailSheet in supplement store)
// ═══════════════════════════════════════════════════════════════════════════

class _MealDetailSheet extends StatefulWidget {
  final _RestaurantMeal meal;
  final String restaurantName;
  const _MealDetailSheet({required this.meal, required this.restaurantName});

  @override
  State<_MealDetailSheet> createState() => _MealDetailSheetState();
}

class _MealDetailSheetState extends State<_MealDetailSheet> {
  int _qty = 1;

  void _addToCart(BuildContext ctx) {
    for (int i = 0; i < _qty; i++) {
      MealCartManager().addItem(
        CartItem(
          id: 'meal_${widget.restaurantName}_${widget.meal.name}',
          name: '${widget.meal.name} — ${widget.restaurantName}',
          price: widget.meal.price,
          quantity: 1,
          icon: Icons.restaurant_rounded,
          imageUrl: widget.meal.mealAsset, // ← meal photo
        ),
      );
    }
    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.meal.name} × $_qty added to cart!',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // ── Meal image — large ────────────────────────────────────────
            Container(
              height: 230,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: meal.tagColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: meal.mealAsset.isNotEmpty
                  ? Image.asset(
                      meal.mealAsset,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _imageFallback(meal),
                    )
                  : _imageFallback(meal),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tag badge ────────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: meal.tagColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(meal.tagIcon, color: Colors.white, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          meal.tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Name ─────────────────────────────────────────────────
                  Text(
                    meal.name,
                    style: AppTheme.heading.copyWith(fontSize: 20, height: 1.2),
                  ),
                  const SizedBox(height: 4),

                  // ── Restaurant name ───────────────────────────────────────
                  Text(
                    widget.restaurantName,
                    style: AppTheme.body.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // ── Macro chips ───────────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _macroChip('🔥 ${meal.kcal}'),
                      _macroChip('💪 ${meal.protein}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Price ─────────────────────────────────────────────────
                  Text(
                    '\$${meal.price.toStringAsFixed(2)} / meal',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),

                  // ── Description ───────────────────────────────────────────
                  if (meal.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'About this meal',
                      style: AppTheme.subheading.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meal.description,
                      style: AppTheme.body.copyWith(fontSize: 13, height: 1.6),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Qty + Add to Cart ─────────────────────────────────────
                  Row(
                    children: [
                      // Quantity controls
                      Container(
                        decoration: AppTheme.card(radius: 30),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _qtyBtn(Icons.remove, () {
                              if (_qty > 1) setState(() => _qty--);
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                '$_qty',
                                style: AppTheme.subheading.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _qtyBtn(Icons.add, () => setState(() => _qty++)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Add to Cart button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 4,
                              shadowColor: AppTheme.primary.withOpacity(0.35),
                            ),
                            onPressed: () => _addToCart(context),
                            child: Text(
                              'Add $_qty to Cart',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(_RestaurantMeal meal) => Center(
    child: Icon(
      Icons.restaurant_menu_rounded,
      size: 80,
      color: meal.tagColor.withOpacity(0.4),
    ),
  );

  Widget _macroChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.primary,
      ),
    ),
  );

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppTheme.primary, size: 18),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPLORE RESTAURANTS SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class ExploreRestaurantsScreen extends StatefulWidget {
  const ExploreRestaurantsScreen({super.key});
  @override
  State<ExploreRestaurantsScreen> createState() =>
      _ExploreRestaurantsScreenState();
}

class _ExploreRestaurantsScreenState extends State<ExploreRestaurantsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Restaurant> get _filtered => _restaurants
      .where(
        (r) =>
            r.name.toLowerCase().contains(_query.toLowerCase()) ||
            r.cuisine.toLowerCase().contains(_query.toLowerCase()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 16, 20),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Explore Restaurants',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_restaurants.length} healthy spots near you',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ExploreCartBadge(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: AppTheme.body.copyWith(
                  color: AppTheme.dark,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search restaurants or cuisine...',
                  hintStyle: AppTheme.body.copyWith(fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.accent,
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.muted,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.accent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text('No restaurants found', style: AppTheme.body),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _RestaurantCard(restaurant: _filtered[i]),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Cart badge ────────────────────────────────────────────────────────────────
class _ExploreCartBadge extends StatefulWidget {
  @override
  State<_ExploreCartBadge> createState() => _ExploreCartBadgeState();
}

class _ExploreCartBadgeState extends State<_ExploreCartBadge> {
  @override
  void initState() {
    super.initState();
    MealCartManager().addListener(_refresh);
  }

  @override
  void dispose() {
    MealCartManager().removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = MealCartManager().totalCount;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MealCartScreen()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Restaurant list card ──────────────────────────────────────────────────────
class _RestaurantCard extends StatelessWidget {
  final _Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _RestaurantDetailScreen(restaurant: restaurant),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: restaurant.logoAsset.isNotEmpty
                  ? Image.asset(
                      restaurant.logoAsset,
                      width: 86,
                      height: 86,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _logoFallback(),
                    )
                  : _logoFallback(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: AppTheme.subheading.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      restaurant.cuisine,
                      style: AppTheme.body.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFF8C00),
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(0xFFFF8C00),
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(width: 3),
                        Text(restaurant.deliveryTime, style: AppTheme.label),
                        const Spacer(),
                        Text(
                          '${restaurant.meals.length} meals',
                          style: AppTheme.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.accent,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoFallback() => Container(
    width: 86,
    height: 86,
    color: restaurant.brandColor,
    child: Icon(
      restaurant.icon,
      color: Colors.white.withOpacity(0.9),
      size: 34,
    ),
  );
}

// ── Restaurant detail screen ──────────────────────────────────────────────────
class _RestaurantDetailScreen extends StatefulWidget {
  final _Restaurant restaurant;
  const _RestaurantDetailScreen({required this.restaurant});

  @override
  State<_RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<_RestaurantDetailScreen> {
  late Future<_Restaurant> _restaurantWithImages;

  @override
  void initState() {
    super.initState();
    _restaurantWithImages = _fetchMealAssets(
      widget.restaurant.id,
    ).then((assetMap) => widget.restaurant.withFirestoreMeals(assetMap));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Restaurant>(
      future: _restaurantWithImages,
      builder: (context, snapshot) {
        final restaurant = snapshot.data ?? widget.restaurant;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              // ── Hero ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: restaurant.brandColor,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: const MealCartBadge(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              restaurant.brandColor,
                              restaurant.brandColor.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: restaurant.logoAsset.isNotEmpty
                                    ? Image.asset(
                                        restaurant.logoAsset,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          restaurant.icon,
                                          color: restaurant.brandColor,
                                          size: 42,
                                        ),
                                      )
                                    : Icon(
                                        restaurant.icon,
                                        color: restaurant.brandColor,
                                        size: 42,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              restaurant.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              restaurant.cuisine,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          color: Colors.black.withOpacity(0.3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _chip(
                                Icons.star_rounded,
                                restaurant.rating.toStringAsFixed(1),
                                'Rating',
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              _chip(
                                Icons.access_time_rounded,
                                restaurant.deliveryTime,
                                'Delivery',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section title ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu',
                        style: AppTheme.heading.copyWith(fontSize: 20),
                      ),
                      Text(
                        'Tap any meal to view details',
                        style: AppTheme.body.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Meal cards ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _MealRowCard(
                      meal: restaurant.meals[i],
                      restaurantName: restaurant.name,
                      isLoading: isLoading,
                    ),
                    childCount: restaurant.meals.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String value, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontFamily: 'Poppins',
          fontSize: 10,
        ),
      ),
    ],
  );
}

// ── Meal row card — tap opens bottom sheet, button adds to cart ───────────────
class _MealRowCard extends StatelessWidget {
  final _RestaurantMeal meal;
  final String restaurantName;
  final bool isLoading;

  const _MealRowCard({
    required this.meal,
    required this.restaurantName,
    this.isLoading = false,
  });

  // Opens the detail bottom sheet (no cart action)
  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _MealDetailSheet(meal: meal, restaurantName: restaurantName),
    );
  }

  // Adds directly to cart (only called from the "Add to Cart" button)
  void _addToCartDirect(BuildContext context) {
    MealCartManager().addItem(
      CartItem(
        id: 'meal_${restaurantName}_${meal.name}',
        name: '${meal.name} — $restaurantName',
        price: meal.price,
        quantity: 1,
        icon: Icons.restaurant_rounded,
        imageUrl: meal.mealAsset, // ← meal photo
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${meal.name} added to cart!',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap the card → open detail sheet
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Meal image ───────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: _buildMealImage(),
            ),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: AppTheme.subheading.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meal.description,
                      style: AppTheme.body.copyWith(fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _tagChip(meal.tag, meal.tagColor, meal.tagIcon),
                        _macroChip('🔥 ${meal.kcal}'),
                        _macroChip('💪 ${meal.protein}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '\$${meal.price.toStringAsFixed(2)}',
                                style: AppTheme.subheading.copyWith(
                                  fontSize: 16,
                                  color: AppTheme.dark,
                                ),
                              ),
                              TextSpan(
                                text: ' / meal',
                                style: AppTheme.label.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // ── "Add to Cart" button — stops propagation ───────
                        GestureDetector(
                          onTap: () => _addToCartDirect(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealImage() {
    if (isLoading) {
      return _ShimmerBox(
        width: 100,
        height: 110,
        baseColor: meal.tagColor.withOpacity(0.08),
        highlightColor: meal.tagColor.withOpacity(0.18),
      );
    }
    if (meal.mealAsset.isNotEmpty) {
      return Image.asset(
        meal.mealAsset,
        width: 100,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _iconFallback(),
      );
    }
    return _iconFallback();
  }

  Widget _iconFallback() => Container(
    width: 100,
    height: 110,
    color: meal.tagColor.withOpacity(0.12),
    child: Icon(
      Icons.restaurant_menu_rounded,
      size: 38,
      color: meal.tagColor.withOpacity(0.45),
    ),
  );

  Widget _tagChip(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _macroChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.07),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: AppTheme.label.copyWith(
        fontSize: 10,
        color: AppTheme.primaryLight,
      ),
    ),
  );
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width, height;
  final Color baseColor, highlightColor;
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: widget.width,
      height: widget.height,
      color: Color.lerp(widget.baseColor, widget.highlightColor, _anim.value),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// GOAL STYLES & MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class _GoalStyle {
  final Color cardBg, iconBg, iconColor, titleColor, subColor;
  const _GoalStyle({
    required this.cardBg,
    required this.iconBg,
    required this.iconColor,
    required this.titleColor,
    required this.subColor,
  });
}

const _styleWeightLoss = _GoalStyle(
  cardBg: Color(0xFF5C3D2E),
  iconBg: Color(0xFF7A5240),
  iconColor: Color(0xFFC9A87C),
  titleColor: Colors.white,
  subColor: Color(0xFFD4B896),
);
const _styleMaintain = _GoalStyle(
  cardBg: Color(0xFFE6D3B3),
  iconBg: Color(0xFFD4BB95),
  iconColor: Color(0xFF5C3D2E),
  titleColor: Color(0xFF3B2214),
  subColor: Color(0xFF7A5C3E),
);
const _styleMuscleGain = _GoalStyle(
  cardBg: Color(0xFF3B2214),
  iconBg: Color(0xFF5C3D2E),
  iconColor: Color(0xFFC9A87C),
  titleColor: Colors.white,
  subColor: Color(0xFFBFA08A),
);

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});
  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  String? _userGoal;
  bool _loading = true;

  static const Map<String, String> _goalMap = {
    "Weight Loss": "Weight Loss",
    "Muscle Gain": "Muscle Gain",
    "Maintenance": "Maintain",
    "Maintain": "Maintain",
  };

  static const List<Map<String, dynamic>> _goals = [
    {
      "label": "Weight Loss Plan",
      "icon": Icons.trending_down_rounded,
      "cal": "1,500 kcal/day",
      "style": _styleWeightLoss,
    },
    {
      "label": "Maintain Weight Plan",
      "icon": Icons.balance_rounded,
      "cal": "2,000 kcal/day",
      "style": _styleMaintain,
    },
    {
      "label": "Muscle Gain Plan",
      "icon": Icons.trending_up_rounded,
      "cal": "2,800 kcal/day",
      "style": _styleMuscleGain,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserGoal();
  }

  Future<void> _loadUserGoal() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (mounted) {
          final raw = doc.data()?['goal'] as String?;
          setState(() {
            _userGoal = raw != null ? (_goalMap[raw] ?? raw) : null;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Meal Plans"),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: [
                if (_userGoal != null) ...[
                  _RecommendedBanner(goalLabel: _userGoal!),
                  const SizedBox(height: 20),
                ],
                Text(
                  "What's your goal?",
                  style: AppTheme.body.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 14),
                ..._goals.map((goal) {
                  final bool isRec = _userGoal == goal["label"];
                  final _GoalStyle st = goal["style"] as _GoalStyle;
                  return _GoalCard(
                    goal: goal,
                    style: st,
                    isRecommended: isRec,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _MealDetailScreen(
                          goalLabel: goal["label"] as String,
                          goalStyle: st,
                          goalCal: goal["cal"] as String,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                _ExploreRestaurantsCard(),
              ],
            ),
    );
  }
}

// ── Recommended Banner ────────────────────────────────────────────────────────
class _RecommendedBanner extends StatelessWidget {
  final String goalLabel;
  const _RecommendedBanner({required this.goalLabel});

  String get _desc {
    switch (goalLabel) {
      case "Weight Loss":
        return "Based on your profile, a calorie-deficit plan will help you reach your target weight.";
      case "Maintain":
        return "Based on your profile, a balanced plan will help you sustain your current physique.";
      case "Muscle Gain":
        return "Based on your profile, a high-protein surplus plan will maximise your muscle growth.";
      default:
        return "We picked the best plan based on your profile goal.";
    }
  }

  IconData get _icon {
    switch (goalLabel) {
      case "Weight Loss":
        return Icons.trending_down_rounded;
      case "Muscle Gain":
        return Icons.trending_up_rounded;
      default:
        return Icons.balance_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: AppTheme.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Recommended",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        goalLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final _GoalStyle style;
  final bool isRecommended;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.style,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: style.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: isRecommended
              ? Border.all(color: AppTheme.accent, width: 2)
              : Border.all(color: Colors.white.withOpacity(0.04), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: isRecommended
                        ? AppTheme.accent
                        : AppTheme.accent.withOpacity(0.35),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: style.iconBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accent.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        goal["icon"] as IconData,
                        color: style.iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                goal["label"] as String,
                                style: TextStyle(
                                  color: style.titleColor,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              if (isRecommended) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "For you",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            goal["cal"] as String,
                            style: TextStyle(
                              color: style.subColor,
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: style.subColor,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Explore Restaurants Card ──────────────────────────────────────────────────
class _ExploreRestaurantsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExploreRestaurantsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppTheme.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Explore Restaurants",
                    style: AppTheme.subheading.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Find healthy spots near you",
                    style: AppTheme.body.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.accent,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meal Detail Screen (goal-based plans) ─────────────────────────────────────
// Firestore key mapping: "Weight Loss Plan" → "weight_loss", etc.
String _planFirestoreKey(String goalLabel) {
  switch (goalLabel) {
    case "Weight Loss Plan":
    case "Weight Loss":
      return "weight_loss";
    case "Maintain Weight Plan":
    case "Maintain":
      return "maintain";
    case "Muscle Gain Plan":
    case "Muscle Gain":
      return "muscle_gain";
    default:
      return goalLabel.toLowerCase().replaceAll(' ', '_');
  }
}

class _MealDetailScreen extends StatefulWidget {
  final String goalLabel;
  final _GoalStyle goalStyle;
  final String goalCal;

  const _MealDetailScreen({
    required this.goalLabel,
    required this.goalStyle,
    required this.goalCal,
  });

  @override
  State<_MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<_MealDetailScreen> {
  // Firestore-loaded sections (null = not loaded yet)
  List<Map<String, dynamic>>? _firestoreSections;
  bool _loadingFirestore = true;

  @override
  void initState() {
    super.initState();
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final planKey = _planFirestoreKey(widget.goalLabel);
      final snap = await FirebaseFirestore.instance
          .collection('meal_plans')
          .doc(planKey)
          .collection('sections')
          .orderBy('order')
          .get();

      if (snap.docs.isNotEmpty && mounted) {
        final sections = snap.docs.map((doc) {
          final data = doc.data();
          final rawItems = data['items'] as List<dynamic>? ?? [];
          final items = rawItems
              .map((i) => Map<String, dynamic>.from(i as Map))
              .toList();
          return {'section': data['section'] as String? ?? '', 'items': items};
        }).toList();
        setState(() {
          _firestoreSections = sections;
          _loadingFirestore = false;
        });
      } else {
        if (mounted) setState(() => _loadingFirestore = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFirestore = false);
    }
  }

  static const Map<String, List<Map<String, dynamic>>> _staticSections = {
    "Weight Loss": [
      {
        "section": "BREAKFAST",
        "items": [
          {
            "name": "Sunrise Fuel",
            "asset": "assets/meals/weight_loss/sunrise_fuel.jpg",
            "desc":
                "A balanced plate of eggs, avocado, vegetables, and chickpeas — rich in protein, fiber, and healthy fats to support energy and metabolism.",
            "kcal": "250 kcal",
            "protein": "22g Protein",
            "carbs": "28g Carbs",
            "fat": "32g Fat",
          },
          {
            "name": "Berry Power Bowl",
            "asset": "assets/meals/weight_loss/berry_bowl.jpg",
            "desc":
                "A creamy bowl of oats and chia topped with bananas, strawberries, blueberries, and walnuts for sustained energy and antioxidant support.",
            "kcal": "300 kcal",
            "protein": "14g Protein",
            "carbs": "51g Carbs",
            "fat": "16g Fat",
          },
          {
            "name": "Hummus Toast",
            "asset": "assets/meals/weight_loss/hummus_toast.jpg",
            "desc":
                "Whole grain toast with creamy hummus, roasted chickpeas, cherry tomatoes, arugula, and a light balsamic drizzle.",
            "kcal": "290 kcal",
            "protein": "17g Protein",
            "carbs": "45g Carbs",
            "fat": "14g Fat",
          },
        ],
      },
      {
        "section": "LUNCH",
        "items": [
          {
            "name": "Steak & Strength",
            "asset": "assets/meals/weight_loss/steak_lunch.jpg",
            "desc":
                "Grilled steak with mashed potatoes, roasted vegetables, and greens — a balanced, high-protein lunch.",
            "kcal": "650 kcal",
            "protein": "52g Protein",
            "carbs": "40g Carbs",
            "fat": "25g Fat",
          },
          {
            "name": "Grilled Salmon Plate",
            "asset": "assets/meals/weight_loss/salmon_plate.jpg",
            "desc":
                "Grilled salmon with roasted vegetables and lemon for a clean, high-protein meal rich in omega-3s.",
            "kcal": "500 kcal",
            "protein": "48g Protein",
            "carbs": "38g Carbs",
            "fat": "22g Fat",
          },
          {
            "name": "Grilled Chicken Plate",
            "asset": "assets/meals/weight_loss/chicken_plate.jpg",
            "desc":
                "Grilled chicken breast served with white rice and a fresh vegetable salad for a balanced, lean meal.",
            "kcal": "520 kcal",
            "protein": "44g Protein",
            "carbs": "45g Carbs",
            "fat": "15g Fat",
          },
        ],
      },
      {
        "section": "DINNER",
        "items": [
          {
            "name": "Caesar Wrap",
            "asset": "assets/meals/weight_loss/caesar_wrap.jpg",
            "desc":
                "Grilled chicken, romaine lettuce, tortilla wrap, and Caesar dressing for a high-protein satisfying meal.",
            "kcal": "360 kcal",
            "protein": "32g Protein",
            "carbs": "35g Carbs",
            "fat": "34g Fat",
          },
          {
            "name": "Tuna Beast",
            "asset": "assets/meals/weight_loss/tuna_beast.jpg",
            "desc":
                "Whole grain bread with tuna, lettuce, tomato, cucumber, and olives for a protein-rich meal.",
            "kcal": "290 kcal",
            "protein": "38g Protein",
            "carbs": "12g Carbs",
            "fat": "10g Fat",
          },
          {
            "name": "Stuffed Grape Leaves",
            "asset": "assets/meals/weight_loss/grape_leaves.jpg",
            "desc":
                "Grape leaves stuffed with rice, herbs, and light seasoning for a traditional, fiber-rich dinner.",
            "kcal": "300 kcal",
            "protein": "15g Protein",
            "carbs": "45g Carbs",
            "fat": "11g Fat",
          },
        ],
      },
    ],
    "Maintain": [
      {
        "section": "BREAKFAST",
        "items": [
          {
            "name": "Steak & Egg Plate",
            "asset": "assets/meals/maintain/steak_egg_plate.jpg",
            "desc":
                "Juicy grilled steak slices with fluffy scrambled eggs, roasted cherry tomatoes, crispy potatoes, and fresh spinach.",
            "kcal": "520 kcal",
            "protein": "44g Protein",
            "carbs": "28g Carbs",
            "fat": "26g Fat",
          },
          {
            "name": "Protein Hash Bowl",
            "asset": "assets/meals/maintain/protein_hash_bowl.jpg",
            "desc":
                "Scrambled eggs with seasoned ground meat, roasted red potatoes, melted cheddar, fresh herbs, and a side of house salsa.",
            "kcal": "480 kcal",
            "protein": "36g Protein",
            "carbs": "32g Carbs",
            "fat": "22g Fat",
          },
        ],
      },
      {
        "section": "LUNCH",
        "items": [
          {
            "name": "Chicken Mandi",
            "asset": "assets/meals/maintain/chicken_mandi.jpg",
            "desc":
                "Tender spiced chicken breast on a bed of fragrant saffron rice, topped with fresh cilantro and a creamy yogurt dip.",
            "kcal": "580 kcal",
            "protein": "48g Protein",
            "carbs": "52g Carbs",
            "fat": "14g Fat",
          },
          {
            "name": "Protein Cobb Salad",
            "asset": "assets/meals/maintain/protein_cobb_salad.jpg",
            "desc":
                "Crispy grilled chicken cubes over fresh greens with hard-boiled eggs, cherry tomatoes, corn, cheese, and a creamy avocado-herb dressing.",
            "kcal": "540 kcal",
            "protein": "46g Protein",
            "carbs": "24g Carbs",
            "fat": "28g Fat",
          },
          {
            "name": "Chicken Rice Bowl",
            "asset": "assets/meals/maintain/chicken_rice_bowl.jpg",
            "desc":
                "Spiced shredded chicken over white rice with roasted sweet potato, street corn, pickled slaw, and bold seasonings.",
            "kcal": "620 kcal",
            "protein": "42g Protein",
            "carbs": "60g Carbs",
            "fat": "16g Fat",
          },
          {
            "name": "Chicken Fiesta Bowl",
            "asset": "assets/meals/maintain/chicken_fiesta_bowl.jpg",
            "desc":
                "Smoky spiced chicken with black beans, white rice, pickled red onions, crumbled feta, and a tangy avocado-lime sauce.",
            "kcal": "590 kcal",
            "protein": "44g Protein",
            "carbs": "55g Carbs",
            "fat": "18g Fat",
          },
        ],
      },
      {
        "section": "DINNER",
        "items": [
          {
            "name": "Salmon Feast",
            "asset": "assets/meals/maintain/salmon_feast.jpg",
            "desc":
                "Herb-crusted salmon fillet on a bed of creamy pea risotto — rich in omega-3s, protein, and complex carbs.",
            "kcal": "560 kcal",
            "protein": "46g Protein",
            "carbs": "40g Carbs",
            "fat": "22g Fat",
          },
          {
            "name": "Chimichurri Steak Bowl",
            "asset": "assets/meals/maintain/chimichurri_steak_bowl.jpg",
            "desc":
                "Grilled flank steak with roasted butternut squash, black beans, caramelized red onions, and vibrant chimichurri sauce.",
            "kcal": "640 kcal",
            "protein": "52g Protein",
            "carbs": "38g Carbs",
            "fat": "28g Fat",
          },
          {
            "name": "Beef & Sweet Potato",
            "asset": "assets/meals/maintain/beef_sweet_potato.jpg",
            "desc":
                "Glazed beef chunks with roasted sweet potato cubes, sweet green peas, and a rich golden sauce.",
            "kcal": "560 kcal",
            "protein": "40g Protein",
            "carbs": "46g Carbs",
            "fat": "20g Fat",
          },
        ],
      },
    ],
    "Muscle Gain": [
      {
        "section": "BREAKFAST",
        "items": [
          {
            "name": "Breakfast Plate",
            "asset": "assets/meals/muscle_gain/Breakfast_Plate.jpg",
            "desc":
                "Golden French toast with fluffy scrambled eggs, juicy sausages, and crispy bacon — high-calorie, protein-packed morning fuel.",
            "kcal": "780 kcal",
            "protein": "48g Protein",
            "carbs": "55g Carbs",
            "fat": "38g Fat",
          },
          {
            "name": "Yogurt Fruit Bowl",
            "asset": "assets/meals/muscle_gain/Yogurt_Fruit_Bowl.jpg",
            "desc":
                "Thick Greek yogurt with granola, banana, kiwi, raspberries, blueberries, strawberries, and honey — loaded with carbs and protein for recovery.",
            "kcal": "520 kcal",
            "protein": "22g Protein",
            "carbs": "72g Carbs",
            "fat": "14g Fat",
          },
          {
            "name": "Avocado Egg Salad",
            "asset": "assets/meals/muscle_gain/Avocado_Egg_Salad.jpg",
            "desc":
                "Chunky avocado with hard-boiled eggs, cherry tomatoes, red onion, fresh herbs, and chili flakes — healthy fats and complete protein.",
            "kcal": "480 kcal",
            "protein": "24g Protein",
            "carbs": "18g Carbs",
            "fat": "36g Fat",
          },
        ],
      },
      {
        "section": "LUNCH",
        "items": [
          {
            "name": "Chicken Rice Dish",
            "asset": "assets/meals/muscle_gain/Chicken_Rice_Dish.jpg",
            "desc":
                "Charred chicken slow-cooked with fragrant tomato-spiced rice in a cast iron pot — bold, high-protein, calorie-dense feast.",
            "kcal": "920 kcal",
            "protein": "68g Protein",
            "carbs": "80g Carbs",
            "fat": "26g Fat",
          },
          {
            "name": "Beef Rice Bowl",
            "asset": "assets/meals/muscle_gain/Beef_Rice_Bowl.jpg",
            "desc":
                "Crispy glazed beef strips with caramelized onions, red chilies, spring onion, and fluffy egg fried rice.",
            "kcal": "880 kcal",
            "protein": "62g Protein",
            "carbs": "78g Carbs",
            "fat": "28g Fat",
          },
          {
            "name": "Double Cheeseburger",
            "asset": "assets/meals/muscle_gain/Double_Cheeseburger.jpg",
            "desc":
                "Two smash-beef patties with double melted cheddar, caramelized onions, pickles, lettuce, tomato, and smoky house sauce on a brioche bun.",
            "kcal": "1050 kcal",
            "protein": "72g Protein",
            "carbs": "58g Carbs",
            "fat": "54g Fat",
          },
          {
            "name": "Beef Sweet Potato Bowl",
            "asset": "assets/meals/muscle_gain/Beef_Sweet_Potato_Bowl.jpg",
            "desc":
                "Seasoned ground beef with roasted sweet potato cubes, diced avocado, Greek yogurt drizzle, and fresh herbs.",
            "kcal": "750 kcal",
            "protein": "55g Protein",
            "carbs": "55g Carbs",
            "fat": "30g Fat",
          },
        ],
      },
      {
        "section": "DINNER",
        "items": [
          {
            "name": "Salmon Protein Bowl",
            "asset": "assets/meals/muscle_gain/Salmon_Protein_Bowl.jpg",
            "desc":
                "Seared salmon with steak bites, two sunny-side eggs, grilled asparagus, roasted zucchini, and fresh avocado — ultimate high-protein dinner.",
            "kcal": "980 kcal",
            "protein": "86g Protein",
            "carbs": "18g Carbs",
            "fat": "62g Fat",
          },
          {
            "name": "Shrimp Avocado Bowl",
            "asset": "assets/meals/muscle_gain/Shrimp_Avocado_Bowl.jpg",
            "desc":
                "Spiced grilled shrimp with roasted potatoes, steamed broccoli, a fried egg, and creamy avocado slices.",
            "kcal": "620 kcal",
            "protein": "48g Protein",
            "carbs": "40g Carbs",
            "fat": "28g Fat",
          },
          {
            "name": "Shrimp Pasta",
            "asset": "assets/meals/muscle_gain/Shrimp_Pasta.jpg",
            "desc":
                "Plump seasoned shrimp in a rich spiced butter-tomato sauce over perfectly cooked spaghetti.",
            "kcal": "820 kcal",
            "protein": "52g Protein",
            "carbs": "82g Carbs",
            "fat": "28g Fat",
          },
        ],
      },
    ],
  };

  double get _price => widget.goalLabel.contains("Weight Loss")
      ? 35.0
      : widget.goalLabel.contains("Maintain")
      ? 38.0
      : 48.0;

  // Normalise goalLabel for static lookup
  String get _staticKey {
    if (widget.goalLabel.contains("Weight Loss")) return "Weight Loss";
    if (widget.goalLabel.contains("Maintain")) return "Maintain";
    return "Muscle Gain";
  }

  @override
  Widget build(BuildContext context) {
    // Use Firestore data if loaded, otherwise fall back to static data
    final sections = _firestoreSections ?? _staticSections[_staticKey] ?? [];
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: widget.goalStyle.cardBg,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: const MealCartBadge(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.goalStyle.cardBg,
                          AppTheme.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      color: AppTheme.accent.withOpacity(0.6),
                    ),
                  ),
                  Positioned(
                    bottom: 28,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Powered by FitStation",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "YOUR MEAL\nINCLUDES",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppTheme.accent,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.goalCal,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loadingFirestore)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < sections.length) {
                    final s = sections[index];
                    return _SectionBlock(
                      title: s["section"] as String,
                      items: List<Map<String, dynamic>>.from(
                        s["items"] as List,
                      ),
                      accentColor: widget.goalStyle.iconColor,
                      headerColor: widget.goalStyle.cardBg,
                    );
                  }
                  return _AddToCartBtn(
                    goalLabel: widget.goalLabel,
                    price: _price,
                  );
                }, childCount: sections.length + 1),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section Block ─────────────────────────────────────────────────────────────
class _SectionBlock extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Color accentColor, headerColor;

  const _SectionBlock({
    required this.title,
    required this.items,
    required this.accentColor,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 28, 0, 16),
          child: Row(
            children: [
              Expanded(child: Divider(color: AppTheme.divider, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: headerColor,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.divider, thickness: 1)),
            ],
          ),
        ),
        ...items.map((item) => _MealCard(item: item, accentColor: accentColor)),
      ],
    );
  }
}

// ── Meal Card (goal plan screen) ──────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accentColor;

  const _MealCard({required this.item, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.card(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.asset(
              item["asset"] as String,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.accent.withOpacity(0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 48,
                      color: AppTheme.accent.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item["name"] as String,
                      style: AppTheme.body.copyWith(
                        fontSize: 13,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["name"] as String, style: AppTheme.subheading),
                const SizedBox(height: 6),
                Text(
                  item["desc"] as String,
                  style: AppTheme.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      "🔥 ${item["kcal"]}",
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.09),
                    ),
                    _chip(
                      "💪 ${item["protein"]}",
                      AppTheme.primaryLight,
                      AppTheme.primaryLight.withOpacity(0.09),
                    ),
                    _chip(
                      "🌾 ${item["carbs"]}",
                      const Color(0xFF7A6348),
                      const Color(0xFF7A6348).withOpacity(0.09),
                    ),
                    _chip(
                      "🥑 ${item["fat"]}",
                      AppTheme.accent,
                      AppTheme.accent.withOpacity(0.12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color textColor, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: textColor.withOpacity(0.18)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: textColor,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ── Add to Cart Button ────────────────────────────────────────────────────────
class _AddToCartBtn extends StatelessWidget {
  final String goalLabel;
  final double price;

  const _AddToCartBtn({required this.goalLabel, required this.price});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 48),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 17),
            minimumSize: const Size(double.infinity, 0),
          ),
          icon: const Icon(
            Icons.shopping_cart_rounded,
            color: Colors.white,
            size: 20,
          ),
          label: Text(
            "ADD TO CART  —  \$${price.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          onPressed: () {
            // Pick the matching logo asset for each goal
            final String planImage = goalLabel == "Weight Loss"
                ? "assets/weight_loss_logo.jpg"
                : goalLabel == "Muscle Gain"
                ? "assets/muscle_gain_logo.jpg"
                : "assets/maintain_weight_logo.jpg";

            MealCartManager().addItem(
              CartItem(
                id: "fitstation_$goalLabel",
                name: "FitStation – $goalLabel Plan",
                price: price,
                quantity: 1,
                icon: Icons.restaurant_menu_rounded,
                imageUrl: planImage,
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "$goalLabel plan added to cart!",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN MEAL PLAN EDITOR SCREEN
// Route: AdminMealPlanEditorScreen(planLabel: "Weight Loss Plan")
// Firestore path: meal_plans/{planKey}/sections/{sectionId}
//   Each section doc: { section: "BREAKFAST", order: 0,
//     items: [ { name, desc, kcal, protein, carbs, fat, asset } ] }
// ═══════════════════════════════════════════════════════════════════════════

class AdminMealPlanEditorScreen extends StatefulWidget {
  /// e.g. "Weight Loss Plan", "Maintain Weight Plan", "Muscle Gain Plan"
  final String planLabel;

  const AdminMealPlanEditorScreen({super.key, required this.planLabel});

  @override
  State<AdminMealPlanEditorScreen> createState() =>
      _AdminMealPlanEditorScreenState();
}

class _AdminMealPlanEditorScreenState extends State<AdminMealPlanEditorScreen> {
  // Working copy of sections: list of { section, order, items[] }
  List<Map<String, dynamic>> _sections = [];
  bool _loading = true;
  bool _saving = false;

  String get _planKey => _planFirestoreKey(widget.planLabel);

  // ── Full static seed — ALL meals, mirrors _MealDetailScreenState._staticSections
  // Used when Firestore has no data yet (first launch).
  static const Map<String, List<Map<String, dynamic>>> _seedSections = {
    "weight_loss": [
      {
        "section": "BREAKFAST",
        "order": 0,
        "items": [
          {
            "name": "Sunrise Fuel",
            "desc":
                "A balanced plate of eggs, avocado, vegetables, and chickpeas — rich in protein, fiber, and healthy fats to support energy and metabolism.",
            "kcal": "250 kcal",
            "protein": "22g Protein",
            "carbs": "28g Carbs",
            "fat": "32g Fat",
            "asset": "assets/meals/weight_loss/sunrise_fuel.jpg",
          },
          {
            "name": "Berry Power Bowl",
            "desc":
                "A creamy bowl of oats and chia topped with bananas, strawberries, blueberries, and walnuts for sustained energy and antioxidant support.",
            "kcal": "300 kcal",
            "protein": "14g Protein",
            "carbs": "51g Carbs",
            "fat": "16g Fat",
            "asset": "assets/meals/weight_loss/berry_bowl.jpg",
          },
          {
            "name": "Hummus Toast",
            "desc":
                "Whole grain toast with creamy hummus, roasted chickpeas, cherry tomatoes, arugula, and a light balsamic drizzle.",
            "kcal": "290 kcal",
            "protein": "17g Protein",
            "carbs": "45g Carbs",
            "fat": "14g Fat",
            "asset": "assets/meals/weight_loss/hummus_toast.jpg",
          },
        ],
      },
      {
        "section": "LUNCH",
        "order": 1,
        "items": [
          {
            "name": "Steak & Strength",
            "desc":
                "Grilled steak with mashed potatoes, roasted vegetables, and greens — a balanced, high-protein lunch.",
            "kcal": "650 kcal",
            "protein": "52g Protein",
            "carbs": "40g Carbs",
            "fat": "25g Fat",
            "asset": "assets/meals/weight_loss/steak_lunch.jpg",
          },
          {
            "name": "Grilled Salmon Plate",
            "desc":
                "Grilled salmon with roasted vegetables and lemon for a clean, high-protein meal rich in omega-3s.",
            "kcal": "500 kcal",
            "protein": "48g Protein",
            "carbs": "38g Carbs",
            "fat": "22g Fat",
            "asset": "assets/meals/weight_loss/salmon_plate.jpg",
          },
          {
            "name": "Grilled Chicken Plate",
            "desc":
                "Grilled chicken breast served with white rice and a fresh vegetable salad for a balanced, lean meal.",
            "kcal": "520 kcal",
            "protein": "44g Protein",
            "carbs": "45g Carbs",
            "fat": "15g Fat",
            "asset": "assets/meals/weight_loss/chicken_plate.jpg",
          },
        ],
      },
      {
        "section": "DINNER",
        "order": 2,
        "items": [
          {
            "name": "Caesar Wrap",
            "desc":
                "Grilled chicken, romaine lettuce, tortilla wrap, and Caesar dressing for a high-protein satisfying meal.",
            "kcal": "360 kcal",
            "protein": "32g Protein",
            "carbs": "35g Carbs",
            "fat": "34g Fat",
            "asset": "assets/meals/weight_loss/caesar_wrap.jpg",
          },
          {
            "name": "Tuna Beast",
            "desc":
                "Whole grain bread with tuna, lettuce, tomato, cucumber, and olives for a protein-rich meal.",
            "kcal": "290 kcal",
            "protein": "38g Protein",
            "carbs": "12g Carbs",
            "fat": "10g Fat",
            "asset": "assets/meals/weight_loss/tuna_beast.jpg",
          },
          {
            "name": "Stuffed Grape Leaves",
            "desc":
                "Grape leaves stuffed with rice, herbs, and light seasoning for a traditional, fiber-rich dinner.",
            "kcal": "300 kcal",
            "protein": "15g Protein",
            "carbs": "45g Carbs",
            "fat": "11g Fat",
            "asset": "assets/meals/weight_loss/grape_leaves.jpg",
          },
        ],
      },
    ],
    "maintain": [
      {
        "section": "BREAKFAST",
        "order": 0,
        "items": [
          {
            "name": "Steak & Egg Plate",
            "desc":
                "Juicy grilled steak slices with fluffy scrambled eggs, roasted cherry tomatoes, crispy potatoes, and fresh spinach.",
            "kcal": "520 kcal",
            "protein": "44g Protein",
            "carbs": "28g Carbs",
            "fat": "26g Fat",
            "asset": "assets/meals/maintain/steak_egg_plate.jpg",
          },
          {
            "name": "Protein Hash Bowl",
            "desc":
                "Scrambled eggs with seasoned ground meat, roasted red potatoes, melted cheddar, fresh herbs, and a side of house salsa.",
            "kcal": "480 kcal",
            "protein": "36g Protein",
            "carbs": "32g Carbs",
            "fat": "22g Fat",
            "asset": "assets/meals/maintain/protein_hash_bowl.jpg",
          },
        ],
      },
      {
        "section": "LUNCH",
        "order": 1,
        "items": [
          {
            "name": "Chicken Mandi",
            "desc":
                "Tender spiced chicken breast on a bed of fragrant saffron rice, topped with fresh cilantro and a creamy yogurt dip.",
            "kcal": "580 kcal",
            "protein": "48g Protein",
            "carbs": "52g Carbs",
            "fat": "14g Fat",
            "asset": "assets/meals/maintain/chicken_mandi.jpg",
          },
          {
            "name": "Protein Cobb Salad",
            "desc":
                "Crispy grilled chicken cubes over fresh greens with hard-boiled eggs, cherry tomatoes, corn, cheese, and a creamy avocado-herb dressing.",
            "kcal": "540 kcal",
            "protein": "46g Protein",
            "carbs": "24g Carbs",
            "fat": "28g Fat",
            "asset": "assets/meals/maintain/protein_cobb_salad.jpg",
          },
          {
            "name": "Chicken Rice Bowl",
            "desc":
                "Spiced shredded chicken over white rice with roasted sweet potato, street corn, pickled slaw, and bold seasonings.",
            "kcal": "620 kcal",
            "protein": "42g Protein",
            "carbs": "60g Carbs",
            "fat": "16g Fat",
            "asset": "assets/meals/maintain/chicken_rice_bowl.jpg",
          },
          {
            "name": "Chicken Fiesta Bowl",
            "desc":
                "Smoky spiced chicken with black beans, white rice, pickled red onions, crumbled feta, and a tangy avocado-lime sauce.",
            "kcal": "590 kcal",
            "protein": "44g Protein",
            "carbs": "55g Carbs",
            "fat": "18g Fat",
            "asset": "assets/meals/maintain/chicken_fiesta_bowl.jpg",
          },
        ],
      },
      {
        "section": "DINNER",
        "order": 2,
        "items": [
          {
            "name": "Salmon Feast",
            "desc":
                "Herb-crusted salmon fillet on a bed of creamy pea risotto — rich in omega-3s, protein, and complex carbs.",
            "kcal": "560 kcal",
            "protein": "46g Protein",
            "carbs": "40g Carbs",
            "fat": "22g Fat",
            "asset": "assets/meals/maintain/salmon_feast.jpg",
          },
          {
            "name": "Chimichurri Steak Bowl",
            "desc":
                "Grilled flank steak with roasted butternut squash, black beans, caramelized red onions, and vibrant chimichurri sauce.",
            "kcal": "640 kcal",
            "protein": "52g Protein",
            "carbs": "38g Carbs",
            "fat": "28g Fat",
            "asset": "assets/meals/maintain/chimichurri_steak_bowl.jpg",
          },
          {
            "name": "Beef & Sweet Potato",
            "desc":
                "Glazed beef chunks with roasted sweet potato cubes, sweet green peas, and a rich golden sauce.",
            "kcal": "560 kcal",
            "protein": "40g Protein",
            "carbs": "46g Carbs",
            "fat": "20g Fat",
            "asset": "assets/meals/maintain/beef_sweet_potato.jpg",
          },
        ],
      },
    ],
    "muscle_gain": [
      {
        "section": "BREAKFAST",
        "order": 0,
        "items": [
          {
            "name": "Breakfast Plate",
            "desc":
                "Golden French toast with fluffy scrambled eggs, juicy sausages, and crispy bacon — high-calorie, protein-packed morning fuel.",
            "kcal": "780 kcal",
            "protein": "48g Protein",
            "carbs": "55g Carbs",
            "fat": "38g Fat",
            "asset": "assets/meals/muscle_gain/Breakfast_Plate.jpg",
          },
          {
            "name": "Yogurt Fruit Bowl",
            "desc":
                "Thick Greek yogurt with granola, banana, kiwi, raspberries, blueberries, strawberries, and honey — loaded with carbs and protein for recovery.",
            "kcal": "520 kcal",
            "protein": "22g Protein",
            "carbs": "72g Carbs",
            "fat": "14g Fat",
            "asset": "assets/meals/muscle_gain/Yogurt_Fruit_Bowl.jpg",
          },
          {
            "name": "Avocado Egg Salad",
            "desc":
                "Chunky avocado with hard-boiled eggs, cherry tomatoes, red onion, fresh herbs, and chili flakes — healthy fats and complete protein.",
            "kcal": "480 kcal",
            "protein": "24g Protein",
            "carbs": "18g Carbs",
            "fat": "36g Fat",
            "asset": "assets/meals/muscle_gain/Avocado_Egg_Salad.jpg",
          },
        ],
      },
      {
        "section": "LUNCH",
        "order": 1,
        "items": [
          {
            "name": "Chicken Rice Dish",
            "desc":
                "Charred chicken slow-cooked with fragrant tomato-spiced rice in a cast iron pot — bold, high-protein, calorie-dense feast.",
            "kcal": "920 kcal",
            "protein": "68g Protein",
            "carbs": "80g Carbs",
            "fat": "26g Fat",
            "asset": "assets/meals/muscle_gain/Chicken_Rice_Dish.jpg",
          },
          {
            "name": "Beef Rice Bowl",
            "desc":
                "Crispy glazed beef strips with caramelized onions, red chilies, spring onion, and fluffy egg fried rice.",
            "kcal": "880 kcal",
            "protein": "62g Protein",
            "carbs": "78g Carbs",
            "fat": "28g Fat",
            "asset": "assets/meals/muscle_gain/Beef_Rice_Bowl.jpg",
          },
          {
            "name": "Double Cheeseburger",
            "desc":
                "Two smash-beef patties with double melted cheddar, caramelized onions, pickles, lettuce, tomato, and smoky house sauce on a brioche bun.",
            "kcal": "1050 kcal",
            "protein": "72g Protein",
            "carbs": "58g Carbs",
            "fat": "54g Fat",
            "asset": "assets/meals/muscle_gain/Double_Cheeseburger.jpg",
          },
          {
            "name": "Beef Sweet Potato Bowl",
            "desc":
                "Seasoned ground beef with roasted sweet potato cubes, diced avocado, Greek yogurt drizzle, and fresh herbs.",
            "kcal": "750 kcal",
            "protein": "55g Protein",
            "carbs": "55g Carbs",
            "fat": "30g Fat",
            "asset": "assets/meals/muscle_gain/Beef_Sweet_Potato_Bowl.jpg",
          },
        ],
      },
      {
        "section": "DINNER",
        "order": 2,
        "items": [
          {
            "name": "Salmon Protein Bowl",
            "desc":
                "Seared salmon with steak bites, two sunny-side eggs, grilled asparagus, roasted zucchini, and fresh avocado — ultimate high-protein dinner.",
            "kcal": "980 kcal",
            "protein": "86g Protein",
            "carbs": "18g Carbs",
            "fat": "62g Fat",
            "asset": "assets/meals/muscle_gain/Salmon_Protein_Bowl.jpg",
          },
          {
            "name": "Shrimp Avocado Bowl",
            "desc":
                "Spiced grilled shrimp with roasted potatoes, steamed broccoli, a fried egg, and creamy avocado slices.",
            "kcal": "620 kcal",
            "protein": "48g Protein",
            "carbs": "40g Carbs",
            "fat": "28g Fat",
            "asset": "assets/meals/muscle_gain/Shrimp_Avocado_Bowl.jpg",
          },
          {
            "name": "Shrimp Pasta",
            "desc":
                "Plump seasoned shrimp in a rich spiced butter-tomato sauce over perfectly cooked spaghetti.",
            "kcal": "820 kcal",
            "protein": "52g Protein",
            "carbs": "82g Carbs",
            "fat": "28g Fat",
            "asset": "assets/meals/muscle_gain/Shrimp_Pasta.jpg",
          },
        ],
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  // ── Load from Firestore; if empty, seed from full static data ─────────────
  Future<void> _loadSections() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('meal_plans')
          .doc(_planKey)
          .collection('sections')
          .orderBy('order')
          .get();

      List<Map<String, dynamic>> loaded;
      if (snap.docs.isNotEmpty) {
        // Load from Firestore
        loaded = snap.docs.map((doc) {
          final d = Map<String, dynamic>.from(doc.data());
          d['_firestoreId'] = doc.id;
          final rawItems = d['items'] as List<dynamic>? ?? [];
          d['items'] = rawItems
              .map((i) => Map<String, dynamic>.from(i as Map))
              .toList();
          return d;
        }).toList();
      } else {
        // Seed from complete static data — deep copy so it's mutable
        loaded = (_seedSections[_planKey] ?? []).map((s) {
          return {
            'section': s['section'],
            'order': s['order'],
            'items': (s['items'] as List)
                .map((i) => Map<String, dynamic>.from(i))
                .toList(),
          };
        }).toList();
      }

      if (mounted)
        setState(() {
          _sections = loaded;
          _loading = false;
        });
    } catch (e) {
      // On error still show seed data so UI is never blank
      final seed = (_seedSections[_planKey] ?? []).map((s) {
        return {
          'section': s['section'],
          'order': s['order'],
          'items': (s['items'] as List)
              .map((i) => Map<String, dynamic>.from(i))
              .toList(),
        };
      }).toList();
      if (mounted)
        setState(() {
          _sections = seed;
          _loading = false;
        });
    }
  }

  // ── Save all sections to Firestore ───────────────────────────────────────
  Future<void> _saveToFirestore() async {
    setState(() => _saving = true);
    try {
      final col = FirebaseFirestore.instance
          .collection('meal_plans')
          .doc(_planKey)
          .collection('sections');

      // Delete existing docs
      final existing = await col.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Write new docs
      final writeBatch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < _sections.length; i++) {
        final s = _sections[i];
        final docRef = col.doc();
        writeBatch.set(docRef, {
          'section': s['section'],
          'order': i,
          'items': (s['items'] as List<Map<String, dynamic>>).map((item) {
            return {
              'name': item['name'] ?? '',
              'desc': item['desc'] ?? '',
              'kcal': item['kcal'] ?? '',
              'protein': item['protein'] ?? '',
              'carbs': item['carbs'] ?? '',
              'fat': item['fat'] ?? '',
              'asset': item['asset'] ?? '',
            };
          }).toList(),
        });
      }
      await writeBatch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'Plan saved & live for customers!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  // ── Show Add / Edit meal dialog ──────────────────────────────────────────
  Future<void> _showMealDialog({
    required int sectionIndex,
    int? mealIndex, // null = adding new
  }) async {
    final existing = mealIndex != null
        ? Map<String, dynamic>.from(
            (_sections[sectionIndex]['items'] as List)[mealIndex],
          )
        : <String, dynamic>{};

    final nameCtrl = TextEditingController(text: existing['name'] ?? '');
    final descCtrl = TextEditingController(text: existing['desc'] ?? '');
    final kcalCtrl = TextEditingController(text: existing['kcal'] ?? '');
    final proteinCtrl = TextEditingController(text: existing['protein'] ?? '');
    final carbsCtrl = TextEditingController(text: existing['carbs'] ?? '');
    final fatCtrl = TextEditingController(text: existing['fat'] ?? '');
    final assetCtrl = TextEditingController(text: existing['asset'] ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mealIndex == null ? 'Add Meal' : 'Edit Meal',
                    style: AppTheme.subheading.copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _dialogField(
                nameCtrl,
                'Meal Name *',
                Icons.label_outline_rounded,
              ),
              const SizedBox(height: 12),
              _dialogField(
                descCtrl,
                'Description *',
                Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dialogField(
                      kcalCtrl,
                      'Calories',
                      Icons.local_fire_department_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dialogField(
                      proteinCtrl,
                      'Protein',
                      Icons.fitness_center_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dialogField(
                      carbsCtrl,
                      'Carbs',
                      Icons.grain_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dialogField(fatCtrl, 'Fat', Icons.opacity_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _dialogField(
                assetCtrl,
                'Asset path (optional)',
                Icons.image_outlined,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty ||
                            descCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Name and description are required',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx, {
                          'name': nameCtrl.text.trim(),
                          'desc': descCtrl.text.trim(),
                          'kcal': kcalCtrl.text.trim(),
                          'protein': proteinCtrl.text.trim(),
                          'carbs': carbsCtrl.text.trim(),
                          'fat': fatCtrl.text.trim(),
                          'asset': assetCtrl.text.trim(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        mealIndex == null ? 'Add Meal' : 'Save Changes',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        final items =
            _sections[sectionIndex]['items'] as List<Map<String, dynamic>>;
        if (mealIndex == null) {
          items.add(result);
        } else {
          items[mealIndex] = result;
        }
      });
    }
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: AppTheme.dark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppTheme.muted,
        ),
        prefixIcon: Icon(icon, color: AppTheme.muted, size: 18),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  // ── Remove meal with confirm ─────────────────────────────────────────────
  Future<void> _removeMeal(int sectionIndex, int mealIndex) async {
    final meal =
        (_sections[sectionIndex]['items']
            as List<Map<String, dynamic>>)[mealIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Meal',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "${meal['name']}" from this plan?',
          style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins', color: AppTheme.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
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
    if (confirmed == true && mounted) {
      setState(() {
        (_sections[sectionIndex]['items'] as List<Map<String, dynamic>>)
            .removeAt(mealIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.planLabel,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.dark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.dark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: _saveToFirestore,
                  icon: const Icon(
                    Icons.cloud_upload_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  label: const Text(
                    'Save Plan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : _sections.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 64,
                    color: AppTheme.divider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sections yet',
                    style: AppTheme.subheading.copyWith(fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _sections.length,
              itemBuilder: (ctx, sIdx) {
                final section = _sections[sIdx];
                final sectionName = section['section'] as String;
                final items = section['items'] as List<Map<String, dynamic>>;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section header ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              sectionName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Add meal to this section
                          GestureDetector(
                            onTap: () => _showMealDialog(sectionIndex: sIdx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.accent.withOpacity(0.35),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: AppTheme.primary,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add Meal',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Meal cards ────────────────────────────────────
                    if (items.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.divider,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppTheme.muted.withOpacity(0.5),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No meals — tap Add Meal',
                              style: AppTheme.body.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      ...items.asMap().entries.map((entry) {
                        final mIdx = entry.key;
                        final meal = entry.value;
                        return _AdminMealTile(
                          meal: meal,
                          onEdit: () => _showMealDialog(
                            sectionIndex: sIdx,
                            mealIndex: mIdx,
                          ),
                          onRemove: () => _removeMeal(sIdx, mIdx),
                        );
                      }),
                  ],
                );
              },
            ),
      // ── Floating save reminder ───────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _saveToFirestore,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.cloud_upload_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
            label: Text(
              _saving ? 'Saving...' : 'Save Plan & Push to Customers',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Admin meal tile widget ────────────────────────────────────────────────────
class _AdminMealTile extends StatelessWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _AdminMealTile({
    required this.meal,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasAsset = (meal['asset'] as String?)?.isNotEmpty ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Meal image thumbnail ─────────────────────────────────────────
          if (hasAsset)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.asset(
                  meal['asset'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.accent.withOpacity(0.08),
                    child: const Center(
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        size: 40,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 36,
                  color: AppTheme.accent,
                ),
              ),
            ),

          // ── Meal info ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['name'] as String? ?? '',
                  style: AppTheme.subheading.copyWith(fontSize: 15),
                ),
                if ((meal['desc'] as String?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    meal['desc'] as String,
                    style: AppTheme.body.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                // Macro chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if ((meal['kcal'] as String?)?.isNotEmpty ?? false)
                      _chip('🔥 ${meal['kcal']}'),
                    if ((meal['protein'] as String?)?.isNotEmpty ?? false)
                      _chip('💪 ${meal['protein']}'),
                    if ((meal['carbs'] as String?)?.isNotEmpty ?? false)
                      _chip('🌾 ${meal['carbs']}'),
                    if ((meal['fat'] as String?)?.isNotEmpty ?? false)
                      _chip('🥑 ${meal['fat']}'),
                  ],
                ),
                const SizedBox(height: 14),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRemove,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade600,
                          size: 16,
                        ),
                        label: Text(
                          'Remove',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppTheme.accent.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: AppTheme.primary,
      ),
    ),
  );
}
