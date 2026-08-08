import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/donor_home_screen.dart';
import '../../screens/home/hospital_home_screen.dart';
import '../../screens/home/admin_home_screen.dart';
import '../../screens/donor/donation_history_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/requests/blood_request_screen.dart';
import '../../screens/requests/create_request_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/campaigns/campaigns_screen.dart';
import '../../screens/donor/direct_donation_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String donorHome = '/donor-home';
  static const String hospitalHome = '/hospital-home';
  static const String adminHome = '/admin-home';
  static const String donationHistory = '/donation-history';
  static const String inventory = '/inventory';
  static const String bloodRequests = '/blood-requests';
  static const String createRequest = '/create-request';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String campaigns = '/campaigns';
  static const String directDonation = '/direct-donation';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case donorHome:
        return _buildRoute(const DonorHomeScreen(), settings);
      case hospitalHome:
        return _buildRoute(const HospitalHomeScreen(), settings);
      case adminHome:
        return _buildRoute(const AdminHomeScreen(), settings);
      case donationHistory:
        return _buildRoute(const DonationHistoryScreen(), settings);
      case inventory:
        return _buildRoute(const InventoryScreen(), settings);
      case bloodRequests:
        return _buildRoute(const BloodRequestScreen(), settings);
      case createRequest:
        return _buildRoute(const CreateRequestScreen(), settings);
      case search:
        return _buildRoute(const SearchScreen(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case campaigns:
        return _buildRoute(const CampaignsScreen(), settings);
      case directDonation:
        return _buildRoute(const DirectDonationScreen(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
