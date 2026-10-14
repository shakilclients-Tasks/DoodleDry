import 'dart:async';
import '../../../../core/services/local_storage_service.dart';
import '../models/baby_profile_model.dart';

abstract class IBabyProfileRepository {
  Stream<BabyProfileModel?> get profileStream;
  BabyProfileModel? get currentProfile;
  Future<void> saveProfile(BabyProfileModel profile);
  Future<void> updateBabyName(String name);
  Future<void> updateCaregiverInfo(String caregiverName, String relationship, String emergencyContact);
}

/// Repository managing the active infant's profile data
class BabyProfileRepository implements IBabyProfileRepository {
  final LocalStorageService _storageService;
  final StreamController<BabyProfileModel?> _profileStreamController =
      StreamController<BabyProfileModel?>.broadcast();
  BabyProfileModel? _currentProfile;

  BabyProfileRepository(this._storageService) {
    _currentProfile = _storageService.getBabyProfile() ?? BabyProfileModel.demo();
    _storageService.saveBabyProfile(_currentProfile!);
    _profileStreamController.add(_currentProfile);
  }

  @override
  Stream<BabyProfileModel?> get profileStream => _profileStreamController.stream;

  @override
  BabyProfileModel? get currentProfile => _currentProfile;

  @override
  Future<void> saveProfile(BabyProfileModel profile) async {
    _currentProfile = profile;
    await _storageService.saveBabyProfile(profile);
    _profileStreamController.add(profile);
  }

  @override
  Future<void> updateBabyName(String name) async {
    if (_currentProfile != null) {
      final updated = _currentProfile!.copyWith(name: name);
      await saveProfile(updated);
    }
  }

  @override
  Future<void> updateCaregiverInfo(String caregiverName, String relationship, String emergencyContact) async {
    if (_currentProfile != null) {
      final updated = _currentProfile!.copyWith(
        caregiverName: caregiverName,
        relationship: relationship,
        emergencyContact: emergencyContact,
      );
      await saveProfile(updated);
    }
  }

  void dispose() {
    _profileStreamController.close();
  }
}
