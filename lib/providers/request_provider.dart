import 'package:flutter/foundation.dart';
import '../models/blood_request_model.dart';
import '../services/request_service.dart';

class RequestProvider extends ChangeNotifier {
  final RequestService _service;

  RequestProvider(this._service);

  List<BloodRequestModel> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BloodRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, int> get stats {
    return {
      'total': _requests.length,
      'pending': _requests.where((r) => r.status == 'Pending').length,
      'processing': _requests.where((r) => r.status == 'Processing').length,
      'fulfilled': _requests.where((r) => r.status == 'Fulfilled').length,
      'cancelled': _requests.where((r) => r.status == 'Cancelled').length,
    };
  }

  List<BloodRequestModel> get pendingRequests =>
      _requests.where((r) => r.status == 'Pending' || r.status == 'Processing').toList();

  List<BloodRequestModel> get emergencyRequests =>
      _requests.where((r) => r.urgency == 'Emergency' && r.status == 'Pending').toList();

  Future<void> loadAllRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      _requests = await _service.getAllRequests();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserRequests(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _requests = await _service.getRequestsForUser(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRequest(BloodRequestModel request) async {
    try {
      final created = await _service.createRequest(request);
      _requests.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      final updated = await _service.updateStatus(id, status);
      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _requests[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRequest(String id) async {
    try {
      await _service.deleteRequest(id);
      _requests.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
