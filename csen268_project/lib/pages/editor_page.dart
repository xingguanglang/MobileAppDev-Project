import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';

enum EditorTab { clip, rotate, adjust }

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  // Aspect ratio for preview (visual only, not actual cropping)
  double _aspectW = 16, _aspectH = 9;

  // Adjustment parameters
  double _rotationDeg = 0;  // -180 ~ 180
  double _brightness = 0;   // -1 ~ 1
  double _contrast = 1;     //  0 ~ 2
  double _saturation = 1;   //  0 ~ 2
  double _temperature = 0;  // -1 ~ 1 (cold→warm)

  File? _imageFile;
  EditorTab _tab = EditorTab.adjust;

  bool _isBusy = false; // prevent repeated dialogs

  static const Color kGreen = Color(0xFF4BAE61);
  static const double kRadius = 16;

  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF7FAF7);
    final card = isDark ? const Color(0xFF171B20) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Editor'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === Preview area ===
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kRadius),
                  child: Container(
                    color: isDark ? const Color(0xFF1B1F24) : const Color(0xFFEFF3EF),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _aspectW / _aspectH,
                        child: _buildPreview(isDark),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // === Bottom controls ===
            _BottomControls(
              tab: _tab,
              onTabChanged: (t) async {
                if (t == EditorTab.clip) {
                  await _ensureImageThenCrop(); // don’t switch tabs
                } else {
                  setState(() => _tab = t);
                }
              },

              // rotate
              rotation: _rotationDeg,
              onRotation: (v) => setState(() => _rotationDeg = v),

              // adjust
              brightness: _brightness,
              contrast: _contrast,
              saturation: _saturation,
              temperature: _temperature,
              onBrightness: (v) => setState(() => _brightness = v),
              onContrast:   (v) => setState(() => _contrast = v),
              onSaturation: (v) => setState(() => _saturation = v),
              onTemperature:(v) => setState(() => _temperature = v),

              // import/export
              onImport: _importImage,
              onExport: () => context.go('/export'),
              background: card,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Image Preview ----------
  Widget _buildPreview(bool isDark) {
    final double c = _contrast;
    final double b = _brightness;
    final double offset = 128.0 * (1.0 - c) + 255.0 * b;

    List<double> m = <double>[
      c, 0, 0, 0, offset,
      0, c, 0, 0, offset,
      0, 0, c, 0, offset,
      0, 0, 0, 1,     0,
    ];

    // Saturation
    final double s = _saturation;
    const double lumR = 0.3086, lumG = 0.6094, lumB = 0.0820;
    final double oneMinusSat = 1 - s;
    final List<double> sat = <double>[
      lumR * oneMinusSat + s, lumG * oneMinusSat,       lumB * oneMinusSat,       0.0, 0.0,
      lumR * oneMinusSat,      lumG * oneMinusSat + s,  lumB * oneMinusSat,       0.0, 0.0,
      lumR * oneMinusSat,      lumG * oneMinusSat,      lumB * oneMinusSat + s,   0.0, 0.0,
      0.0,                     0.0,                     0.0,                      1.0, 0.0,
    ];
    m = _mul(sat, m);

    // Temperature
    final double temp = _temperature.clamp(-1.0, 1.0);
    final double warm = 0.25 * temp;
    final double cool = -0.25 * temp;
    final List<double> tempM = <double>[
      1.0 + warm, 0.0,        0.0,        0.0, 0.0,
      0.0,        1.0,        0.0,        0.0, 0.0,
      0.0,        0.0,        1.0 + cool, 0.0, 0.0,
      0.0,        0.0,        0.0,        1.0, 0.0,
    ];
    m = _mul(tempM, m);

    final double radians = _rotationDeg * math.pi / 180.0;

    Widget content = _imageFile != null
        ? Image.file(_imageFile!, fit: BoxFit.contain)
        : Center(child: Icon(Icons.image_outlined, size: 72, color: isDark ? Colors.white70 : Colors.black54));

    return Transform.rotate(
      angle: radians,
      child: ColorFiltered(colorFilter: ColorFilter.matrix(m), child: content),
    );
  }

  // multiply color matrices
  List<double> _mul(List<double> a, List<double> b) {
    final List<double> out = List<double>.filled(20, 0.0);
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 5; c++) {
        out[r * 5 + c] =
            b[r * 5 + 0] * a[0 + c] +
            b[r * 5 + 1] * a[5 + c] +
            b[r * 5 + 2] * a[10 + c] +
            b[r * 5 + 3] * a[15 + c] +
            (c == 4 ? b[r * 5 + 4] : 0.0);
      }
    }
    return out;
  }

  // ---------- Import & Crop ----------
  Future<void> _importImage() async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      debugPrint('Import error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Import failed.')));
      }
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _ensureImageThenCrop() async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      if (_imageFile == null) {
        final goImport = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            title: const Text('No image selected'),
            content: const Text('Please import an image before cropping.'),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: kGreen),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Import'),
              ),
            ],
          ),
        );
        if (goImport == true) {
          await _importImage();
          if (_imageFile != null) {
            await _openFreeCrop();
          }
        }
      } else {
        await _openFreeCrop();
      }
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _openFreeCrop() async {
    final file = _imageFile;
    if (file == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          toolbarColor: Colors.white,
          toolbarWidgetColor: Colors.black87,
          lockAspectRatio: false,
          hideBottomControls: false,
          activeControlsWidgetColor: kGreen,
        ),
        IOSUiSettings(
          title: 'Crop',
          aspectRatioLockEnabled: false,
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: true,
          rotateButtonsHidden: false,
        ),
      ],
      aspectRatio: null,
    );

    if (cropped != null) {
      setState(() => _imageFile = File(cropped.path));
    }
  }
}

