import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/app_config.dart';
import '../models/donor_model.dart';

class DonorService {
  final _uuid = const Uuid();
  static const String _donorsPrefKey = 'mock_donors_data';

  List<DonorModel> _mockDonors = [];

  DonorService() {
    _loadDonors();
  }

  Future<void> _loadDonors() async {
    final prefs = await SharedPreferences.getInstance();
    final donorsStr = prefs.getString(_donorsPrefKey);
    if (donorsStr != null) {
      final List<dynamic> decoded = json.decode(donorsStr);
      _mockDonors = decoded.map((map) => DonorModel.fromMap(map, map['id'])).toList();
    } else {
      _mockDonors = [];
    }
  }

  Future<void> _saveDonors() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded = _mockDonors.map((d) {
      final map = d.toMap();
      map['id'] = d.id; // ensure ID is preserved
      return map;
    }).toList();
    await prefs.setString(_donorsPrefKey, json.encode(encoded));
  }

  Future<List<DonorModel>> getAllDonors() async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadDonors();
      return List.from(_mockDonors);
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance.collection('donors').get();
      return snapshot.docs
          .map((doc) => DonorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch donors: $e');
    }
  }

  Future<List<DonorModel>> getDonorsByBloodGroup(String bloodGroup) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadDonors();
      return _mockDonors.where((d) => d.bloodGroup == bloodGroup).toList();
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donors')
          .where('bloodGroup', isEqualTo: bloodGroup)
          .get();
      return snapshot.docs
          .map((doc) => DonorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch donors by blood group: $e');
    }
  }

  Future<DonorModel?> getDonorByUserId(String userId) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadDonors();
      try {
        return _mockDonors.firstWhere((d) => d.userId == userId);
      } catch (_) {
        return null;
      }
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donors')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
          
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return DonorModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      return null;
    }
  }

  Future<DonorModel> createDonorRecord(DonorModel donor) async {
    final newDonor = DonorModel(
      id: _uuid.v4(),
      userId: donor.userId,
      name: donor.name,
      bloodGroup: donor.bloodGroup,
      phone: donor.phone,
      address: donor.address,
      isEligible: donor.isEligible,
      isAvailable: donor.isAvailable,
      lastDonationDate: donor.lastDonationDate,
      totalDonations: donor.totalDonations,
      donationIds: donor.donationIds,
    );
    
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadDonors();
      _mockDonors.add(newDonor);
      await _saveDonors();
      return newDonor;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('donors')
          .doc(newDonor.id)
          .set(newDonor.toMap());
      return newDonor;
    } catch (e) {
      throw Exception('Failed to create donor record: $e');
    }
  }

  Future<DonorModel> recordDonation(String donorId) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      await _loadDonors();

      final index = _mockDonors.indexWhere((d) => d.id == donorId);
      if (index == -1) throw Exception('Donor not found');

      final donor = _mockDonors[index];
      final updated = donor.copyWith(
        lastDonationDate: DateTime.now(),
        totalDonations: donor.totalDonations + 1,
        isEligible: false,
        donationIds: [...donor.donationIds, _uuid.v4()],
      );
      _mockDonors[index] = updated;
      await _saveDonors();
      return updated;
    }
    
    try {
      final docRef = FirebaseFirestore.instance.collection('donors').doc(donorId);
      final newDonationId = _uuid.v4();
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Donor not found');
        
        final donor = DonorModel.fromMap(snapshot.data()!, snapshot.id);
        transaction.update(docRef, {
          'lastDonationDate': DateTime.now().toIso8601String(),
          'totalDonations': donor.totalDonations + 1,
          'isEligible': false,
          'donationIds': FieldValue.arrayUnion([newDonationId]),
        });
      });
      
      final doc = await docRef.get();
      return DonorModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to record donation: $e');
    }
  }

  Future<DonorModel> updateDonor(DonorModel donor) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _loadDonors();
      
      final index = _mockDonors.indexWhere((d) => d.id == donor.id);
      if (index != -1) {
        _mockDonors[index] = donor;
        await _saveDonors();
      }
      return donor;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('donors')
          .doc(donor.id)
          .update(donor.toMap());
      return donor;
    } catch (e) {
      throw Exception('Failed to update donor: $e');
    }
  }

  // Note: These getters will only work synchronously for mock data.
  // For Firestore, it is better to query the database.
  int get totalDonors => _mockDonors.length;
  int get availableDonors => _mockDonors.where((d) => d.isAvailable && d.isEligible).length;
}
