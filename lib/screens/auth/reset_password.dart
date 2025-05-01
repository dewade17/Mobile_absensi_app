import 'dart:async';

import 'package:absensi_app/providers/get_token_provider.dart';
import 'package:absensi_app/providers/reset_password_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final formKey = GlobalKey<FormState>();
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool _canResend = true;
  int _timerSeconds = 0;

  void startCooldown() {
    setState(() {
      _canResend = false;
      _timerSeconds = 30;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timerSeconds--;
        if (_timerSeconds <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final getTokenProvider = Provider.of<GetTokenProvider>(context);
    final resetPasswordProvider = Provider.of<ResetPasswordProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(
                'assets/images/Reset_password.png',
                height: 250,
                width: 250,
              ),
              const SizedBox(height: 20),
              Text("Reset Password",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800)),
              const SizedBox(height: 20),
              Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 350,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey.shade600),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 0),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade400),
                                ),
                                child: TextFormField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    hintText: "masukan email",
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic),
                                    icon: Icon(Icons.alternate_email_rounded),
                                    border: InputBorder.none,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF92E3A9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: (getTokenProvider.isLoading ||
                                            !_canResend)
                                        ? null
                                        : () async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              await getTokenProvider
                                                  .sendResetCode(
                                                      emailController.text);
                                              startCooldown();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        getTokenProvider
                                                                .message ??
                                                            ''),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    child: getTokenProvider.isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : Text(_canResend
                                            ? 'Kirim Kode'
                                            : 'Tunggu $_timerSeconds detik'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 350,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Token",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade600),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: TextFormField(
                                controller: tokenController,
                                decoration: InputDecoration(
                                  hintText: "Token",
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic),
                                  icon: Icon(Icons.generating_tokens_outlined),
                                  border: InputBorder.none,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Token tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        width: 350,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password Baru",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade600),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: TextFormField(
                                controller: newPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: "Password Baru",
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic),
                                  icon: Icon(Icons.lock),
                                  border: InputBorder.none,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password Baru tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (resetPasswordProvider.isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF92E3A9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            await resetPasswordProvider.resetPassword(
                              tokenController.text.trim(),
                              newPasswordController.text.trim(),
                            );

                            final message = resetPasswordProvider.message;
                            if (message != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          }
                        },
                        child: const Text("Reset Password"),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: Text(
                  'Login',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
