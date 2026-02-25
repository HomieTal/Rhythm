import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'equalizer_provider.dart';

class EqualizerPage extends StatefulWidget {
  const EqualizerPage({super.key});

  @override
  State<EqualizerPage> createState() => _EqualizerPageState();
}

class _EqualizerPageState extends State<EqualizerPage> {
  String _selectedPreset = 'Custom';

  static const bandLabels = ['60 hz', '230 hz', '910 hz', '4 khz', '14 khz'];

  // simple presets map
  static const Map<String, List<double>> _presets = {
    'Normal': [0, 0, 0, 0, 0],
    'Classical': [2, 1, 0, -1, -2],
    'Dance': [4, 2, 0, 2, 4],
    'Flat': [0, 0, 0, 0, 0],
    'Folk': [3, 1, 0, 1, 3],
    'Heavy Metal': [6, 3, 0, 3, 6],
  };

  @override
  void initState() {
    super.initState();
    // detect which preset (if any) matches saved gains
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eq = Provider.of<EqualizerProvider>(context, listen: false);
      final gains = eq.gains;
      final matched = _detectPreset(gains);
      if (matched != null && mounted) {
        setState(() => _selectedPreset = matched);
      }
    });
  }

  String? _detectPreset(List<double> gains) {
    for (final entry in _presets.entries) {
      final preset = entry.value;
      var matches = true;
      for (var i = 0; i < preset.length && i < gains.length; i++) {
        if (preset[i].toStringAsFixed(2) != gains[i].toStringAsFixed(2)) {
          matches = false;
          break;
        }
      }
      if (matches) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121216) : const Color(0xFFF5F5F5);
    final card = isDark ? const Color(0xFF1B1B1F) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final eqProvider = Provider.of<EqualizerProvider>(context);
    final enabled = eqProvider.enabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        elevation: 0,
      ),
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Enabled switch + Reset
              Consumer<EqualizerProvider>(
                builder: (context, eq, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.equalizer, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text('Equalizer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: eq.enabled ? () async { await eq.resetAll(); } : null,
                            icon: Icon(
                              Icons.restart_alt_rounded,
                              color: eq.enabled ? (isDark ? Colors.white70 : Colors.black54) : (isDark ? Colors.white24 : Colors.black26),
                            ),
                          ),
                          Switch(
                            value: eq.enabled,
                            onChanged: (v) async {
                              await eq.setEnabled(v);
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Top band area (greyed & non-interactive when disabled)
              Opacity(
                opacity: enabled ? 1.0 : 0.45,
                child: AbsorbPointer(
                  absorbing: !enabled,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        // Vertical bands
                        SizedBox(
                          height: 300,
                          child: Consumer<EqualizerProvider>(
                            builder: (context, eq, child) {
                              final gains = eq.gains;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(gains.length, (i) => _buildBand(context, i, gains[i])),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Preset chips
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _presetChip(context, 'Custom'),
                              ..._presets.keys.map((k) => _presetChip(context, k)),
                            ].map((w) => Padding(padding: const EdgeInsets.only(right: 8), child: w)).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Normalize audio row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.tune, size: 22, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Normalize audio', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Normalizes volume by reading the replay gain tag or the info provided by youtube',
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Default', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                                const SizedBox(height: 2),
                                Text('(Loudness Enhancer)', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom controls area (greyed & non-interactive when disabled)
              Opacity(
                opacity: enabled ? 1.0 : 0.45,
                child: AbsorbPointer(
                  absorbing: !enabled,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _buildControlConsumerRow(
                          context,
                          label: 'Loudness Enhancer (PreAmp)',
                          valueGetter: (eq) => eq.preamp,
                          defaultValue: 0.0,
                          min: -12.0,
                          max: 12.0,
                          format: (v) => '${v.toStringAsFixed(1)}dB',
                          setter: (eq, v) => eq.setPreamp(v),
                        ),
                        const SizedBox(height: 12),
                        _buildControlConsumerRow(
                          context,
                          label: 'Pitch',
                          valueGetter: (eq) => eq.pitch,
                          defaultValue: 1.0,
                          min: 0.5,
                          max: 2.0,
                          format: (v) => '${(v * 100).toStringAsFixed(0)}%',
                          setter: (eq, v) => eq.setPitch(v),
                        ),
                        const SizedBox(height: 12),
                        _buildControlConsumerRow(
                          context,
                          label: 'Speed',
                          valueGetter: (eq) => eq.speed,
                          defaultValue: 1.0,
                          min: 0.5,
                          max: 2.0,
                          format: (v) => '${v.toStringAsFixed(2)}x',
                          setter: (eq, v) => eq.setSpeed(v),
                        ),
                        const SizedBox(height: 12),
                        // Volume with mute/unmute button
                        Consumer<EqualizerProvider>(
                          builder: (context, eq, child) {
                            final isMuted = eq.muted;
                            final val = eq.volume;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('Volume', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                    ),
                                    IconButton(
                                      tooltip: isMuted ? 'Unmute' : 'Mute',
                                      onPressed: () => eq.toggleMute(),
                                      icon: Icon(isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: isDark ? Colors.white70 : Colors.black54),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: val,
                                        min: 0.0,
                                        max: 1.5,
                                        onChanged: (v) async {
                                          // if muted, unmute on manual slider change
                                          if (eq.muted) await eq.setMuted(false);
                                          await eq.setVolume(v);
                                        },
                                        activeColor: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('${(val * 100).toStringAsFixed(0)}%', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBand(BuildContext context, int index, double value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    // value range -15..15
    final display = value >= 0 ? '+${value.toStringAsFixed(2)}' : value.toStringAsFixed(2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // caret icon (small)
        const SizedBox(height: 6),
        Text(display, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        // vertical slider
        RotatedBox(
          quarterTurns: -1,
          child: SizedBox(
            width: 220,
            child: Consumer<EqualizerProvider>(
              builder: (context, eq, child) {
                final v = eq.gainAt(index);
                return SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: primary,
                    inactiveTrackColor: primary.withAlpha(60),
                  ),
                  child: Slider(
                    value: v,
                    min: -15.0,
                    max: 15.0,
                    divisions: 30,
                    onChanged: (val) async {
                      // user adjusted: mark as custom preset
                      if (mounted) setState(() => _selectedPreset = 'Custom');
                      await Provider.of<EqualizerProvider>(context, listen: false).setGain(index, val);
                    },
                    ),
                  );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // frequency label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(bandLabels[index], style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _presetChip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedPreset == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) async {
        if (!sel) return;
        if (label == 'Custom') {
          setState(() => _selectedPreset = 'Custom');
          return;
        }
        final preset = _presets[label];
        if (preset != null) {
          await Provider.of<EqualizerProvider>(context, listen: false).setAllGains(preset);
          if (mounted) setState(() => _selectedPreset = label);
        }
      },
      selectedColor: Theme.of(context).primaryColor.withAlpha(180),
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEFEFEF),
      labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _buildControlConsumerRow(
    BuildContext context, {
    required String label,
    required double Function(EqualizerProvider) valueGetter,
    required double defaultValue,
    required double min,
    required double max,
    required String Function(double) format,
    required Future<void> Function(EqualizerProvider, double) setter,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    return Consumer<EqualizerProvider>(
      builder: (context, eq, child) {
        final val = valueGetter(eq);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                ),
                IconButton(
                  onPressed: () async {
                    await setter(eq, defaultValue);
                  },
                  icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: val,
                    min: min,
                    max: max,
                    onChanged: (v) async {
                      await setter(eq, v);
                    },
                    activeColor: primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(format(val), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
