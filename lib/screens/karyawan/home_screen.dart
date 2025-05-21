import 'dart:convert';
import 'dart:typed_data';

import 'package:absensi_app/screens/karyawan/menu_profile/profile_screen.dart';
import 'package:absensi_app/screens/karyawan/menu_request/screen_request.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:absensi_app/providers/attendance_arrival.dart';
import 'package:absensi_app/providers/authprovider.dart';
import 'package:absensi_app/providers/profile_provider.dart';
import 'package:absensi_app/screens/karyawan/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenContent(),
    const ScreenRequest(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        items: const [
          Icon(Icons.home, color: AppColors.backgroundColor),
          Icon(Icons.notifications, color: AppColors.backgroundColor),
          Icon(Icons.person, color: AppColors.backgroundColor),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        color: AppColors.primaryColor,
        buttonBackgroundColor: AppColors.primaryColor,
      ),
    );
  }
}

// Ini adalah content utama dari HomeScreen
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late ScrollController _scrollController;

  Future<void> fetchAttendanceData({bool refresh = false}) async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceArrivalProvider>(context, listen: false);

    await profileProvider.initUserProfile();
    await attendanceProvider.fetchPaginatedAttendanceArrivals(refresh: refresh);
  }

  void _scrollListener() {
    final attendanceProvider =
        Provider.of<AttendanceArrivalProvider>(context, listen: false);

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!attendanceProvider.isLoading &&
          attendanceProvider.attendanceArrivals.isNotEmpty) {
        attendanceProvider.fetchPaginatedAttendanceArrivals();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchAttendanceData());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final isComplete = profileProvider.isProfileComplete;

    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(300),
          child: AppBar(
            backgroundColor: AppColors.primaryColor,
            automaticallyImplyLeading: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            flexibleSpace: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, top: 110.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'I Dewa Gede Arsana PucangAnom, S.Kom',
                        style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '2215091041',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Card(
                        child: isComplete
                            ? Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.pushNamed(context,
                                                  '/absensi-kedatangan');
                                            },
                                            child: Center(
                                              child: Column(
                                                children: const [
                                                  Icon(
                                                    Icons.calendar_month,
                                                    size: 30,
                                                    color: Color(0xFF92E3A9),
                                                  ),
                                                  Text(
                                                    'Absensi Kedatangan',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              // Navigasi ke Absensi Kepulangan
                                            },
                                            child: Center(
                                              child: Column(
                                                children: const [
                                                  Icon(
                                                    Icons.calendar_month,
                                                    size: 30,
                                                    color: Colors.red,
                                                  ),
                                                  Text(
                                                    'Absensi Kepulangan',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.pushNamed(
                                                  context, '/screen-agenda');
                                            },
                                            child: Center(
                                              child: Column(
                                                children: const [
                                                  Icon(
                                                    Icons.assignment_add,
                                                    size: 30,
                                                    color: Colors.blueAccent,
                                                  ),
                                                  Text(
                                                    'Agenda\nKerja',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              final authProvider =
                                                  Provider.of<AuthProvider>(
                                                      context,
                                                      listen: false);
                                              authProvider.logout(context);
                                            },
                                            child: Center(
                                              child: Column(
                                                children: const [
                                                  Icon(
                                                      Icons
                                                          .power_settings_new_sharp,
                                                      size: 30),
                                                  Text('Logout'),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              )
                            : const SizedBox(), // Kalau belum lengkap, Card tetap ada tapi isinya kosong
                      )
                    ],
                  ),
                ),
                Positioned(
                  top: 40, // Jarak dari atas
                  right: 16, // Jarak dari kanan
                  child: GestureDetector(
                    onTap: () {
                      // Aksi klik foto profil
                    },
                    child: Consumer<ProfileProvider>(
                      builder: (context, profileProvider, child) {
                        final base64Photo = profileProvider.user?.fotoProfil;
                        const double avatarRadius = 35;

                        if (base64Photo != null && base64Photo.isNotEmpty) {
                          try {
                            String cleanedBase64 = base64Photo.split(',').last;
                            Uint8List imageBytes = base64Decode(cleanedBase64);
                            return CircleAvatar(
                              radius: avatarRadius,
                              backgroundImage: MemoryImage(imageBytes),
                            );
                          } catch (e) {
                            return CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person,
                                  size: avatarRadius,
                                  color: AppColors.primaryColor),
                            );
                          }
                        } else {
                          return CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person,
                                size: avatarRadius,
                                color: AppColors.primaryColor),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            final profileProvider =
                Provider.of<ProfileProvider>(context, listen: false);
            await profileProvider.initUserProfile();
          },
          child: isComplete
              ? Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "History\nKehadiran",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "View All",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Expanded ListView
                    Expanded(
                      child: Consumer<AttendanceArrivalProvider>(
                        builder: (context, attendanceProvider, child) {
                          if (attendanceProvider.isLoading &&
                              attendanceProvider.attendanceArrivals.isEmpty) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                attendanceProvider.attendanceArrivals.length +
                                    (attendanceProvider.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index <
                                  attendanceProvider
                                      .attendanceArrivals.length) {
                                final attendance = attendanceProvider
                                    .attendanceArrivals[index];
                                final location =
                                    tz.getLocation('Asia/Singapore');
                                final jamMasukSingapore = tz.TZDateTime.from(
                                    attendance.jamMasuk, location);

                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Card(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 26),
                                          child: Text(
                                            '${DateFormat('EEEE', 'id_ID').format(attendance.tanggal)}, '
                                            '${attendance.tanggal.day} '
                                            '${DateFormat('MMMM', 'id_ID').format(attendance.tanggal)} '
                                            '${attendance.tanggal.year}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    color: Colors.red,
                                                    size: 30),
                                                const SizedBox(width: 5),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text("Start Day"),
                                                    Text(
                                                      "${jamMasukSingapore.hour.toString().padLeft(2, '0')}:${jamMasukSingapore.minute.toString().padLeft(2, '0')}",
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    color: Colors.red,
                                                    size: 30),
                                                const SizedBox(width: 5),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text("Start Day"),
                                                    Text(
                                                      () {
                                                        final location =
                                                            tz.getLocation(
                                                                'Asia/Singapore');
                                                        final jamMasukSingapore =
                                                            tz.TZDateTime.from(
                                                                attendance
                                                                    .jamMasuk,
                                                                location);
                                                        return "${jamMasukSingapore.hour.toString().padLeft(2, '0')}:${jamMasukSingapore.minute.toString().padLeft(2, '0')}";
                                                      }(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 250),
                    Center(
                      child: Text(
                        'Lengkapi data profil Anda terlebih dahulu!',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ),
                  ],
                ),
        ));
  }
}
