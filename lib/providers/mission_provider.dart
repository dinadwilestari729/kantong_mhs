import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MissionProvider with ChangeNotifier {
  List<Map<String, dynamic>> _missions = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get missions => _missions;
  bool get isLoading => _isLoading;
  
  List<Map<String, dynamic>> get activeMissions {
    return _missions.where((m) => m['status'] == 'active').toList();
  }
  
  List<Map<String, dynamic>> get completedMissions {
    return _missions.where((m) => m['status'] == 'completed').toList();
  }

  Future<void> loadMissions(int userId) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.getMissions(userId);

    if (result['success'] == true) {
      _missions = List<Map<String, dynamic>>.from(result['missions']);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createMission({
    required int userId,
    required String title,
    required double targetAmount,
    int rewardPoints = 10,
    String? deadline,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.createMission(
      userId: userId,
      title: title,
      targetAmount: targetAmount,
      rewardPoints: rewardPoints,
      deadline: deadline,
    );

    _isLoading = false;
    notifyListeners();

    if (result['success'] == true) {
      await loadMissions(userId);
      return true;
    }
    return false;
  }

  Future<void> updateMissionProgress(int missionId) async {
    await ApiService.updateMissionProgress(missionId);
  }
}