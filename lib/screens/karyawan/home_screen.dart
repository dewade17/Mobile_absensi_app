import 'package:absensi_app/providers/authprovider.dart';
import 'package:absensi_app/providers/profile_provider.dart';
import 'package:absensi_app/screens/karyawan/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:provider/provider.dart';

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
    const SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        items: const [
          Icon(Icons.home, color: AppColors.backgroundColor),
          Icon(Icons.settings, color: AppColors.backgroundColor),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.initUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final isComplete = profileProvider.isProfileComplete;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(185),
        child: AppBar(
          backgroundColor: AppColors.primaryColor,
          automaticallyImplyLeading: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 110.0),
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
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (value) {
                  if (value == 'logout') {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    authProvider.logout(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final profileProvider =
              Provider.of<ProfileProvider>(context, listen: false);
          await profileProvider.initUserProfile();
        },
        child: isComplete
            ? SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/absensi-kedatangan');
                          },
                          child: Card(
                            color: AppColors.primaryColor,
                            child: Icon(Icons.face, size: 100),
                          ),
                        ),
                        Card(
                          color: AppColors.primaryColor,
                          child:
                              Icon(Icons.door_front_door_outlined, size: 100),
                        ),
                        Card(
                          color: Colors.red,
                          child: Icon(Icons.sensor_door_outlined, size: 100),
                        )
                      ],
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Card(
                          color: AppColors.primaryColor,
                          child: Icon(Icons.sensor_door_outlined, size: 100),
                        ),
                        Card(
                          color: AppColors.primaryColor,
                          child: Icon(Icons.sensor_door_outlined, size: 100),
                        )
                      ],
                    ),
                    SizedBox(height: 30),
                  ],
                ),
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
      ),
    );
  }
}
