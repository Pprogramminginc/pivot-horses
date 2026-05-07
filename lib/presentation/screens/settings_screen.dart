import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  final AppSettings initialSettings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings = widget.initialSettings;

  void _updateSettings(AppSettings settings) {
    setState(() {
      _settings = settings;
    });
    widget.onSettingsChanged(settings);
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Close settings',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Audio',
              subtitle: 'Balance ambience and gameplay cues',
              child: Column(
                children: [
                  _SettingsSwitch(
                    icon: Icons.volume_up_rounded,
                    title: 'Audio',
                    subtitle: 'Allow all game audio',
                    value: settings.audioEnabled,
                    onChanged: (value) =>
                        _updateSettings(settings.copyWith(audioEnabled: value)),
                  ),
                  _SettingsSlider(
                    icon: Icons.tune_rounded,
                    title: 'Master volume',
                    value: settings.masterVolume,
                    enabled: settings.audioEnabled,
                    onChanged: (value) =>
                        _updateSettings(settings.copyWith(masterVolume: value)),
                  ),
                  _SettingsSwitch(
                    icon: Icons.ads_click_rounded,
                    title: 'Sound effects',
                    subtitle: 'Clicks, births, breeding, and support sends',
                    value: settings.effectsEnabled,
                    enabled: settings.audioEnabled,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(effectsEnabled: value),
                    ),
                  ),
                  _SettingsSlider(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Effects volume',
                    value: settings.effectsVolume,
                    enabled: settings.audioEnabled && settings.effectsEnabled,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(effectsVolume: value),
                    ),
                  ),
                  _SettingsSwitch(
                    icon: Icons.music_note_rounded,
                    title: 'Background audio',
                    subtitle: 'Soft ambience while browsing the stable',
                    value: settings.backgroundAudioEnabled,
                    enabled: settings.audioEnabled,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(backgroundAudioEnabled: value),
                    ),
                  ),
                  _SettingsSlider(
                    icon: Icons.surround_sound_rounded,
                    title: 'Background volume',
                    value: settings.backgroundVolume,
                    enabled:
                        settings.audioEnabled &&
                        settings.backgroundAudioEnabled,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(backgroundVolume: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Bell Alerts',
              subtitle: 'Choose which stable updates appear under the bell',
              child: Column(
                children: [
                  _SettingsSwitch(
                    icon: Icons.timer_rounded,
                    title: 'Breeding timer ending soon',
                    subtitle: 'Alert when an active pairing is close to ready',
                    value: settings.breedingTimerAlerts,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(breedingTimerAlerts: value),
                    ),
                  ),
                  _SettingsSwitch(
                    icon: Icons.child_friendly_rounded,
                    title: 'Foal waiting to be born',
                    subtitle: 'Alert when a pregnancy is ready to deliver',
                    value: settings.birthReadyAlerts,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(birthReadyAlerts: value),
                    ),
                  ),
                  _SettingsSwitch(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Birth timer ending soon',
                    subtitle: 'Alert shortly before a foal is due',
                    value: settings.pregnancyDueSoonAlerts,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(pregnancyDueSoonAlerts: value),
                    ),
                  ),
                  _SettingsSwitch(
                    icon: Icons.healing_rounded,
                    title: 'Mare healing almost complete',
                    subtitle: 'Alert near the end of a mare healing phase',
                    value: settings.healingCompleteAlerts,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(healingCompleteAlerts: value),
                    ),
                  ),
                  _SettingsSwitch(
                    icon: Icons.self_improvement_rounded,
                    title: 'Stallion recovery almost complete',
                    subtitle: 'Alert near the end of a recovery cooldown',
                    value: settings.recoveryCompleteAlerts,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(recoveryCompleteAlerts: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Feel',
              subtitle: 'Small preferences for everyday play',
              compact: true,
              child: Column(
                children: [
                  _SettingsSwitch(
                    icon: Icons.vibration_rounded,
                    title: 'Haptics',
                    subtitle: 'Light feedback on taps and settings changes',
                    value: settings.hapticsEnabled,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(hapticsEnabled: value),
                    ),
                  ),
                  _SettingsSwitch(
                    icon: Icons.view_agenda_rounded,
                    title: 'Compact horse cards',
                    subtitle: 'Reserved for denser roster views',
                    value: settings.compactHorseCards,
                    onChanged: (value) => _updateSettings(
                      settings.copyWith(compactHorseCards: value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: _SettingIcon(icon: icon, enabled: enabled),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: AppTheme.secondary,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  const _SettingsSlider({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = '${(value * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _SettingIcon(icon: icon, enabled: enabled),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      percent,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled ? AppTheme.secondary : AppTheme.mutedInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: value,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  activeColor: AppTheme.secondary,
                  inactiveColor: AppTheme.outline,
                  onChanged: enabled ? onChanged : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, required this.enabled});

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppTheme.secondary : AppTheme.mutedInk;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: enabled ? 0.16 : 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
