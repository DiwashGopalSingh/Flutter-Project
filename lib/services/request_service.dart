import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/app_config.dart';
import '../models/blood_request_model.dart';

class RequestService {
  final _uuid = const Uuid();
  static const String _requestsPrefKey = 'mock_requests_data';

  List<BloodRequestModel> _mockRequests = [];

  RequestService() {
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final requestsStr = prefs.getString(_requestsPrefKey);
    if (requestsStr != null) {
      final List<dynamic> decoded = json.decode(requestsStr);
      _mockRequests = [];
      for (int i = 0; i < decoded.length; i++) {
        final map = Map<String, dynamic>.from(decoded[i]);
        final String rawId = (map['id'] != null && map['id'].toString().isNotEmpty)
            ? map['id'].toString()
            : 'req_mock_${i + 1}';
        _mockRequests.add(BloodRequestModel.fromMap(map, rawId));
      }
      _mockRequests.sort((a, b) => b.requestDate.compareTo(a.requestDate));
    } else {
      final now = DateTime.now();
      _mockRequests = [
        BloodRequestModel(
          id: 'req_mock_1',
          requestedBy: 'h1',
          requesterName: 'City General Hospital',
          hospitalName: 'City General Hospital',
          bloodGroup: 'O+',
          quantity: 2,
          urgency: 'Emergency',
          status: 'Pending',
          patientName: 'John Doe',
          notes: 'Urgent surgery requirement',
          requestDate: now.subtract(const Duration(hours: 2)),
          contactPhone: '9876543210',
        ),
        BloodRequestModel(
          id: 'req_mock_2',
          requestedBy: 'h1',
          requesterName: 'City General Hospital',
          hospitalName: 'City General Hospital',
          bloodGroup: 'A+',
          quantity: 1,
          urgency: 'Urgent',
          status: 'Pending',
          patientName: 'Jane Smith',
          notes: 'ICU Patient',
          requestDate: now.subtract(const Duration(hours: 5)),
          contactPhone: '9876543210',
        ),
      ];
      await _saveRequests();
    }
  }

  Future<void> _saveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded = _mockRequests.map((r) {
      final map = r.toMap();
      map['id'] = r.id; // preserve ID
      return map;
    }).toList();
    await prefs.setString(_requestsPrefKey, json.encode(encoded));
  }

  Future<List<BloodRequestModel>> getAllRequests() async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadRequests();
      return List.from(_mockRequests);
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('blood_requests')
          .orderBy('requestDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch requests: $e');
    }
  }

  Future<List<BloodRequestModel>> getRequestsForUser(String userId) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _loadRequests();
      return _mockRequests
          .where((r) => r.requestedBy == userId)
          .toList();
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('blood_requests')
          .where('requestedBy', isEqualTo: userId)
          .orderBy('requestDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch requests for user: $e');
    }
  }

  Future<List<BloodRequestModel>> getPendingRequests() async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _loadRequests();
      return _mockRequests
          .where((r) => r.status == 'Pending' || r.status == 'Processing')
          .toList();
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('blood_requests')
          .where('status', whereIn: ['Pending', 'Processing'])
          .orderBy('requestDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  Future<BloodRequestModel> createRequest(BloodRequestModel request) async {
    final newRequest = BloodRequestModel(
      id: _uuid.v4(),
      requestedBy: request.requestedBy,
      requesterName: request.requesterName,
      hospitalName: request.hospitalName,
      bloodGroup: request.bloodGroup,
      quantity: request.quantity,
      urgency: request.urgency,
      status: 'Pending',
      patientName: request.patientName,
      notes: request.notes,
      requestDate: DateTime.now(),
      contactPhone: request.contactPhone,
    );

    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 700));
      await _loadRequests();
      _mockRequests.insert(0, newRequest);
      await _saveRequests();
      return newRequest;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(newRequest.id)
          .set(newRequest.toMap());
      return newRequest;
    } catch (e) {
      throw Exception('Failed to create request: $e');
    }
  }

  Future<BloodRequestModel> recordUnitDonation(String id, {int units = 1}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _loadRequests();

      var index = _mockRequests.indexWhere((r) => r.id == id);
      if (index == -1) {
        index = _mockRequests.indexWhere((r) => r.status != 'Fulfilled' && r.status != 'Cancelled');
      }
      if (index == -1) throw Exception('Request not found');

      final req = _mockRequests[index];
      final newFulfilled = req.fulfilledQuantity + units;
      final isFullyFulfilled = newFulfilled >= req.quantity;
      final newStatus = isFullyFulfilled ? 'Fulfilled' : 'Processing';

      final updated = req.copyWith(
        fulfilledQuantity: newFulfilled,
        status: newStatus,
        fulfilledDate: isFullyFulfilled ? DateTime.now() : req.fulfilledDate,
      );

      _mockRequests[index] = updated;
      await _saveRequests();
      return updated;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('blood_requests').doc(id);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) throw Exception('Request not found');

      final req = BloodRequestModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      final newFulfilled = req.fulfilledQuantity + units;
      final isFullyFulfilled = newFulfilled >= req.quantity;
      final newStatus = isFullyFulfilled ? 'Fulfilled' : 'Processing';

      await docRef.update({
        'fulfilledQuantity': newFulfilled,
        'status': newStatus,
        'fulfilledDate': isFullyFulfilled ? DateTime.now().toIso8601String() : req.fulfilledDate?.toIso8601String(),
      });

      final updatedDoc = await docRef.get();
      return BloodRequestModel.fromMap(updatedDoc.data()!, updatedDoc.id);
    } catch (e) {
      throw Exception('Failed to record donation unit: $e');
    }
  }

  Future<BloodRequestModel> updateStatus(String id, String status) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _loadRequests();
      
      final index = _mockRequests.indexWhere((r) => r.id == id);
      if (index == -1) throw Exception('Request not found');

      final updated = _mockRequests[index].copyWith(
        status: status,
        fulfilledDate: status == 'Fulfilled' ? DateTime.now() : null,
      );
      _mockRequests[index] = updated;
      await _saveRequests();
      return updated;
    }
    
    try {
      final docRef = FirebaseFirestore.instance.collection('blood_requests').doc(id);
      final fulfilledDate = status == 'Fulfilled' ? DateTime.now().toIso8601String() : null;
      
      await docRef.update({
        'status': status,
        'fulfilledDate': fulfilledDate,
      });
      
      final doc = await docRef.get();
      return BloodRequestModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  Future<void> deleteRequest(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadRequests();
      _mockRequests.removeWhere((r) => r.id == id);
      await _saveRequests();
      return;
    }
    
    try {
      await FirebaseFirestore.instance.collection('blood_requests').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete request: $e');
    }
  }
}
