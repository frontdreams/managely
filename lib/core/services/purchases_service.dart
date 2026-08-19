import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Configures the RevenueCat SDK. Called once from `main()`, before
/// `runApp`, so entitlement/offerings data is ready before any screen
/// (e.g. [SubscriptionScreen]) might ask for it.
Future<void> initializeRevenueCat() async {
  // Platform-specific API keys
  String apiKey;
  if (Platform.isIOS) {
    apiKey = 'test_HahHTxirPYYCoSNRHnDTmTTCvbJ';
  } else if (Platform.isAndroid) {
    apiKey = 'test_HahHTxirPYYCoSNRHnDTmTTCvbJ';
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(PurchasesConfiguration(apiKey));
}
