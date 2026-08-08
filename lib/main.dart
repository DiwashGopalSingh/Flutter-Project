import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/blood_inventory_service.dart';
import 'services/donor_service.dart';
import 'services/request_service.dart';
import 'providers/auth_provider.dart';
import 'providers/donor_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/request_provider.dart';
import 'services/campaign_service.dart';
import 'providers/campaign_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Firebase initialization (enable when AppConfig.useMockData = false)
  if (!AppConfig.useMockData) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const BloodBankApp());
}

class BloodBankApp extends StatelessWidget {
  const BloodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final authService = AuthService();
    final inventoryService = BloodInventoryService();
    final requestService = RequestService();
    final donorService = DonorService();
    final campaignService = CampaignService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(inventoryService),
        ),
        ChangeNotifierProvider(
          create: (_) => RequestProvider(requestService),
        ),
        ChangeNotifierProvider(
          create: (_) => DonorProvider(donorService),
        ),
        ChangeNotifierProvider(
          create: (_) => CampaignProvider(campaignService),
        ),
      ],
      child: MaterialApp(
        title: 'Blood Bank Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
