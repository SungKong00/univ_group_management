import 'package:flutter/material.dart';

class Otp6Input extends StatefulWidget {
  final void Function(String code)? onCompleted;
  final bool enabled;

  const Otp6Input({super.key, this.onCompleted, this.enabled = true});

  @override
  State<Otp6Input> createState() => _Otp6InputState();
}

class _Otp6InputState extends State<Otp6Input> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Paste handling: distribute across boxes
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      _focusNextAvailable();
    } else if (value.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }

    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6 && widget.onCompleted != null) {
      widget.onCompleted!(code);
    }
  }

  void _focusNextAvailable() {
    for (int i = 0; i < 6; i++) {
      if (_controllers[i].text.isEmpty) {
        _nodes[i].requestFocus();
        return;
      }
    }
    _nodes.last.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 44,
          child: TextField(
            enabled: widget.enabled,
            controller: _controllers[i],
            focusNode: _nodes[i],
            maxLength: 1,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(counterText: ''),
            onChanged: (v) => _onChanged(i, v),
          ),
        );
      }),
    );
  }
}

