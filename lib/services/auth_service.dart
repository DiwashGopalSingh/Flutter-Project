import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/config/app_config.dart';
import '../models/user_model.dart';

class AuthService {
  final _uuid = const Uuid();
  static const String _usersPrefKey = 'mock_users_data';
  
  Map<String, Map<String, dynamic>> _mockUsers = {};
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  AuthService() {
    _loadUsers();
    seedDefaultAccountsToDatabase();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersPrefKey);
    if (usersStr != null) {
      final Map<String, dynamic> decoded = json.decode(usersStr);
      _mockUsers = decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
    } else {
      _mockUsers = {};
    }

    // Ensure default Admin exists in database
    if (!_mockUsers.containsKey(AppConstants.demoAdminEmail)) {
      _mockUsers[AppConstants.demoAdminEmail] = {
        'id': 'admin-001',
        'name': 'System Admin',
        'email': AppConstants.demoAdminEmail,
        'phone': '1234567890',
        'role': 'admin',
        'password': AppConstants.demoPassword,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
    }

    // Ensure default Hospital exists in database (primary & alias)
    if (!_mockUsers.containsKey(AppConstants.demoHospitalEmail)) {
      _mockUsers[AppConstants.demoHospitalEmail] = {
        'id': 'h1',
        'name': 'City General Hospital',
        'email': AppConstants.demoHospitalEmail,
        'hospitalName': 'City General Hospital',
        'phone': '9876543210',
        'role': 'hospital',
        'password': AppConstants.demoPassword,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
    }
    if (!_mockUsers.containsKey(AppConstants.demoHospitalAliasEmail)) {
      _mockUsers[AppConstants.demoHospitalAliasEmail] = {
        'id': 'h1',
        'name': 'City General Hospital',
        'email': AppConstants.demoHospitalAliasEmail,
        'hospitalName': 'City General Hospital',
        'phone': '9876543210',
        'role': 'hospital',
        'password': AppConstants.demoPassword,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
    }

    // Ensure default Donor exists in database
    if (!_mockUsers.containsKey(AppConstants.demoDonorEmail)) {
      _mockUsers[AppConstants.demoDonorEmail] = {
        'id': 'donor-001',
        'name': 'Demo Donor',
        'email': AppConstants.demoDonorEmail,
        'phone': '5551234567',
        'role': 'donor',
        'bloodGroup': 'O+',
        'password': AppConstants.demoPassword,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
    }

    // Force update demo passwords to AppConstants.demoPassword ('password123')
    if (_mockUsers.containsKey(AppConstants.demoAdminEmail)) {
      _mockUsers[AppConstants.demoAdminEmail]!['password'] = AppConstants.demoPassword;
    }
    if (_mockUsers.containsKey(AppConstants.demoHospitalEmail)) {
      _mockUsers[AppConstants.demoHospitalEmail]!['password'] = AppConstants.demoPassword;
    }
    if (_mockUsers.containsKey(AppConstants.demoHospitalAliasEmail)) {
      _mockUsers[AppConstants.demoHospitalAliasEmail]!['password'] = AppConstants.demoPassword;
    }
    if (_mockUsers.containsKey(AppConstants.demoDonorEmail)) {
      _mockUsers[AppConstants.demoDonorEmail]!['password'] = AppConstants.demoPassword;
    }

    // Strict Enforcement: Ensure only ONE Admin and ONE Hospital exist across all mock accounts.
    String? primaryAdmin;
    String? primaryHospital;

    _mockUsers.forEach((emailKey, userMap) {
      final role = userMap['role'];
      if (role == 'admin') {
        if (primaryAdmin == null) {
          primaryAdmin = emailKey;
        } else {
          userMap['role'] = 'donor'; // convert extra admin accounts to donor
        }
      } else if (role == 'hospital') {
        if (primaryHospital == null || primaryHospital == AppConstants.demoHospitalEmail) {
          primaryHospital = emailKey;
        } else if (emailKey != AppConstants.demoHospitalAliasEmail && emailKey != AppConstants.demoHospitalEmail) {
          userMap['role'] = 'donor'; // convert extra hospital accounts to donor
        }
      }
    });

    await _saveUsers();
  }

  /// Seeds default Admin, Hospital, and Donor login accounts to Firestore or local database.
  Future<void> seedDefaultAccountsToDatabase() async {
    if (AppConfig.useMockData) {
      await _loadUsers();
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // Seed Admin
      final adminDoc = await firestore.collection('users').doc('admin-001').get();
      if (!adminDoc.exists) {
        await firestore.collection('users').doc('admin-001').set({
          'id': 'admin-001',
          'name': 'System Admin',
          'email': AppConstants.demoAdminEmail,
          'phone': '1234567890',
          'role': 'admin',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        });
      }

      // Seed Hospital
      final hospitalDoc = await firestore.collection('users').doc('h1').get();
      if (!hospitalDoc.exists) {
        await firestore.collection('users').doc('h1').set({
          'id': 'h1',
          'name': 'City General Hospital',
          'email': AppConstants.demoHospitalEmail,
          'hospitalName': 'City General Hospital',
          'phone': '9876543210',
          'role': 'hospital',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        });
      }

      // Seed Demo Donor
      final donorDoc = await firestore.collection('users').doc('donor-001').get();
      if (!donorDoc.exists) {
        await firestore.collection('users').doc('donor-001').set({
          'id': 'donor-001',
          'name': 'Demo Donor',
          'email': AppConstants.demoDonorEmail,
          'phone': '5551234567',
          'role': 'donor',
          'bloodGroup': 'O+',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        });

        await firestore.collection('donors').doc('donor-001').set({
          'id': 'donor-001',
          'userId': 'donor-001',
          'name': 'Demo Donor',
          'bloodGroup': 'O+',
          'phone': '5551234567',
          'totalDonations': 1,
          'donationIds': [],
          'isEligible': true,
          'isAvailable': true,
        });
      }
    } catch (_) {
      // Ignored if offline or not connected
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersPrefKey, json.encode(_mockUsers));
  }

  Future<UserModel?> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final isDemoAccount = cleanEmail == AppConstants.demoAdminEmail ||
        cleanEmail == AppConstants.demoHospitalEmail ||
        cleanEmail == AppConstants.demoHospitalAliasEmail ||
        cleanEmail == AppConstants.demoDonorEmail;

    if (AppConfig.useMockData) {
      return _mockSignIn(cleanEmail, password);
    }
    
    try {
      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
      } on FirebaseAuthException catch (authErr) {
        // For demo accounts (Admin, Hospital, Donor), fallback to mock sign-in if Firebase Auth fails
        if (isDemoAccount) {
          return _mockSignIn(cleanEmail, password);
        }

        if (authErr.code == 'wrong-password') {
          throw Exception('Incorrect password. Please check your credentials and try again.');
        } else if (authErr.code == 'user-not-found' || authErr.code == 'invalid-credential') {
          // Attempt auto-provisioning ONLY IF account doesn't exist in Firebase Auth yet
          await _loadUsers();
          final userMap = _mockUsers[cleanEmail];
          if (userMap != null || cleanEmail.contains('@')) {
            try {
              cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: cleanEmail,
                password: password,
              );

              final name = userMap?['name'] ?? cleanEmail.split('@').first;
              final roleStr = userMap?['role'] ?? 'donor';
              final bloodGroup = userMap?['bloodGroup'] ?? 'A+';
              final phone = userMap?['phone'] ?? '1234567890';
              final hospitalName = userMap?['hospitalName'];

              final newUser = UserModel(
                id: cred.user!.uid,
                name: name,
                email: cleanEmail,
                phone: phone,
                role: UserRoleExtension.fromString(roleStr),
                bloodGroup: bloodGroup,
                hospitalName: hospitalName,
                createdAt: DateTime.now(),
              );

              final mapToSave = newUser.toMap();
              mapToSave['id'] = cred.user!.uid;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(cred.user!.uid)
                  .set(mapToSave);

              if (newUser.role == UserRole.donor) {
                await FirebaseFirestore.instance
                    .collection('donors')
                    .doc(cred.user!.uid)
                    .set({
                  'id': cred.user!.uid,
                  'userId': cred.user!.uid,
                  'name': name,
                  'bloodGroup': bloodGroup,
                  'phone': phone,
                  'totalDonations': 0,
                  'donationIds': [],
                  'isEligible': true,
                  'isAvailable': true,
                });
              }
            } on FirebaseAuthException catch (createErr) {
              if (createErr.code == 'email-already-in-use') {
                return _mockSignIn(cleanEmail, password);
              }
              throw Exception(createErr.message ?? 'Authentication failed.');
            }
          } else {
            throw Exception('Invalid user credentials.');
          }
        } else if (authErr.code == 'email-already-in-use') {
          return _mockSignIn(cleanEmail, password);
        } else {
          throw Exception(authErr.message ?? 'Authentication failed.');
        }
      }
      
      final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        // Create user document if missing
        final emailStr = cred.user!.email ?? email;
        final name = emailStr.split('@').first;
        final isHospital = emailStr == AppConstants.demoHospitalEmail || emailStr == AppConstants.demoHospitalAliasEmail;
        final isAdmin = emailStr == AppConstants.demoAdminEmail;
        final role = isAdmin ? UserRole.admin : (isHospital ? UserRole.hospital : UserRole.donor);

        final newUser = UserModel(
          id: cred.user!.uid,
          name: name,
          email: emailStr,
          phone: '1234567890',
          role: role,
          bloodGroup: 'A+',
          hospitalName: isHospital ? 'City General Hospital' : null,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set(newUser.toMap());
        _currentUser = newUser;
      } else {
        _currentUser = UserModel.fromMap(doc.data()!, cred.user!.uid);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserId, _currentUser!.id);
      await prefs.setString(AppConstants.prefUserRole, _currentUser!.role.value);
      await prefs.setString(AppConstants.prefUserName, _currentUser!.name);
      await prefs.setString(AppConstants.prefUserEmail, _currentUser!.email);
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      
      return _currentUser;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<UserModel?> _mockSignIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    await _loadUsers();

    var userMap = _mockUsers[email.toLowerCase()];
    if (userMap == null) {
      // Auto-create missing mock donor account for seamless access
      final id = _uuid.v4();
      final name = email.split('@').first;
      userMap = {
        'id': id,
        'name': name.isEmpty ? 'Donor User' : name[0].toUpperCase() + name.substring(1),
        'email': email.toLowerCase(),
        'phone': '1234567890',
        'role': 'donor',
        'bloodGroup': 'A+',
        'password': password,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
      _mockUsers[email.toLowerCase()] = userMap;
      await _saveUsers();
    }

    final user = UserModel.fromMap(userMap, userMap['id']);
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserId, user.id);
    await prefs.setString(AppConstants.prefUserRole, user.role.value);
    await prefs.setString(AppConstants.prefUserName, user.name);
    await prefs.setString(AppConstants.prefUserEmail, user.email);
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);

    return user;
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? bloodGroup,
    String? hospitalName,
  }) async {
    if (role == 'admin' || role == 'hospital') {
      if (AppConfig.useMockData) {
        await _loadUsers();
        final hasRole = _mockUsers.values.any((u) => u['role'] == role);
        if (hasRole) {
          throw Exception('Only one ${role == "admin" ? "Admin" : "Hospital"} account is allowed in the system.');
        }
      } else {
        final existing = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: role)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          throw Exception('Only one ${role == "admin" ? "Admin" : "Hospital"} account is allowed in the system.');
        }
      }
    }

    if (AppConfig.useMockData) {
      return _mockRegister(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        bloodGroup: bloodGroup,
        hospitalName: hospitalName,
      );
    }
    
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = cred.user!.uid;
      final userMap = {
        'name': name,
        'email': email.toLowerCase(),
        'phone': phone,
        'role': role,
        'bloodGroup': bloodGroup,
        'hospitalName': hospitalName,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
      
      await FirebaseFirestore.instance.collection('users').doc(uid).set(userMap);
      
      final user = UserModel.fromMap(userMap, uid);

      if (user.role == UserRole.donor) {
        await FirebaseFirestore.instance.collection('donors').doc(uid).set({
          'id': uid,
          'userId': uid,
          'name': name,
          'bloodGroup': bloodGroup ?? 'A+',
          'phone': phone,
          'totalDonations': 0,
          'donationIds': [],
          'isEligible': true,
          'isAvailable': true,
        });
      }
      _currentUser = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserId, user.id);
      await prefs.setString(AppConstants.prefUserRole, user.role.value);
      await prefs.setString(AppConstants.prefUserName, user.name);
      await prefs.setString(AppConstants.prefUserEmail, user.email);
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      
      return user;
    } on FirebaseAuthException catch (authErr) {
      if (authErr.code == 'email-already-in-use') {
        throw Exception('An account with this email address already exists. Please sign in instead.');
      }
      throw Exception(authErr.message ?? 'Registration failed.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<UserModel?> _mockRegister({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? bloodGroup,
    String? hospitalName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    await _loadUsers();

    if (role == 'admin' || role == 'hospital') {
      final hasRole = _mockUsers.values.any((u) => u['role'] == role);
      if (hasRole) {
        throw Exception('Only one ${role == "admin" ? "Admin" : "Hospital"} account is allowed in the system.');
      }
    }

    if (_mockUsers.containsKey(email.toLowerCase())) {
      throw Exception('An account with this email already exists.');
    }

    final id = _uuid.v4();
    final userMap = {
      'id': id,
      'name': name,
      'email': email.toLowerCase(),
      'phone': phone,
      'role': role,
      'bloodGroup': bloodGroup,
      'hospitalName': hospitalName,
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': true,
    };

    _mockUsers[email.toLowerCase()] = userMap;
    await _saveUsers();

    final user = UserModel.fromMap(userMap, id);
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserId, user.id);
    await prefs.setString(AppConstants.prefUserRole, user.role.value);
    await prefs.setString(AppConstants.prefUserName, user.name);
    await prefs.setString(AppConstants.prefUserEmail, user.email);
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);

    return user;
  }

  Future<UserModel?> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
    final email = prefs.getString(AppConstants.prefUserEmail);

    if (!isLoggedIn || email == null) return null;

    if (AppConfig.useMockData) {
      await _loadUsers();
      final userMap = _mockUsers[email.toLowerCase()];
      if (userMap == null) return null;
      final user = UserModel.fromMap(userMap, userMap['id']);
      _currentUser = user;
      return user;
    }
    
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
        if (doc.exists) {
          final user = UserModel.fromMap(doc.data()!, fbUser.uid);
          _currentUser = user;
          return user;
        }
      }
      
      // Fallback check if logged in as demo or local account
      await _loadUsers();
      final userMap = _mockUsers[email.toLowerCase()];
      if (userMap != null) {
        final user = UserModel.fromMap(userMap, userMap['id']);
        _currentUser = user;
        return user;
      }
      return null;
    } catch (e) {
      await _loadUsers();
      final userMap = _mockUsers[email.toLowerCase()];
      if (userMap != null) {
        final user = UserModel.fromMap(userMap, userMap['id']);
        _currentUser = user;
        return user;
      }
      return null;
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    if (!AppConfig.useMockData) {
      await FirebaseAuth.instance.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> updateUser(UserModel user) async {
    _currentUser = user;
    if (AppConfig.useMockData) {
      await _loadUsers();
      if (_mockUsers.containsKey(user.email)) {
        _mockUsers[user.email]!['name'] = user.name;
        _mockUsers[user.email]!['phone'] = user.phone;
        _mockUsers[user.email]!['address'] = user.address;
        _mockUsers[user.email]!['bloodGroup'] = user.bloodGroup;
        await _saveUsers();
      }
    } else {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'name': user.name,
        'phone': user.phone,
        'address': user.address,
        'bloodGroup': user.bloodGroup,
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserName, user.name);
  }
}
