import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../core/theme.dart';

const riderName = 'Rahul Kumar';
const riderInitials = 'RK';
const riderId = 'FZR-40271';

/// The order a rider is currently working, or accepts from the incoming
/// request alert. Static demo data — a real app would receive this from the
/// dispatch/order service over push/websocket.
const DeliveryRequest demoRequest = DeliveryRequest(
  orderId: 'FZ8241',
  restaurantName: 'Paradise Biryani',
  restaurantAddress: 'Banjara Hills, Road 12 · Outlet #402',
  customerName: 'Ananya Reddy',
  customerAddress: 'Jubilee Hills, Road 36 · Flat 4B',
  totalKm: 4.4,
  totalMins: 15,
  payout: 78,
  orderTotal: 560,
  paymentMethod: PaymentMethod.cod,
  items: [
    OrderLine(qty: 1, name: 'Chicken Dum Biryani (Family)'),
    OrderLine(qty: 2, name: 'Mirchi ka Salan'),
    OrderLine(qty: 1, name: 'Double ka Meetha'),
  ],
);

/// A fleet-manager-activated streak bonus. In production this comes from the
/// ops dashboard; null (no campaign running) is the common case.
const IncentiveOffer demoIncentive = IncentiveOffer(bonusAmount: 120, targetTrips: 5, currentTrips: 3, deadlineLabel: 'before 4 PM');

const basePay = 62;
const tipPay = 16;

const List<RecentTrip> recentTrips = [
  RecentTrip(icon: Icons.rice_bowl_outlined, restaurant: 'Paradise Biryani', when: '2:40 PM', km: 3.2, pay: 78),
  RecentTrip(icon: Icons.local_pizza_outlined, restaurant: 'La Pinoz Pizza', when: '1:15 PM', km: 2.1, pay: 62),
  RecentTrip(icon: Icons.lunch_dining_outlined, restaurant: 'Burger Singh', when: '12:30 PM', km: 4.0, pay: 85),
];

const todayEarn = 1240;
const todayTrips = 12;
const onlineTime = '6h 30m';
const todayKm = 46;

const List<TripHistoryEntry> tripHistory = [
  TripHistoryEntry(id: 'FZ8231', from: 'Paradise Biryani, Banjara Hills', to: 'Jubilee Hills, Rd 36', when: '2:40 PM', km: 3.2, pay: 78, stars: 5.0, delivered: true),
  TripHistoryEntry(id: 'FZ8219', from: 'La Pinoz Pizza, Madhapur', to: 'Hitech City, Cyber Towers', when: '1:15 PM', km: 2.1, pay: 62, stars: 5.0, delivered: true),
  TripHistoryEntry(id: 'FZ8204', from: 'Burger Singh, Kondapur', to: 'Gachibowli, DLF', when: '12:30 PM', km: 4.0, pay: 85, stars: 4.0, delivered: true),
  TripHistoryEntry(id: 'FZ8188', from: 'Subway, Jubilee Hills', to: 'Film Nagar, Rd 2', when: '11:50 AM', km: 1.6, pay: 54, stars: 5.0, delivered: true),
  TripHistoryEntry(id: 'FZ8170', from: 'Chai Point, Banjara Hills', to: 'Somajiguda', when: '11:10 AM', km: 2.8, pay: null, stars: null, delivered: false),
];

const List<({int star, int pct})> ratingBars = [
  (star: 5, pct: 88),
  (star: 4, pct: 9),
  (star: 3, pct: 2),
  (star: 2, pct: 1),
  (star: 1, pct: 0),
];

const List<RiderReview> riderReviews = [
  RiderReview(initials: 'AR', name: 'Ananya R.', stars: 5, when: '2d', text: 'Super quick and polite. Food was still hot!'),
  RiderReview(initials: 'VK', name: 'Vikram K.', stars: 5, when: '4d', text: 'Called before arriving and found the flat easily. Great service.'),
  RiderReview(initials: 'SM', name: 'Sneha M.', stars: 4, when: '1w', text: 'Good delivery, just a couple minutes late during the rain.'),
];

/// The rider's verifiable documents. Numbers here are the seed values for an
/// already-established demo account (all pre-verified); a fresh signup
/// starts every one of these at [DocumentStatus.unverified] instead — see
/// `AppState.startNewApplication`.
const List<VerifiableDocument> verifiableDocuments = [
  VerifiableDocument(id: 'dl', icon: Icons.badge_outlined, label: 'Driving licence', numberHint: 'DL number', provider: VerificationProvider.sandbox),
  VerifiableDocument(id: 'rc', icon: Icons.description_outlined, label: 'Vehicle RC', numberHint: 'RC number', provider: VerificationProvider.apisetu),
  VerifiableDocument(id: 'insurance', icon: Icons.shield_outlined, label: 'Insurance', numberHint: 'Policy number', provider: VerificationProvider.verifico),
  VerifiableDocument(id: 'bank', icon: Icons.account_balance_outlined, label: 'Bank account (for payouts)', numberHint: 'Account number + IFSC', provider: VerificationProvider.razorpay),
];

