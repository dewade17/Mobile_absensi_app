import 'package:absensi_app/providers/attendance_arrival.dart';
import 'package:absensi_app/providers/authprovider.dart';
import 'package:absensi_app/providers/encodeface_provider.dart';
import 'package:absensi_app/providers/face_provider.dart';
import 'package:absensi_app/providers/face_verification_provider.dart';
import 'package:absensi_app/providers/get_token_provider.dart';
import 'package:absensi_app/providers/location_provider.dart';
import 'package:absensi_app/providers/profile_provider.dart';
import 'package:absensi_app/providers/reset_password_provider.dart';
import 'package:absensi_app/screens/auth/login_screen.dart';
import 'package:absensi_app/screens/auth/reset_password.dart';
import 'package:absensi_app/screens/karyawan/home_screen.dart';
import 'package:absensi_app/screens/karyawan/menu_absensi/absensi_kedatangan.dart';
import 'package:absensi_app/screens/splash_screen/splash_screen.dart';
import 'package:absensi_app/services/auth_wrapper.dart';
import 'package:absensi_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        ChangeNotifierProvider(create: (context) => FaceProvider()),
        ChangeNotifierProvider(create: (context) => FaceEncodingProvider()),
        ChangeNotifierProvider(create: (context) => FaceVerificationProvider()),
        ChangeNotifierProvider(create: (context) => GetTokenProvider()),
        ChangeNotifierProvider(create: (context) => ResetPasswordProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
        ChangeNotifierProvider(create: (context) => AttendanceArrivalProvider()),
      ],
      child: MaterialApp(
        title: 'bank_sampah App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home-screen': (context) => const AuthWrapper(
                child: HomeScreen(),
              ),
          '/reset-password': (context) => const ResetPassword(),
          '/absensi-kedatangan': (context) => const AbsensiKedatangan(),
        },
      ),
    );
  }
}
