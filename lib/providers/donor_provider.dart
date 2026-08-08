import 'package:flutter/foundation.dart';
import '../models/donor_model.dart';
import '../services/donor_service.dart';

class DonorProvider extends ChangeNotifier {
  final DonorService _service;

  DonorProvider(this._service);

  List<DonorModel> _donors = [];
  DonorModel? _currentDonorProfile;
  bool _isLoading = false;
  String? _errorMessage;

  List<DonorModel> get donors => _donors;
  DonorModel? get currentDonorProfile => _currentDonorProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalDonors => _service.totalDonors;
  int get availableDonors => _service.availableDonors;

  Future<void> loadDonors() async {
    _isLoading = true;
    notifyListeners();
    try {
      _donors = await _service.getAllDonors();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDonorProfile(String userId) async {
    try {
      _currentDonorProfile = await _service.getDonorByUserId(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<List<DonorModel>> searchByBloodGroup(String bloodGroup) async {
    try {
      return await _service.getDonorsByBloodGroup(bloodGroup);
    } catch (e) {
      return [];
    }
  }

  Future<void> recordDonation(String donorId) async {
    try {
      final updated = await _service.recordDonation(donorId);
      final index = _donors.indexWhere((d) => d.id == donorId);
      if (index != -1) {
        _donors[index] = updated;
      }
      if (_currentDonorProfile?.id == donorId) {
        _currentDonorProfile = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> createDonorProfile(DonorModel donor) async {
    try {
      final created = await _service.createDonorRecord(donor);
      _donors.add(created);
      _currentDonorProfile = created;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  List<DonorModel> filterDonors({String? bloodGroup, bool? availableOnly}) {
    return _donors.where((d) {
      if (bloodGroup != null && bloodGroup.isNotEmpty && d.bloodGroup != bloodGroup) return false;
      if (availableOnly == true && (!d.isAvailable || !d.isEligible)) return false;
      return true;
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