/// Seed document numbers for the established demo account (login flow).
const Map<String, String> seedDocumentNumbers = {
  'dl': 'TS0920230012345',
  'rc': 'TS09EA1234',
  'insurance': 'POL-88213409',
  'bank': '50100234567890 · HDFC0000123',
};

const List<RiderPref> riderPrefDefs = [
  RiderPref(key: 'longTrips', icon: Icons.route_outlined, label: 'Accept long trips (>6 km)'),
  RiderPref(key: 'autoAccept', icon: Icons.bolt_outlined, label: 'Auto-accept nearby orders'),
  RiderPref(key: 'cashOnly', icon: Icons.payments_outlined, label: 'Prefer cash orders'),
];

const List<String> supportFaqs = [
  'How are my earnings calculated?',
  'What if the customer is unavailable?',
  'Reporting a wrong or missing item',
  'Updating my bank & payout details',
];

const Map<String, EarningsPeriodData> earningsByPeriod = {
  'today': EarningsPeriodData(
    subtitle: 'Earned today',
    total: '1,240',
    trips: '12',
    km: '46',
    hrs: '6.5',
    breakdown: [
      EarningsBreakdownRow(icon: Icons.moped_outlined, label: 'Trip payouts', sub: '12 deliveries', amount: '₹940', amountColor: AppColors.ink, tint: AppColors.plumTint),
      EarningsBreakdownRow(icon: Icons.savings_outlined, label: 'Customer tips', sub: '5 tips', amount: '+₹180', amountColor: AppColors.green, tint: AppColors.greenPaleBg),
      EarningsBreakdownRow(icon: Icons.track_changes_outlined, label: 'Streak bonus', sub: '3 unlocked', amount: '+₹120', amountColor: AppColors.green, tint: AppColors.goldTint),
      EarningsBreakdownRow(icon: Icons.bolt_outlined, label: 'Surge (peak)', sub: '1–3 PM', amount: '+₹0', amountColor: AppColors.bodyGrey, tint: Color(0xFFEDE7F1)),
    ],
  ),
  'week': EarningsPeriodData(
    subtitle: 'Earned this week',
    total: '7,860',
    trips: '74',
    km: '312',
    hrs: '41',
    breakdown: [
      EarningsBreakdownRow(icon: Icons.moped_outlined, label: 'Trip payouts', sub: '74 deliveries', amount: '₹5,980', amountColor: AppColors.ink, tint: AppColors.plumTint),
      EarningsBreakdownRow(icon: Icons.savings_outlined, label: 'Customer tips', sub: '31 tips', amount: '+₹1,110', amountColor: AppColors.green, tint: AppColors.greenPaleBg),
      EarningsBreakdownRow(icon: Icons.track_changes_outlined, label: 'Streak bonuses', sub: '6 days', amount: '+₹620', amountColor: AppColors.green, tint: AppColors.goldTint),
      EarningsBreakdownRow(icon: Icons.bolt_outlined, label: 'Surge (peak)', sub: 'weekend', amount: '+₹150', amountColor: AppColors.green, tint: Color(0xFFEDE7F1)),
    ],
  ),
  'month': EarningsPeriodData(
    subtitle: 'Earned this month',
    total: '31,420',
    trips: '298',
    km: '1,284',
    hrs: '168',
    breakdown: [
      EarningsBreakdownRow(icon: Icons.moped_outlined, label: 'Trip payouts', sub: '298 deliveries', amount: '₹24,100', amountColor: AppColors.ink, tint: AppColors.plumTint),
      EarningsBreakdownRow(icon: Icons.savings_outlined, label: 'Customer tips', sub: '128 tips', amount: '+₹4,520', amountColor: AppColors.green, tint: AppColors.greenPaleBg),
      EarningsBreakdownRow(icon: Icons.track_changes_outlined, label: 'Streak bonuses', sub: '22 days', amount: '+₹2,300', amountColor: AppColors.green, tint: AppColors.goldTint),
      EarningsBreakdownRow(icon: Icons.bolt_outlined, label: 'Surge (peak)', sub: 'festival week', amount: '+₹500', amountColor: AppColors.green, tint: Color(0xFFEDE7F1)),
    ],
  ),
};
