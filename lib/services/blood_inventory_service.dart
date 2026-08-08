import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blood_unit_model.dart';
import '../core/config/app_config.dart';

class BloodInventoryService {
  final _uuid = const Uuid();
  static const String _inventoryPrefKey = 'mock_inventory_data';

  List<BloodUnitModel> _mockInventory = [];

  BloodInventoryService() {
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final inventoryStr = prefs.getString(_inventoryPrefKey);
    if (inventoryStr != null) {
      final List<dynamic> decoded = json.decode(inventoryStr);
      _mockInventory = decoded.map((map) => BloodUnitModel.fromMap(map, map['id'])).toList();
    } else {
      _mockInventory = [];
    }
  }

  Future<void> _saveInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded = _mockInventory.map((u) {
      final map = u.toMap();
      map['id'] = u.id; // preserve ID
      return map;
    }).toList();
    await prefs.setString(_inventoryPrefKey, json.encode(encoded));
  }

  Future<List<BloodUnitModel>> getInventory() async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadInventory();
      return List.from(_mockInventory);
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance.collection('blood_units').get();
      return snapshot.docs
          .map((doc) => BloodUnitModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch inventory: $e');
    }
  }



  Future<BloodUnitModel> addUnit(BloodUnitModel unit) async {
    final newUnit = BloodUnitModel(
      id: _uuid.v4(),
      bloodGroup: unit.bloodGroup,
      quantity: unit.quantity,
      collectionDate: unit.collectionDate,
      expiryDate: unit.expiryDate,
      status: unit.status,
      donorId: unit.donorId,
      donorName: unit.donorName,
      location: unit.location,
    );
    
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      await _loadInventory();
      _mockInventory.add(newUnit);
      await _saveInventory();
      return newUnit;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('blood_units')
          .doc(newUnit.id)
          .set(newUnit.toMap());
      return newUnit;
    } catch (e) {
      throw Exception('Failed to add blood unit: $e');
    }
  }

  Future<BloodUnitModel> updateUnit(BloodUnitModel unit) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _loadInventory();
      
      final index = _mockInventory.indexWhere((u) => u.id == unit.id);
      if (index != -1) {
        _mockInventory[index] = unit;
        await _saveInventory();
      }
      return unit;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('blood_units')
          .doc(unit.id)
          .update(unit.toMap());
      return unit;
    } catch (e) {
      throw Exception('Failed to update blood unit: $e');
    }
  }

  Future<void> deleteUnit(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _loadInventory();
      _mockInventory.removeWhere((u) => u.id == id);
      await _saveInventory();
      return;
    }
    
    try {
      await FirebaseFirestore.instance.collection('blood_units').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete blood unit: $e');
    }
  }

  Future<void> markUnitUsed(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadInventory();
      
      final index = _mockInventory.indexWhere((u) => u.id == id);
      if (index != -1) {
        _mockInventory[index] = _mockInventory[index].copyWith(status: 'Used');
        await _saveInventory();
      }
      return;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('blood_units')
          .doc(id)
          .update({'status': 'Used'});
    } catch (e) {
      throw Exception('Failed to mark unit as used: $e');
    }
  }
}
