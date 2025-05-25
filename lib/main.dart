import 'package:absensi_app/providers/agenda_provider.dart';
import 'package:absensi_app/providers/attendance_arrival.dart';
import 'package:absensi_app/providers/attendance_departure_provider.dart';
import 'package:absensi_app/providers/authprovider.dart';
import 'package:absensi_app/providers/emergency_attendance_provider.dart';
import 'package:absensi_app/providers/face_reenrollment_provider.dart';
import 'package:absensi_app/providers/get_token_provider.dart';
import 'package:absensi_app/providers/location_provider.dart';
import 'package:absensi_app/providers/profile_provider.dart';
import 'package:absensi_app/providers/provider_leaverequest.dart';
import 'package:absensi_app/providers/recap_attendance_provider.dart';
import 'package:absensi_app/providers/reset_password_provider.dart';
import 'package:absensi_app/providers/face/encode_provider.dart';
import 'package:absensi_app/providers/face/verify_provider.dart';
import 'package:absensi_app/screens/auth/login_screen.dart';
import 'package:absensi_app/screens/auth/reset_password.dart';
import 'package:absensi_app/screens/karyawan/home_screen.dart';
import 'package:absensi_app/screens/karyawan/menu_absensi/absensi_kedatangan.dart';
import 'package:absensi_app/screens/karyawan/menu_absensi/absensi_kepulangan.dart';
import 'package:absensi_app/screens/karyawan/menu_agenda/add_agenda_screen.dart';
import 'package:absensi_app/screens/karyawan/menu_agenda/screen_agenda.dart';
import 'package:absensi_app/screens/karyawan/menu_all_absensi/data_absensi_screen.dart';
import 'package:absensi_app/screens/karyawan/menu_request/add_request_screen.dart';
import 'package:absensi_app/screens/karyawan/more_setting/menu_emergency/add_absensi_emergency_screen.dart';
import 'package:absensi_app/screens/splash_screen/splash_screen.dart';
import 'package:absensi_app/services/auth_wrapper.dart';
import 'package:absensi_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Wajib untuk nunggu async
  await initializeDateFormatting('id_ID', null); // untuk tanggal Indonesia
  tz.initializeTimeZones(); // untuk timezone!
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🔥 FLUTTER CAUGHT ERROR: ${details.exception}');
    print('📍 STACK TRACE: ${details.stack}');
  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        ChangeNotifierProvider(create: (context) => GetTokenProvider()),
        ChangeNotifierProvider(create: (context) => ResetPasswordProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
        ChangeNotifierProvider(
          create: (context) => AttendanceArrivalProvider(),
        ),
        ChangeNotifierProvider(create: (context) => LeaveRequestProvider()),
        ChangeNotifierProvider(create: (context) => FaceEncodingProvider()),
        ChangeNotifierProvider(create: (context) => FaceVerificationProvider()),
        ChangeNotifierProvider(create: (context) => WorkAgendaProvider()),
        ChangeNotifierProvider(
            create: (context) => EmergencyAttendanceProvider()),
        ChangeNotifierProvider(
          create: (context) => FaceReenrollmentProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => AttendanceDepartureProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => RecapAttendanceProvider(),
        )
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
          '/absensi-kepulangan': (context) => const AbsensiKepulangan(),
          '/add-request': (context) => const AddRequestScreen(),
          '/add-agenda': (context) => const AddAgendaScreen(),
          '/screen-agenda': (context) => const ScreenAgenda(),
          '/emergency-absensi': (context) => const AddAbsensiEmergencyScreen(),
          '/data-absensi': (context) => const DataAbsensiScreen(),
        },
      ),
    );
  }
}
