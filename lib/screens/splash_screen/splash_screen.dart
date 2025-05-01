// lib/src/screens/splash_screen.dart
import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _checkLoginStatus();
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (token != null) {
      bool isTokenExpired = JwtDecoder.isExpired(token);

      if (isTokenExpired) {
        // Token expired, arahkan ke login dan hapus token
        await prefs.remove('token');
        await prefs.remove('role');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }
    }

    if (mounted) {
      if (token != null && role == 'KARYAWAN') {
        Navigator.of(context).pushReplacementNamed('/home-screen');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.backgroundColor,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Logo_green.png',
                  width: 400,
                  height: 400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
