import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

typedef SetSidesCallback = void Function(num a, num b, num c);

class TriangleForm extends StatefulWidget {
  final SetSidesCallback onSetSides;

  const TriangleForm({super.key, required this.onSetSides});

  @override
  State<TriangleForm> createState() => _TriangleFormState();
}

class _TriangleFormState extends State<TriangleForm> {
  final TextEditingController _aCtrl = TextEditingController();
  final TextEditingController _bCtrl = TextEditingController();
  final TextEditingController _cCtrl = TextEditingController();

  String? _errA;
  String? _errB;
  String? _errC;

  // ---------- validation helpers ----------

  String? _validateInt(String value) {
    // trim whitespace
    final v = value.trim();

    if (v.isEmpty) {
      return 'Required';
    }

    // int.tryParse rejects decimals like "3.5" and junk like "abc".
    final parsed = double.tryParse(v);
    if (parsed == null) {
      return 'Must be a number';
    }

    if (parsed <= 0) {
      return 'Must be > 0';
    }

    return null; // null means "no error"
  }

  void _validateAllFields() {
    setState(() {
      _errA = _validateInt(_aCtrl.text);
      _errB = _validateInt(_bCtrl.text);
      _errC = _validateInt(_cCtrl.text);
    });
  }

  bool get _allValid {
    return _errA == null && _errB == null && _errC == null;
  }

  // ---------- submit ----------

  void _submit() {
    // First, run validation
    _validateAllFields();

    if (!_allValid) {
      // Don't submit garbage.
      return;
    }

    // Safe to parse now, because allValid guarantees int.tryParse succeeded
    final a = double.parse(_aCtrl.text.trim());
    final b = double.parse(_bCtrl.text.trim());
    final c = double.parse(_cCtrl.text.trim());

    widget.onSetSides(a, b, c);
  }

  // ---------- build helpers ----------

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String? errorText,
    required void Function(String) onChanged,
  }) {
    final baseTextStyle = CupertinoTheme.of(context).textTheme.textStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: baseTextStyle),
        const SizedBox(height: 4),
        CupertinoTextField(
          padding: const EdgeInsets.all(12),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: false,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d{0,9}([.]\d{0,6})?$'),
            ),
          ],
          textInputAction: TextInputAction.next,
          // We manually validate on every change
          onChanged: onChanged,
          placeholder: 'Enter $label',
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: baseTextStyle.copyWith(
              color: CupertinoColors.systemRed,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // keep it natural height, don't try to fill screen
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          label: 'Side A',
          controller: _aCtrl,
          errorText: _errA,
          onChanged: (val) {
            setState(() {
              _errA = _validateInt(val);
            });
          },
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Side B',
          controller: _bCtrl,
          errorText: _errB,
          onChanged: (val) {
            setState(() {
              _errB = _validateInt(val);
            });
          },
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Side C',
          controller: _cCtrl,
          errorText: _errC,
          onChanged: (val) {
            setState(() {
              _errC = _validateInt(val);
            });
          },
        ),
        const SizedBox(height: 24),
        CupertinoButton.filled(
          // we still let the user tap it, but _submit() will refuse if invalid
          onPressed: _submit,
          child: const Text('Check'),
        ),
      ],
    );
  }
}
