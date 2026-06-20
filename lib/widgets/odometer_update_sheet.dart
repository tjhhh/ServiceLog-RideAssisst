import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/motorcycle.dart';

/// Shows the redesigned odometer update bottom sheet.
/// Returns the result (true if something was saved).
Future<bool?> showOdometerUpdateSheet(
  BuildContext context,
  Motorcycle motor, {
  required Future<void> Function(int newOdo) onSaveKm,
  required Future<void> Function(int newOdo) onSaveCycle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => OdometerUpdateSheet(
      motor: motor,
      onSaveKm: onSaveKm,
      onSaveCycle: onSaveCycle,
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
class OdometerUpdateSheet extends StatefulWidget {
  final Motorcycle motor;
  final Future<void> Function(int newOdo) onSaveKm;
  final Future<void> Function(int newOdo) onSaveCycle;

  const OdometerUpdateSheet({
    super.key,
    required this.motor,
    required this.onSaveKm,
    required this.onSaveCycle,
  });

  @override
  State<OdometerUpdateSheet> createState() => _OdometerUpdateSheetState();
}

class _OdometerUpdateSheetState extends State<OdometerUpdateSheet>
    with TickerProviderStateMixin {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  late final AnimationController _shakeCtrl;
  late final AnimationController _cycleExpandCtrl;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _cycleExpandAnim;

  String? _errorText;
  bool _isSaving = false;
  bool _cycleExpanded = false;
  int? _parsedValue;

  static const int _maxOdo = 99999;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.motor.odometer.toString());
    _focusNode = FocusNode();
    _parsedValue = widget.motor.odometer;

    // Shake animation for error / cycle warning
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    // Cycle section expand animation
    _cycleExpandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cycleExpandAnim = CurvedAnimation(
      parent: _cycleExpandCtrl,
      curve: Curves.easeOutCubic,
    );

    // Auto-focus the field after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _shakeCtrl.dispose();
    _cycleExpandCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    final parsed = int.tryParse(val);
    setState(() {
      _parsedValue = parsed;
      if (val.isEmpty) {
        _errorText = 'Masukkan nilai odometer';
      } else if (parsed == null) {
        _errorText = 'Hanya angka yang diperbolehkan';
      } else if (parsed < widget.motor.odometer) {
        _errorText =
            'Nilai harus ≥ ${widget.motor.odometer} KM. Gunakan Reset Cycle untuk mereset.';
      } else if (parsed > _maxOdo) {
        _errorText = 'Melebihi batas maksimal $_maxOdo KM';
      } else {
        _errorText = null;
      }
    });
  }

  Future<void> _saveKm() async {
    _onChanged(_ctrl.text);
    if (_errorText != null) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    setState(() => _isSaving = true);
    await widget.onSaveKm(_parsedValue!);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _saveCycle() async {
    final cycleOdo = int.tryParse(_ctrl.text) ?? 0;
    setState(() => _isSaving = true);
    await widget.onSaveCycle(cycleOdo);
    if (mounted) Navigator.pop(context, true);
  }

  void _toggleCycleSection() {
    setState(() => _cycleExpanded = !_cycleExpanded);
    if (_cycleExpanded) {
      _cycleExpandCtrl.forward();
      // Shake the cycle section to draw attention
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _shakeCtrl.forward(from: 0);
      });
    } else {
      _cycleExpandCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final odo = widget.motor.odometer;
    final delta = (_parsedValue != null && _parsedValue! > odo)
        ? _parsedValue! - odo
        : 0;
    final progressValue = (odo / _maxOdo).clamp(0.0, 1.0);
    final nearLimit = odo >= 89999;
    final maxSheetHeight = mediaQuery.size.height - mediaQuery.padding.top - 12;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.speed_rounded,
                              color: primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Update Odometer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                widget.motor.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Current ODO + Progress Bar ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Posisi saat ini: $odo KM',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(progressValue * 100).toStringAsFixed(0)}% dari $_maxOdo KM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nearLimit
                                      ? Colors.red
                                      : Colors.grey.shade500,
                                  fontWeight: nearLimit
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progressValue),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (_, value, __) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade100,
                                    color: nearLimit
                                        ? Colors.red
                                        : progressValue > 0.7
                                        ? Colors.orange
                                        : primary,
                                  ),
                            ),
                          ),
                          if (nearLimit) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Mendekati batas! Pertimbangkan Reset Cycle.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Input Field ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(_shakeAnim.value, 0),
                          child: child,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _errorText != null
                                          ? Colors.red.shade50
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _errorText != null
                                            ? Colors.red.shade300
                                            : Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _ctrl,
                                      focusNode: _focusNode,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(5),
                                      ],
                                      onChanged: _onChanged,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: _errorText != null
                                            ? Colors.red.shade700
                                            : const Color(0xFF0F172A),
                                      ),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 16,
                                            ),
                                        hintText: odo.toString(),
                                        hintStyle: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.grey.shade300,
                                        ),
                                        suffixText: 'KM',
                                        suffixStyle: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _errorText != null
                                              ? Colors.red.shade400
                                              : primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Delta badge
                                if (delta > 0) ...[
                                  const SizedBox(width: 12),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: primary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '+$delta',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: primary,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'KM',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: primary.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Inline error
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 200),
                              crossFadeState: _errorText != null
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              firstChild: Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 14,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _errorText ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              secondChild: const SizedBox(height: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Save KM button ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveKm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primary.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Simpan Odometer',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Cycle Reset Section (Collapsible) ─────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Toggle button
                          InkWell(
                            onTap: _toggleCycleSection,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _cycleExpanded
                                    ? Colors.red.shade50
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _cycleExpanded
                                      ? Colors.red.shade200
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _cycleExpanded
                                        ? Icons.warning_amber_rounded
                                        : Icons.refresh_rounded,
                                    size: 18,
                                    color: _cycleExpanded
                                        ? Colors.red.shade700
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _cycleExpanded
                                          ? 'Batalkan Reset Cycle'
                                          : 'Reset Odometer Cycle',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _cycleExpanded
                                            ? Colors.red.shade700
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _cycleExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: _cycleExpanded
                                          ? Colors.red.shade400
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Expandable content
                          SizeTransition(
                            sizeFactor: _cycleExpandAnim,
                            axis: Axis.vertical,
                            child: AnimatedBuilder(
                              animation: _shakeAnim,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(_shakeAnim.value, 0),
                                child: child,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              size: 16,
                                              color: Colors.red.shade700,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'AKSI TIDAK DAPAT DIBATALKAN',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Cycle akan bertambah dari ${widget.motor.cycle} → ${widget.motor.cycle + 1}.\nHistori servis cycle ini akan direset.\nOdometer field di atas digunakan sebagai nilai awal cycle baru (biasanya 0).',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade800,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // New cycle odo hint
                                        Text(
                                          'Odometer awal cycle baru: ${_ctrl.text.isEmpty ? "0" : _ctrl.text} KM',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: _isSaving
                                                ? null
                                                : _saveCycle,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade600,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            icon: const Icon(
                                              Icons.warning_amber_rounded,
                                              size: 18,
                                            ),
                                            label: Text(
                                              'Konfirmasi Reset ke Cycle ${widget.motor.cycle + 1}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
