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
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersPrefKey);
    if (usersStr != null) {
      final Map<String, dynamic> decoded = json.decode(usersStr);
      _mockUsers = decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
    } else {
      _mockUsers = {
        'admin@bloodbank.com': {
          'id': 'admin-001',
          'name': 'System Admin',
          'email': 'admin@bloodbank.com',
          'phone': '1234567890',
          'role': 'admin',
          'password': 'password123',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        }
      };
      _saveUsers();
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersPrefKey, json.encode(_mockUsers));
  }

  Future<UserModel?> signIn(String email, String password) async {
    if (AppConfig.useMockData) {
      return _mockSignIn(email, password);
    }
    
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        throw Exception('User record not found in database.');
      }
      
      final user = UserModel.fromMap(doc.data()!, cred.user!.uid);
      _currentUser = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserId, user.id);
      await prefs.setString(AppConstants.prefUserRole, user.role.value);
      await prefs.setString(AppConstants.prefUserName, user.name);
      await prefs.setString(AppConstants.prefUserEmail, user.email);
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      
      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel?> _mockSignIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    await _loadUsers();

    final userMap = _mockUsers[email.toLowerCase()];
    if (userMap == null) throw Exception('No account found with this email.');
    if (userMap['password'] != password) throw Exception('Incorrect password.');

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
      _currentUser = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserId, user.id);
      await prefs.setString(AppConstants.prefUserRole, user.role.value);
      await prefs.setString(AppConstants.prefUserName, user.name);
      await prefs.setString(AppConstants.prefUserEmail, user.email);
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      
      return user;
    } catch (e) {
      throw Exception(e.toString());
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
    if (!isLoggedIn) return null;

    final email = prefs.getString(AppConstants.prefUserEmail);
    if (email == null) return null;

    if (AppConfig.useMockData) {
      await _loadUsers();
      final userMap = _mockUsers[email];
      if (userMap == null) return null;
      final user = UserModel.fromMap(userMap, userMap['id']);
      _currentUser = user;
      return user;
    }
    
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) return null;
      
      final doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
      if (!doc.exists) return null;
      
      final user = UserModel.fromMap(doc.data()!, fbUser.uid);
      _currentUser = user;
      return user;
    } catch (e) {
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
