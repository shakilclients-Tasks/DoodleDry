/// Baby Profile model representing the monitored infant
class BabyProfileModel {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String? gender; // 'Male', 'Female', 'Other'
  final String? photoUrl;
  final String caregiverName;
  final String relationship; // 'Mother', 'Father', 'Guardian', 'Nurse'
  final String emergencyContact;
  final String assignedDeviceId;
  final String? notes;

  const BabyProfileModel({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    this.gender = 'Female',
    this.photoUrl,
    required this.caregiverName,
    required this.relationship,
    required this.emergencyContact,
    this.assignedDeviceId = 'DOODLEDRY-001',
    this.notes,
  });

  /// Default demo infant profile for immediate testing
  factory BabyProfileModel.demo() {
    return BabyProfileModel(
      id: 'baby_leo_001',
      name: 'Leo',
      dateOfBirth: DateTime.now().subtract(const Duration(days: 120)), // 4 months old
      gender: 'Male',
      photoUrl: null,
      caregiverName: 'Sarah Jenkins',
      relationship: 'Mother',
      emergencyContact: '+1 (555) 987-6543',
      assignedDeviceId: 'DOODLEDRY-001',
      notes: 'Monitored with DOODLEDRY Smart Wearable',
    );
  }

  /// Calculates baby's age in months and days
  String get ageDisplay {
    final now = DateTime.now();
    int months = (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
    if (now.day < dateOfBirth.day) {
      months--;
    }
    if (months < 1) {
      final days = now.difference(dateOfBirth).inDays;
      return '$days days old';
    } else if (months == 1) {
      return '1 month old';
    } else {
      return '$months months old';
    }
  }

  factory BabyProfileModel.fromJson(Map<String, dynamic> json) {
    return BabyProfileModel(
      id: json['id'] as String? ?? 'baby_default',
      name: json['name'] as String? ?? 'Baby',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString()) ?? DateTime.now().subtract(const Duration(days: 90))
          : DateTime.now().subtract(const Duration(days: 90)),
      gender: json['gender'] as String? ?? 'Female',
      photoUrl: json['photoUrl'] as String?,
      caregiverName: json['caregiverName'] as String? ?? 'Parent',
      relationship: json['relationship'] as String? ?? 'Parent',
      emergencyContact: json['emergencyContact'] as String? ?? '',
      assignedDeviceId: json['assignedDeviceId'] as String? ?? 'DOODLEDRY-001',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'photoUrl': photoUrl,
      'caregiverName': caregiverName,
      'relationship': relationship,
      'emergencyContact': emergencyContact,
      'assignedDeviceId': assignedDeviceId,
      'notes': notes,
    };
  }

  BabyProfileModel copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    String? photoUrl,
    String? caregiverName,
    String? relationship,
    String? emergencyContact,
    String? assignedDeviceId,
    String? notes,
  }) {
    return BabyProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      caregiverName: caregiverName ?? this.caregiverName,
      relationship: relationship ?? this.relationship,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      assignedDeviceId: assignedDeviceId ?? this.assignedDeviceId,
      notes: notes ?? this.notes,
    );
  }
}
