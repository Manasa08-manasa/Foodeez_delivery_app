import 'package:flutter/material.dart';

/// Which third-party KYC/verification API a document number is checked
/// against — see docs/BACKEND_INTEGRATION.md §3 for the full mapping.
enum VerificationProvider { apisetu, sandbox, verifico, razorpay }

String verificationProviderLabel(VerificationProvider p) => switch (p) {
      VerificationProvider.apisetu => 'APISetu',
      VerificationProvider.sandbox => 'Sandbox',
      VerificationProvider.verifico => 'Verifico',
      VerificationProvider.razorpay => 'Razorpay',
    };

enum DocumentStatus { unverified, pending, verified, rejected }

/// A single regulatory/KYC document that gates account activation.
class VerifiableDocument {
  final String id;
  final IconData icon;
  final String label;
  final String numberHint;
  final VerificationProvider? provider;
  final bool requiresNumber;

  const VerifiableDocument({
    required this.id,
    required this.icon,
    required this.label,
    this.numberHint = '',
    this.provider,
    this.requiresNumber = true,
  });
}

/// Overall rider-account activation state. Verifying every individual
/// document does NOT auto-activate the account — an admin/fleet-manager
/// still does a final review (see docs/BACKEND_INTEGRATION.md §3).
enum AccountStatus { pendingReview, active, rejected }

enum PaymentMethod { cod, upi, card }

String paymentMethodLabel(PaymentMethod m) => switch (m) {
      PaymentMethod.upi => 'UPI',
      PaymentMethod.card => 'Card',
      PaymentMethod.cod => 'Cash',
    };

IconData paymentMethodIcon(PaymentMethod m) => m == PaymentMethod.card ? Icons.credit_card_outlined : Icons.qr_code_scanner_outlined;

/// The 4 sub-stages of a live delivery: en route to the restaurant, arrived
/// and collecting, en route to the customer, arrived and handing over.
enum DeliveryStage { toPickup, atPickup, toDrop, atDrop }

class OrderLine {
  final int qty;
  final String name;
  const OrderLine({required this.qty, required this.name});
}

/// The active delivery request — accepted from the incoming-request alert
/// and driven through [DeliveryStage] on the Trip screen.
class DeliveryRequest {
  final String orderId;
  final String restaurantName;
  final String restaurantAddress;
  final String customerName;
  final String customerAddress;
  final double totalKm;
  final int totalMins;
  final int payout;
  final int orderTotal;
  final PaymentMethod paymentMethod;
  final List<OrderLine> items;

  const DeliveryRequest({
    required this.orderId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerName,
    required this.customerAddress,
    required this.totalKm,
    required this.totalMins,
    required this.payout,
    required this.orderTotal,
    required this.paymentMethod,
    required this.items,
  });
}

class RecentTrip {
  final IconData icon;
  final String restaurant;
  final String when;
  final double km;
  final int pay;
  const RecentTrip({required this.icon, required this.restaurant, required this.when, required this.km, required this.pay});
}

class TripHistoryEntry {
  final String id;
  final String from;
  final String to;
  final String when;
  final double km;
  final int? pay; // null for cancelled trips
  final double? stars; // null for cancelled trips
  final bool delivered;
  const TripHistoryEntry({required this.id, required this.from, required this.to, required this.when, required this.km, required this.pay, required this.stars, required this.delivered});
}

class RiderReview {
  final String initials;
  final String name;
  final int stars;
  final String when;
  final String text;
  const RiderReview({required this.initials, required this.name, required this.stars, required this.when, required this.text});
}

class RiderPref {
  final String key;
  final IconData icon;
  final String label;
  const RiderPref({required this.key, required this.icon, required this.label});
}

class EarningsBreakdownRow {
  final IconData icon;
  final String label;
  final String sub;
  final String amount;
  final Color amountColor;
  final Color tint;
  const EarningsBreakdownRow({required this.icon, required this.label, required this.sub, required this.amount, required this.amountColor, required this.tint});
}

class EarningsPeriodData {
  final String subtitle;
  final String total;
  final String trips;
  final String km;
  final String hrs;
  final List<EarningsBreakdownRow> breakdown;
  const EarningsPeriodData({required this.subtitle, required this.total, required this.trips, required this.km, required this.hrs, required this.breakdown});
}

/// A time-boxed streak bonus campaign. Fleet ops/admins turn these on for a
/// rider or zone from the backend dashboard — riders never create or toggle
/// these themselves, so the Home screen only shows the card when one exists.
class IncentiveOffer {
  final int bonusAmount;
  final int targetTrips;
  final int currentTrips;
  final String deadlineLabel; // e.g. "before 4 PM"

  const IncentiveOffer({required this.bonusAmount, required this.targetTrips, required this.currentTrips, required this.deadlineLabel});

  int get remainingTrips => (targetTrips - currentTrips).clamp(0, targetTrips);
  double get progress => targetTrips == 0 ? 0 : (currentTrips / targetTrips).clamp(0, 1);
}
