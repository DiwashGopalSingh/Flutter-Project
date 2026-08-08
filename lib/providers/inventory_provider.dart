import 'package:flutter/foundation.dart';
import '../models/blood_unit_model.dart';
import '../services/blood_inventory_service.dart';
import '../core/constants/app_constants.dart';

class InventoryProvider extends ChangeNotifier {
  final BloodInventoryService _service;

  InventoryProvider(this._service);

  List<BloodUnitModel> _units = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BloodUnitModel> get units => _units;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, int> get stockSummary {
    final Map<String, int> summary = {};
    for (final group in AppConstants.bloodGroups) {
      summary[group] = 0;
    }
    for (final unit in _units) {
      if (unit.isAvailable) {
        summary[unit.bloodGroup] = (summary[unit.bloodGroup] ?? 0) + unit.quantity;
      }
    }
    return summary;
  }

  int get totalUnits {
    return _units
        .where((u) => u.isAvailable)
        .fold(0, (sum, u) => sum + u.quantity);
  }

  List<BloodUnitModel> get expiringUnits {
    return _units.where((u) => u.isExpiringSoon).toList();
  }

  Future<void> loadInventory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _units = await _service.getInventory();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUnit(BloodUnitModel unit) async {
    try {
      final newUnit = await _service.addUnit(unit);
      _units.add(newUnit);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateUnit(BloodUnitModel unit) async {
    try {
      final updated = await _service.updateUnit(unit);
      final index = _units.indexWhere((u) => u.id == unit.id);
      if (index != -1) {
        _units[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteUnit(String id) async {
    try {
      await _service.deleteUnit(id);
      _units.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  List<BloodUnitModel> filterByBloodGroup(String bloodGroup) {
    return _units.where((u) => u.bloodGroup == bloodGroup).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
