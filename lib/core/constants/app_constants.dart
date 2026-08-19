class AppConstants {
  AppConstants._();

  static const String appName = 'BloodBank';
  static const String appTagline = 'Connecting Life, Saving Lives';
  static const String appVersion = '1.0.0';

  // User Roles
  static const String roleDonor = 'donor';
  static const String roleHospital = 'hospital';
  static const String roleAdmin = 'admin';

  // Blood Groups
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  // Donation Rules
  static const int donationIntervalDays = 56; // 8 weeks between donations
  static const int bloodShelfLifeDays = 42;   // 42 days shelf life
  static const int lowStockThreshold = 5;
  static const int criticalStockThreshold = 2;

  // Request Urgency Levels
  static const String urgencyNormal = 'Normal';
  static const String urgencyUrgent = 'Urgent';
  static const String urgencyEmergency = 'Emergency';
  static const List<String> urgencyLevels = [
    urgencyNormal,
    urgencyUrgent,
    urgencyEmergency,
  ];

  // Request Status
  static const String statusPending = 'Pending';
  static const String statusProcessing = 'Processing';
  static const String statusFulfilled = 'Fulfilled';
  static const String statusCancelled = 'Cancelled';

  // Blood Unit Status
  static const String unitAvailable = 'Available';
  static const String unitReserved = 'Reserved';
  static const String unitExpired = 'Expired';
  static const String unitUsed = 'Used';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String donorsCollection = 'donors';
  static const String bloodUnitsCollection = 'blood_units';
  static const String requestsCollection = 'blood_requests';
  static const String appointmentsCollection = 'appointments';

  // SharedPreferences Keys
  static const String prefUserId = 'user_id';
  static const String prefUserRole = 'user_role';
  static const String prefUserName = 'user_name';
  static const String prefUserEmail = 'user_email';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefUseMockData = 'use_mock_data';

  // Demo Credentials (Single Admin & Single Hospital)
  static const String demoAdminEmail = 'admin@bloodbank.com';
  static const String demoHospitalEmail = 'hospital@bloodbank.com';
  static const String demoHospitalAliasEmail = 'hospital@citygeneral.com';
  static const String demoDonorEmail = 'donor@bloodbank.com';
  static const String demoPassword = 'password123';
}
