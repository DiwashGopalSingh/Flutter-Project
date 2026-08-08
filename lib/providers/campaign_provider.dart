import 'package:flutter/foundation.dart';
import '../models/campaign_model.dart';
import '../services/campaign_service.dart';

class CampaignProvider extends ChangeNotifier {
  final CampaignService _service;

  CampaignProvider(this._service);

  List<CampaignModel> _campaigns = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CampaignModel> get campaigns => _campaigns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCampaigns() async {
    _isLoading = true;
    notifyListeners();
    try {
      _campaigns = await _service.getAllCampaigns();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCampaign(CampaignModel campaign) async {
    try {
      final created = await _service.createCampaign(campaign);
      _campaigns.add(created);
      _campaigns.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerForCampaign(String campaignId, String userId) async {
    try {
      final updated = await _service.registerForCampaign(campaignId, userId);
      final index = _campaigns.indexWhere((c) => c.id == campaignId);
      if (index != -1) {
        _campaigns[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> startDonation(String campaignId, String userId) async {
    try {
      final updated = await _service.startDonation(campaignId, userId);
      final index = _campaigns.indexWhere((c) => c.id == campaignId);
      if (index != -1) {
        _campaigns[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
