import 'package:flutter/material.dart';
import 'package:shurokkha/core/localization/l10n/app_localizations.dart';
import 'package:shurokkha/core/storage/secure_storage.dart';

class CalculatorDisguiseScreen extends StatefulWidget {
  final Widget child; // The actual home / login screen to reveal

  const CalculatorDisguiseScreen({
    super.key,
    required this.child,
  });

  @override
  State<CalculatorDisguiseScreen> createState() => _CalculatorDisguiseScreenState();
}

class _CalculatorDisguiseScreenState extends State<CalculatorDisguiseScreen> {
  String _display = '';
  String _inputBuffer = '';
  String _secretCode = '9876'; // Default fallback secret code
  bool _unlocked = false;
  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _loadSecretPin();
  }

  Future<void> _loadSecretPin() async {
    try {
      final pin = await _secureStorage.read('disguise_pin');
      if (pin != null && pin.isNotEmpty) {
        setState(() {
          _secretCode = pin;
        });
      }
    } catch (e) {
      debugPrint("Failed to read PIN from secure storage: $e");
    }
  }

  void _onKeyPress(String value) {
    if (value == 'C') {
      setState(() {
        _display = '';
        _inputBuffer = '';
      });
    } else if (value == '=') {
      if (_inputBuffer == _secretCode) {
        setState(() {
          _unlocked = true;
        });
      } else {
        setState(() {
          _display = _evaluateExpression(_display);
          _inputBuffer = '';
        });
      }
    } else if ('+-*/'.contains(value)) {
      setState(() {
        _display += value;
        _inputBuffer = ''; // Reset PIN buffer upon operator press
      });
    } else if (value == '.') {
      setState(() {
        _display += value;
        // Don't add decimal to inputBuffer to keep it pure digit-only for PIN
      });
    } else {
      setState(() {
        _display += value;
        _inputBuffer += value;
      });
    }
  }

  String _evaluateExpression(String expr) {
    try {
      String cleaned = expr.replaceAll(' ', '');
      if (cleaned.isEmpty) return '';

      final tokens = <dynamic>[];
      String numberBuffer = '';

      for (int i = 0; i < cleaned.length; i++) {
        final char = cleaned[i];
        if ('0123456789.'.contains(char)) {
          numberBuffer += char;
        } else if ('+-*/'.contains(char)) {
          if (numberBuffer.isNotEmpty) {
            tokens.add(double.parse(numberBuffer));
            numberBuffer = '';
          } else {
            // Handle negative numbers at the beginning or after another operator
            if (char == '-' && (tokens.isEmpty || tokens.last is String)) {
              numberBuffer = '-';
              continue;
            }
          }
          tokens.add(char);
        } else {
          throw Exception('Invalid character');
        }
      }
      if (numberBuffer.isNotEmpty) {
        if (numberBuffer == '-') {
          throw Exception('Invalid trailing minus');
        }
        tokens.add(double.parse(numberBuffer));
      }

      if (tokens.isEmpty) return '0';

      // First pass: multiplication and division
      final firstPass = <dynamic>[];
      int i = 0;
      while (i < tokens.length) {
        final token = tokens[i];
        if (token == '*' || token == '/') {
          if (firstPass.isEmpty || i + 1 >= tokens.length) {
            throw Exception('Invalid syntax');
          }
          final prev = firstPass.removeLast() as double;
          final next = tokens[i + 1];
          if (next is! double) {
            throw Exception('Invalid syntax');
          }
          if (token == '*') {
            firstPass.add(prev * next);
          } else {
            if (next == 0.0) {
              return 'Error';
            }
            firstPass.add(prev / next);
          }
          i += 2;
        } else {
          firstPass.add(token);
          i++;
        }
      }

      if (firstPass.isEmpty) return '0';
      if (firstPass.first is! double) {
        throw Exception('Invalid syntax');
      }

      // Second pass: addition and subtraction
      double result = firstPass[0] as double;
      int j = 1;
      while (j < firstPass.length) {
        final op = firstPass[j];
        if (op is! String || j + 1 >= firstPass.length) {
          throw Exception('Invalid syntax');
        }
        final val = firstPass[j + 1];
        if (val is! double) {
          throw Exception('Invalid syntax');
        }
        if (op == '+') {
          result += val;
        } else if (op == '-') {
          result -= val;
        } else {
          throw Exception('Invalid operator');
        }
        j += 2;
      }

      if (result == result.toInt()) {
        return result.toInt().toString();
      } else {
        String formatted = result.toStringAsFixed(6);
        while (formatted.endsWith('0')) {
          formatted = formatted.substring(0, formatted.length - 1);
        }
        if (formatted.endsWith('.')) {
          formatted = formatted.substring(0, formatted.length - 1);
        }
        return formatted;
      }
    } catch (e) {
      return 'Error';
    }
  }

  Widget _buildButton(String text, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey.shade300,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => _onKeyPress(text),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      return widget.child;
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.calculatorTitle),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Text(
                _display.isEmpty ? '0' : _display,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _buildButton('7'),
                  _buildButton('8'),
                  _buildButton('9'),
                  _buildButton('/', color: Colors.orange.shade300),
                ],
              ),
              Row(
                children: [
                  _buildButton('4'),
                  _buildButton('5'),
                  _buildButton('6'),
                  _buildButton('*', color: Colors.orange.shade300),
                ],
              ),
              Row(
                children: [
                  _buildButton('1'),
                  _buildButton('2'),
                  _buildButton('3'),
                  _buildButton('-', color: Colors.orange.shade300),
                ],
              ),
              Row(
                children: [
                  _buildButton('C', color: Colors.red.shade200),
                  _buildButton('0'),
                  _buildButton('.'),
                  _buildButton('+', color: Colors.orange.shade300),
                ],
              ),
              Row(
                children: [
                  _buildButton('=', color: Colors.orange.shade400),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
