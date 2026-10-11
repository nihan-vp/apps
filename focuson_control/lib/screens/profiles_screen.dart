import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';

class ProfilesScreen extends StatefulWidget {
  final FocusDatabase db;

  const ProfilesScreen({super.key, required this.db});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  List<RestrictionProfile> _profiles = [];
  String? _activeProfileId;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    var profiles = await widget.db.controlRepo.getAllProfiles();
    if (profiles.isEmpty) {
      // Seed default profiles
      final study = RestrictionProfile(name: 'Study', type: ProfileType.study, defaultFocusMinutes: 45, isActive: true);
      final work = RestrictionProfile(name: 'Work', type: ProfileType.work, defaultFocusMinutes: 50);
      final gaming = RestrictionProfile(name: 'Gaming', type: ProfileType.gaming, defaultFocusMinutes: 60);
      final sleep = RestrictionProfile(name: 'Sleep', type: ProfileType.sleep, defaultFocusMinutes: 0, notificationMode: 'silent');

      await widget.db.controlRepo.insertProfile(study);
      await widget.db.controlRepo.insertProfile(work);
      await widget.db.controlRepo.insertProfile(gaming);
      await widget.db.controlRepo.insertProfile(sleep);

      profiles = await widget.db.controlRepo.getAllProfiles();
    }

    final active = await widget.db.controlRepo.getActiveProfile();

    if (mounted) {
      setState(() {
        _profiles = profiles;
        _activeProfileId = active?.id;
      });
    }
  }

  Future<void> _activateProfile(RestrictionProfile profile) async {
    await widget.db.controlRepo.setActiveProfile(profile.id);
    await _loadProfiles();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activated ${profile.name} Profile'),
          backgroundColor: FocusColors.emeraldGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: FocusSpacing.insetAllLg,
        children: [
          const FocusCard(
            padding: FocusSpacing.insetAllMd,
            child: Row(
              children: [
                Icon(Icons.tune, color: FocusColors.electricBlue, size: 22),
                SizedBox(width: FocusSpacing.md),
                Expanded(
                  child: Text(
                    'Profiles adjust app restrictions, focus defaults, and notification behavior simultaneously across the FocusON ecosystem. Switching profiles preserves your custom rules.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FocusSpacing.lg),

          const FocusSectionHeader(title: 'SYSTEM PROFILES'),
          ..._profiles.map((profile) {
            final isActive = profile.id == _activeProfileId;
            return Padding(
              padding: const EdgeInsets.only(bottom: FocusSpacing.sm),
              child: FocusCard(
                padding: FocusSpacing.insetAllMd,
                borderColor: isActive ? FocusColors.electricBlue : null,
                child: Row(
                  children: [
                    FocusProfileBadge(
                      type: profile.type,
                      isSelected: isActive,
                    ),
                    const SizedBox(width: FocusSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            '${profile.defaultFocusMinutes}m Focus Defaults • Mode: ${profile.notificationMode}',
                            style: const TextStyle(fontSize: 11, color: FocusColors.darkTextMuted),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FocusColors.electricBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(FocusSpacing.radiusPill),
                        ),
                        child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: FocusColors.electricBlue)),
                      )
                    else
                      FocusButton(
                        label: 'Activate',
                        height: 32,
                        variant: FocusButtonVariant.secondary,
                        onPressed: () => _activateProfile(profile),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
