/// ==========================================================================
/// subscription_service.dart — Subscription & Monetization
/// ==========================================================================
/// Manages user subscription state and feature gating.
/// 
/// Core responsibilities:
/// 1. Track current subscription tier (Free vs Premium).
/// 2. Provide a single source of truth for feature access level.
/// 3. Standardized purchase and restore flows (integrated with RevenueCat).
/// ==========================================================================

import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/user_model.dart';
import 'database_service.dart';

/// Enum defining specific premium features for granular gating.
enum Feature {
  aiInsights,
  advancedReports,
  environmentalNudges,
  unlimitedSync,
}

class SubscriptionService {
  final DatabaseService _db;
  
  SubscriptionService({DatabaseService? db}) 
      : _db = db ?? DatabaseService();

  // ══════════════════════════════════════════════════════════════════════════
  // ── 1. Initialization ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Initializes the RevenueCat SDK and sets the user identity.
  Future<void> initialize(String userId) async {
    // TODO: Configure with your RevenueCat public API key
    // await Purchases.configure(PurchasesConfiguration("YOUR_API_KEY")
    //   ..appUserId = userId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── 2. Feature Gating ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns true if the given [user] has access to a specific [feature].
  bool canAccess(UserModel user, Feature feature) {
    if (user.subscription == SubscriptionTier.premium) return true;

    // Optional: Add logic for 'freemium' limited usage here
    // e.g. return true for 1 report per month for free users.
    
    switch (feature) {
      case Feature.aiInsights:
      case Feature.advancedReports:
        return false; // Premium only
      case Feature.environmentalNudges:
      case Feature.unlimitedSync:
        return true; // Available to all for now
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── 3. Purchase Logic ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Refreshes the subscription status from RevenueCat and syncs to Firestore.
  /// 
  /// Returns the updated [SubscriptionTier].
  Future<SubscriptionTier> syncSubscriptionStatus(String userId) async {
    try {
      // Fetch status from RevenueCat
      // CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      // bool isPremium = customerInfo.entitlements.active.containsKey('premium');

      // Mock update to Firestore for demo
      final isPremium = false; // logic would go here
      final tier = isPremium ? SubscriptionTier.premium : SubscriptionTier.free;

      // Update local and remote DB if status changed
      // This ensures Firestore stays the source of truth for security rules.
      await _db.updateUserSubscription(userId, tier);
      
      return tier;
    } catch (e) {
      return SubscriptionTier.free;
    }
  }

  /// Initiates a purchase for the Premium subscription.
  Future<bool> purchasePremium() async {
    try {
      // Offerings offerings = await Purchases.getOfferings();
      // if (offerings.current != null && offerings.current!.premium != null) {
      //   await Purchases.purchasePackage(offerings.current!.premium!);
      //   return true;
      // }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Restores previous purchases.
  Future<void> restorePurchases() async {
    // await Purchases.restorePurchases();
  }
}
