/// Subscription product identifiers. These MUST exactly match the
/// subscription products configured in both Google Play Console
/// (Monetize > Subscriptions) and App Store Connect (Monetization >
/// Subscriptions) — this app doesn't create or manage products, it only
/// references IDs that already exist there.
///
/// Each should be its own separate subscription product with exactly one
/// base plan (Android) / one subscription duration (iOS) — not multiple
/// offers on a single product — so [PurchaseService.buy] doesn't need to
/// pick between offers.
class PurchaseProductIds {
  PurchaseProductIds._();

  static const String monthly = 'managely_premium_monthly';
  static const String annual = 'managely_premium_annual';

  /// Organization seat bands (see routes/purchases.js's ORG_SEAT_BANDS) —
  /// purchased by an org's owner, not an individual. Mobile app stores
  /// don't support per-seat dynamic pricing on subscriptions, so this is a
  /// small fixed catalog of seat bands instead of true "price × N users".
  static const String org10Seats = 'managely_professional_10';
  static const String org25Seats = 'managely_professional_25';
  static const String org50Seats = 'managely_professional_50';

  static const Map<String, int> orgSeatBands = {
    org10Seats: 10,
    org25Seats: 25,
    org50Seats: 50,
  };

  static const Set<String> individual = {monthly, annual};
  static const Set<String> all = {monthly, annual, org10Seats, org25Seats, org50Seats};
}
