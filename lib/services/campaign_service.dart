import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/app_config.dart';
import '../models/campaign_model.dart';

class CampaignService {
  final _uuid = const Uuid();
  static const String _campaignsPrefKey = 'mock_campaigns_data';

  List<CampaignModel> _mockCampaigns = [];

  CampaignService() {
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    final prefs = await SharedPreferences.getInstance();
    final campaignsStr = prefs.getString(_campaignsPrefKey);
    if (campaignsStr != null) {
      final List<dynamic> decoded = json.decode(campaignsStr);
      _mockCampaigns = decoded.map((map) => CampaignModel.fromMap(map, map['id'])).toList();
      _mockCampaigns.sort((a, b) => a.date.compareTo(b.date)); // Sort ascending by date
    } else {
      final now = DateTime.now();
      _mockCampaigns = [
        CampaignModel(
          id: _uuid.v4(),
          title: 'City General Blood Drive',
          description: 'Join us for our community blood donation drive. Every unit counts!',
          location: 'City General Hospital',
          date: now.add(const Duration(days: 3)),
          organizerId: 'h1',
          organizerName: 'City General Hospital',
          targetBloodGroups: ['O-', 'A+', 'B+'],
        ),
      ];
      await _saveCampaigns();
    }
  }

  Future<void> _saveCampaigns() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded = _mockCampaigns.map((c) {
      final map = c.toMap();
      map['id'] = c.id;
      return map;
    }).toList();
    await prefs.setString(_campaignsPrefKey, json.encode(encoded));
  }

  Future<List<CampaignModel>> getAllCampaigns() async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadCampaigns();
      return List.from(_mockCampaigns.where((c) => c.isActive));
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('isActive', isEqualTo: true)
          .orderBy('date', descending: false)
          .get();
          
      return snapshot.docs
          .map((doc) => CampaignModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch campaigns: $e');
    }
  }

  Future<CampaignModel> createCampaign(CampaignModel campaign) async {
    final newCampaign = CampaignModel(
      id: _uuid.v4(),
      title: campaign.title,
      description: campaign.description,
      location: campaign.location,
      date: campaign.date,
      organizerId: campaign.organizerId,
      organizerName: campaign.organizerName,
      targetBloodGroups: campaign.targetBloodGroups,
    );

    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      await _loadCampaigns();
      _mockCampaigns.add(newCampaign);
      await _saveCampaigns();
      return newCampaign;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(newCampaign.id)
          .set(newCampaign.toMap());
      return newCampaign;
    } catch (e) {
      throw Exception('Failed to create campaign: $e');
    }
  }

  Future<CampaignModel> registerForCampaign(String campaignId, String userId) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _loadCampaigns();
      
      final index = _mockCampaigns.indexWhere((c) => c.id == campaignId);
      if (index == -1) throw Exception('Campaign not found');

      final campaign = _mockCampaigns[index];
      if (campaign.registeredUserIds.contains(userId)) {
        throw Exception('User is already registered for this campaign');
      }

      final updated = campaign.copyWith(
        registeredUserIds: [...campaign.registeredUserIds, userId],
      );
      _mockCampaigns[index] = updated;
      await _saveCampaigns();
      return updated;
    }
    
    try {
      final docRef = FirebaseFirestore.instance.collection('campaigns').doc(campaignId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Campaign not found');
        
        final campaign = CampaignModel.fromMap(snapshot.data()!, snapshot.id);
        if (campaign.registeredUserIds.contains(userId)) {
          throw Exception('User is already registered for this campaign');
        }
        
        transaction.update(docRef, {
          'registeredUserIds': FieldValue.arrayUnion([userId])
        });
      });
      
      final doc = await docRef.get();
      return CampaignModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to register for campaign: $e');
    }
  }

  Future<CampaignModel> startDonation(String campaignId, String userId) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _loadCampaigns();
      
      final index = _mockCampaigns.indexWhere((c) => c.id == campaignId);
      if (index == -1) throw Exception('Campaign not found');

      final campaign = _mockCampaigns[index];
      if (!campaign.registeredUserIds.contains(userId)) {
        throw Exception('User is not registered for this campaign');
      }
      if (campaign.donatedUserIds.contains(userId)) {
        throw Exception('User has already donated in this campaign');
      }

      final updated = campaign.copyWith(
        donatedUserIds: [...campaign.donatedUserIds, userId],
      );
      _mockCampaigns[index] = updated;
      await _saveCampaigns();
      return updated;
    }
    
    try {
      final docRef = FirebaseFirestore.instance.collection('campaigns').doc(campaignId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Campaign not found');
        
        final campaign = CampaignModel.fromMap(snapshot.data()!, snapshot.id);
        if (!campaign.registeredUserIds.contains(userId)) {
          throw Exception('User is not registered for this campaign');
        }
        if (campaign.donatedUserIds.contains(userId)) {
          throw Exception('User has already donated in this campaign');
        }
        
        transaction.update(docRef, {
          'donatedUserIds': FieldValue.arrayUnion([userId])
        });
      });
      
      final doc = await docRef.get();
      return CampaignModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to start donation: $e');
    }
  }
}
