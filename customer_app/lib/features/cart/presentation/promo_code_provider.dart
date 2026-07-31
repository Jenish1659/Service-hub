import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromoCode {
  final String code;
  final String description;
  final double discountPercent; // 0 if flat amount
  final int flatDiscount;      // 0 if percent
  final int maxDiscount;       // Max discount for percentage
  final int minOrderValue;

  const PromoCode({
    required this.code,
    required this.description,
    this.discountPercent = 0,
    this.flatDiscount = 0,
    this.maxDiscount = 0,
    this.minOrderValue = 0,
  });

  int calculateDiscount(int subtotal) {
    if (subtotal < minOrderValue) return 0;
    if (flatDiscount > 0) {
      return flatDiscount;
    } else if (discountPercent > 0) {
      int calculated = ((subtotal * discountPercent) / 100).round();
      if (maxDiscount > 0 && calculated > maxDiscount) {
        return maxDiscount;
      }
      return calculated;
    }
    return 0;
  }
}

class PromoResult {
  final bool isSuccess;
  final String message;
  final int discountAmount;
  final PromoCode? promoCode;

  PromoResult({
    required this.isSuccess,
    required this.message,
    this.discountAmount = 0,
    this.promoCode,
  });
}

class PromoState {
  final PromoCode? activeCode;
  final int discountAmount;

  const PromoState({this.activeCode, this.discountAmount = 0});

  PromoState copyWith({PromoCode? activeCode, int? discountAmount}) {
    return PromoState(
      activeCode: activeCode,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}

const List<PromoCode> availablePromoCodes = [
  PromoCode(
    code: 'WELCOME50',
    description: 'Flat ₹50 OFF on orders above ₹199',
    flatDiscount: 50,
    minOrderValue: 199,
  ),
  PromoCode(
    code: 'SERVICEHUB20',
    description: '20% OFF up to ₹150 on orders above ₹299',
    discountPercent: 20,
    maxDiscount: 150,
    minOrderValue: 299,
  ),
  PromoCode(
    code: 'FIRST100',
    description: 'Flat ₹100 OFF on orders above ₹399',
    flatDiscount: 100,
    minOrderValue: 399,
  ),
  PromoCode(
    code: 'SUPER75',
    description: 'Flat ₹75 OFF on orders above ₹249',
    flatDiscount: 75,
    minOrderValue: 249,
  ),
];

class PromoNotifier extends StateNotifier<PromoState> {
  PromoNotifier() : super(const PromoState());

  String _getUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? 'guest_user';
  }

  Future<PromoResult> applyPromoCode(String codeInput, int subtotal) async {
    final code = codeInput.trim().toUpperCase();
    if (code.isEmpty) {
      return PromoResult(
        isSuccess: false,
        message: 'Please enter a promo code.',
      );
    }

    // 1. Find matching code definition
    final promo = availablePromoCodes.firstWhere(
      (p) => p.code == code,
      orElse: () => const PromoCode(code: '', description: ''),
    );

    if (promo.code.isEmpty) {
      return PromoResult(
        isSuccess: false,
        message: 'Invalid promo code. Please check and try a different code.',
      );
    }

    // 2. Check if already used by this user account
    final userId = _getUserId();
    Box box;
    if (Hive.isBoxOpen('used_promo_codes')) {
      box = Hive.box('used_promo_codes');
    } else {
      box = await Hive.openBox('used_promo_codes');
    }

    final key = '${userId}_$code';
    if (box.get(key, defaultValue: false) == true) {
      return PromoResult(
        isSuccess: false,
        message: 'This promo code "$code" has already been redeemed on your account. Please use a different code.',
      );
    }

    // 3. Validate Minimum Order Value
    if (subtotal < promo.minOrderValue) {
      return PromoResult(
        isSuccess: false,
        message: 'Minimum order value for "$code" is ₹${promo.minOrderValue}. Add items worth ₹${promo.minOrderValue - subtotal} more.',
      );
    }

    // 4. Calculate Discount
    final discount = promo.calculateDiscount(subtotal);
    state = PromoState(activeCode: promo, discountAmount: discount);

    return PromoResult(
      isSuccess: true,
      message: 'Promo Code "$code" applied! Saved ₹$discount',
      discountAmount: discount,
      promoCode: promo,
    );
  }

  Future<void> markActiveCodeAsUsed() async {
    if (state.activeCode == null) return;
    final userId = _getUserId();
    final code = state.activeCode!.code;
    Box box;
    if (Hive.isBoxOpen('used_promo_codes')) {
      box = Hive.box('used_promo_codes');
    } else {
      box = await Hive.openBox('used_promo_codes');
    }

    final key = '${userId}_$code';
    await box.put(key, true);

    // Reset applied promo state for next cart
    state = const PromoState();
  }

  void removePromoCode() {
    state = const PromoState();
  }
}

final promoProvider = StateNotifierProvider<PromoNotifier, PromoState>((ref) {
  return PromoNotifier();
});