// ---------- Bottom control section ----------
class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.tab,
    required this.onTabChanged,
    required this.rotation,
    required this.onRotation,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.temperature,
    required this.onBrightness,
    required this.onContrast,
    required this.onSaturation,
    required this.onTemperature,
    required this.onImport,
    required this.onExport,
    required this.background,
  });

  final EditorTab tab;
  final ValueChanged<EditorTab> onTabChanged;

  final double rotation;
  final ValueChanged<double> onRotation;

  final double brightness, contrast, saturation, temperature;
  final ValueChanged<double> onBrightness, onContrast, onSaturation, onTemperature;

  final VoidCallback onImport, onExport;
  final Color background;

  static const double kRadius = _EditorPageState.kRadius;
  static const Color kGreen = _EditorPageState.kGreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SegmentedTabs(current: tab, onChanged: onTabChanged),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(kRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _buildToolPanel(theme),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _FilledButton(text: 'Import', icon: Icons.download_outlined, onPressed: onImport),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilledButton(
                    text: 'Export',
                    icon: Icons.upload_outlined,
                    filledColor: kGreen,
                    textColor: Colors.white,
                    onPressed: onExport,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolPanel(ThemeData theme) {
  switch (tab) {
    case EditorTab.clip:
      return Center(
        child: Text(
          'Use "Clip" above to open free cropping.',
          style: theme.textTheme.bodyMedium,
        ),
      );

    case EditorTab.rotate:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rotate', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Row(
            children: [
              IconButton(
                onPressed: () => onRotation(((rotation - 90.0).clamp(-180.0, 180.0)).toDouble()),
                icon: const Icon(Icons.rotate_left),
              ),
              Expanded(
                child: Slider(value: rotation, min: -180.0, max: 180.0, onChanged: (v) => onRotation(v)),
              ),
              IconButton(
                onPressed: () => onRotation(((rotation + 90.0).clamp(-180.0, 180.0)).toDouble()),
                icon: const Icon(Icons.rotate_right),
              ),
            ],
          ),
        ],
      );

    case EditorTab.adjust:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Title row: "Adjust" + Reset button ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adjust',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () {
                  // Reset all adjustments to defaults
                  onBrightness(0.0);
                  onContrast(1.0);
                  onSaturation(1.0);
                  onTemperature(0.0);
                },
                style: TextButton.styleFrom(
                  foregroundColor: _EditorPageState.kGreen,
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // === Sliders ===
          _LabeledSlider(label: 'Brightness', value: brightness,  min: -1.0, max: 1.0, onChanged: onBrightness),
          _LabeledSlider(label: 'Contrast',   value: contrast,    min: 0.0,  max: 2.0, onChanged: onContrast),
          _LabeledSlider(label: 'Saturation', value: saturation,  min: 0.0,  max: 2.0, onChanged: onSaturation),
          _LabeledSlider(label: 'Temperature',value: temperature, min: -1.0, max: 1.0, onChanged: onTemperature),
        ],
      );
  }
}

}

// ---------- Common small widgets ----------
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.current, required this.onChanged});
  final EditorTab current;
  final ValueChanged<EditorTab> onChanged;
  static const Color kGreen = _EditorPageState.kGreen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF171B20) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _btn('Clip', EditorTab.clip),
          _btn('Rotate', EditorTab.rotate),
          _btn('Adjust', EditorTab.adjust),
        ],
      ),
    );
  }

  Expanded _btn(String label, EditorTab tab) {
    final sel = current == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? kGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sel ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      children: [
        SizedBox(width: 96, child: Text(label, style: t.textTheme.bodyMedium)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.end,
            style: t.textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

class _FilledButton extends StatelessWidget {
  const _FilledButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.filledColor,
    this.textColor,
  });

  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? filledColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = filledColor ?? const Color(0xFFEFF3EF);
    final fg = textColor ?? Colors.black87;
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
