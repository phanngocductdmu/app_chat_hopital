import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  final void Function(String generatedPassword) onPasswordSelected;

  const PasswordGeneratorScreen({super.key, required this.onPasswordSelected});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _generatedPassword = '';
  double _passwordLength = 8;
  bool _includeNumbers = true;
  bool _includeLower = true;
  bool _includeUpper = true;
  bool _includeSpecial = true;
  bool _obscurePassword = true;

  bool _copied = false;
  bool _confirmSaved = false;

  void _generatePassword() {
    const numbers = '0123456789';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const special = '@#\$%^&*!()_+-={}[]<>?/';

    String chars = '';
    if (_includeNumbers) chars += numbers;
    if (_includeLower) chars += lower;
    if (_includeUpper) chars += upper;
    if (_includeSpecial) chars += special;

    if (chars.isEmpty) {
      setState(() => _generatedPassword = '');
      return;
    }

    final rand = Random.secure();
    final password = List.generate(
      _passwordLength.toInt(),
          (_) => chars[rand.nextInt(chars.length)],
    ).join();

    setState(() {
      _generatedPassword = password;
      _copied = false;
      _confirmSaved = false;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword)).then((_) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã sao chép mật khẩu")),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo mật khẩu", style: TextStyle(color: Colors.white)),
        backgroundColor: isDark ? Colors.black : const Color(0xFF0077BB),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                readOnly: true,
                obscureText: _obscurePassword,
                controller: TextEditingController(text: _generatedPassword),
                cursorColor: const Color(0xFF0077BB),
                style: const TextStyle(color: Color(0xFF0077BB)),
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  labelStyle: const TextStyle(color: Color(0xFF0077BB)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0077BB), width: 2),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0077BB)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF0077BB),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text("Số lượng ký tự:"),
                  Expanded(
                    child: Slider(
                      value: _passwordLength,
                      min: 8,
                      max: 32,
                      divisions: 24,
                      label: _passwordLength.round().toString(),
                      activeColor: const Color(0xFF0077BB),
                      onChanged: (value) {
                        setState(() => _passwordLength = value);
                      },
                      onChangeEnd: (_) => _generatePassword(),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                value: _passwordLength.round() == 8,
                title: const Text("Có 8 ký tự"),
                onChanged: null,
              ),
              CheckboxListTile(
                value: _includeNumbers,
                onChanged: (val) {
                  setState(() {
                    _includeNumbers = val!;
                    _generatePassword();
                  });
                },
                title: const Text("Có ký tự số"),
                activeColor: const Color(0xFF0077BB),
              ),
              CheckboxListTile(
                value: _includeLower,
                onChanged: (val) {
                  setState(() {
                    _includeLower = val!;
                    _generatePassword();
                  });
                },
                title: const Text("Có ký tự thường"),
                activeColor: const Color(0xFF0077BB),
              ),
              CheckboxListTile(
                value: _includeUpper,
                onChanged: (val) {
                  setState(() {
                    _includeUpper = val!;
                    _generatePassword();
                  });
                },
                title: const Text("Có ký tự hoa"),
                activeColor: const Color(0xFF0077BB),
              ),
              CheckboxListTile(
                value: _includeSpecial,
                onChanged: (val) {
                  setState(() {
                    _includeSpecial = val!;
                    _generatePassword();
                  });
                },
                title: const Text("Có ký tự đặc biệt"),
                activeColor: const Color(0xFF0077BB),
              ),
              SizedBox(height: 15),
              CheckboxListTile(
                value: _confirmSaved,
                onChanged: (val) {
                  if (!_copied) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Vui lòng sao chép mật khẩu trước khi xác nhận đã lưu."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _confirmSaved = val!;
                  });

                  if (val == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Bạn đã lưu mật khẩu mới."),
                        backgroundColor: Color(0xFF0077BB),
                      ),
                    );
                  }
                },
                title: const Text("Tôi đã lưu lại mật khẩu mới"),
                activeColor: const Color(0xFF0077BB),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _generatedPassword.isNotEmpty ? _copyToClipboard : null,
                    icon: Icon(
                      _copied ? Icons.check_circle : Icons.copy,
                      color: Colors.white,
                    ),
                    label: Text(
                      _copied ? "Đã sao chép" : "Sao chép",
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _copied ? Colors.green : const Color(0xFF0077BB),
                    ),
                  ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _copied && _confirmSaved
                          ? () {
                        widget.onPasswordSelected(_generatedPassword);
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _copied && _confirmSaved
                            ? const Color(0xFF0077BB)
                            : Colors.grey,
                      ),
                      child: const Text("Xác nhận", style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}