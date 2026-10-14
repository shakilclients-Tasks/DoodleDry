import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/core/utils/date_formatter.dart';
import 'package:doodledry/features/baby_profile/data/models/baby_profile_model.dart';
import 'package:doodledry/features/baby_profile/presentation/providers/baby_profile_provider.dart';
import 'package:doodledry/shared/widgets/custom_button.dart';
import 'package:doodledry/shared/widgets/custom_text_field.dart';

class BabyProfileScreen extends ConsumerStatefulWidget {
  const BabyProfileScreen({super.key});

  @override
  ConsumerState<BabyProfileScreen> createState() => _BabyProfileScreenState();
}

class _BabyProfileScreenState extends ConsumerState<BabyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _babyNameCtrl;
  late TextEditingController _caregiverNameCtrl;
  late TextEditingController _relationshipCtrl;
  late TextEditingController _emergencyContactCtrl;
  late DateTime _dob;
  String _gender = 'Female';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentBabyProfileProvider).value ?? BabyProfileModel.demo();
    _babyNameCtrl = TextEditingController(text: profile.name);
    _caregiverNameCtrl = TextEditingController(text: profile.caregiverName);
    _relationshipCtrl = TextEditingController(text: profile.relationship);
    _emergencyContactCtrl = TextEditingController(text: profile.emergencyContact);
    _dob = profile.dateOfBirth;
    _gender = profile.gender ?? 'Female';
  }

  @override
  void dispose() {
    _babyNameCtrl.dispose();
    _caregiverNameCtrl.dispose();
    _relationshipCtrl.dispose();
    _emergencyContactCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final updated = BabyProfileModel(
        id: 'baby_001',
        name: _babyNameCtrl.text.trim(),
        dateOfBirth: _dob,
        gender: _gender,
        caregiverName: _caregiverNameCtrl.text.trim(),
        relationship: _relationshipCtrl.text.trim(),
        emergencyContact: _emergencyContactCtrl.text.trim(),
        assignedDeviceId: 'DOODLEDRY-001',
      );
      ref.read(babyProfileRepositoryProvider).saveProfile(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Baby profile updated successfully."),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Baby Profile',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Icon(
                          Icons.child_care_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Smart Wearable Linked: DOODLEDRY-001",
                        style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Baby Info Section
                Text(
                  "BABY INFORMATION",
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: "Baby Name",
                  controller: _babyNameCtrl,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? "Please enter baby name" : null,
                ),
                const SizedBox(height: 14),

                // Date of birth picker field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Date of Birth",
                      style: AppTextStyles.titleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDob,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppDateFormatter.formatDate(_dob),
                              style: AppTextStyles.bodyMedium,
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Gender selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Gender",
                      style: AppTextStyles.titleSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Female"),
                            selected: _gender == 'Female',
                            onSelected: (v) => setState(() => _gender = 'Female'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Male"),
                            selected: _gender == 'Male',
                            onSelected: (v) => setState(() => _gender = 'Male'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Caregiver Info Section
                Text(
                  "CAREGIVER & EMERGENCY",
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: "Parent / Caregiver Name",
                  controller: _caregiverNameCtrl,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: "Relationship",
                  hint: "e.g. Mother, Father, Guardian",
                  controller: _relationshipCtrl,
                  prefixIcon: Icons.family_restroom_rounded,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: "Emergency Contact Phone",
                  controller: _emergencyContactCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 24),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Text(
                    "Medical Notice: DOODLEDRY does not provide medical diagnoses. Abnormal vital notifications are intended as an alerting aid for caregivers.",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                CustomButton(
                  text: "Save Baby Profile",
                  variant: CustomButtonVariant.primary,
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
