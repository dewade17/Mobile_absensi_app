import 'dart:convert';

import 'package:absensi_app/providers/profile_provider.dart';
import 'package:absensi_app/screens/karyawan/menu_faceid/home_face.dart';
import 'package:absensi_app/screens/karyawan/menu_profile/update_profile.dart';
import 'package:absensi_app/screens/karyawan/more_setting/menu_emergency/add_absensi_emergency_screen.dart';
import 'package:absensi_app/screens/karyawan/more_setting/menu_emergency/emergency_screen.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    // Panggil initUserProfile saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      provider.initUserProfile();
    });
  }

  Future<void> _refreshProfile() async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    await provider.initUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          final user = profileProvider.user;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final isBase64Image =
              user.fotoProfil?.startsWith('data:image') ?? false;

          return RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // penting untuk scroll meskipun konten pendek
              child: Column(
                children: [
                  const SizedBox(height: 10), // spasi di atas container
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(
                            top: 60), // beri ruang untuk gambar
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text("PERSONAL INFORMATION",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                            Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(Icons.person),
                                    const SizedBox(width: 10),
                                    Text(user.nama)
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(Icons.email),
                                    const SizedBox(width: 10),
                                    Text(user.email),
                                  ],
                                ),
                              ),
                            ), // ruang tambahan agar teks tidak kena gambar
                            Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(Icons.phone),
                                    const SizedBox(width: 10),
                                    Text(
                                      (user.noHp != null &&
                                              user.noHp.trim().isNotEmpty)
                                          ? user.noHp
                                          : "Lengkap nomor telepon Anda",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(Icons.badge),
                                    const SizedBox(width: 10),
                                    Text(
                                      (user.nip != null &&
                                              user.nip.trim().isNotEmpty)
                                          ? user.nip
                                          : "Lengkap NIP Anda",
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text("SETTINGS",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeFace(),
                                  ),
                                );
                              },
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.face),
                                          const SizedBox(width: 10),
                                          Text("Registrasi Wajah"),
                                        ],
                                      ),
                                      Icon(Icons.arrow_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmergencyScreen(),
                                  ),
                                );
                              },
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warning),
                                          const SizedBox(width: 10),
                                          Text("Absensi Darurat"),
                                        ],
                                      ),
                                      Icon(Icons.arrow_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeFace(),
                                  ),
                                );
                              },
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.feedback),
                                          const SizedBox(width: 10),
                                          Text("Feedback"),
                                        ],
                                      ),
                                      Icon(Icons.arrow_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeFace(),
                                  ),
                                );
                              },
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.info),
                                          const SizedBox(width: 10),
                                          Text("Version Aplikasi"),
                                        ],
                                      ),
                                      Icon(Icons.arrow_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: (user.fotoProfil != null &&
                                  user.fotoProfil!.isNotEmpty)
                              ? (isBase64Image
                                      ? MemoryImage(base64Decode(
                                          user.fotoProfil!.split(',').last))
                                      : NetworkImage(user.fotoProfil!))
                                  as ImageProvider
                              : null,
                          child: (user.fotoProfil == null ||
                                  user.fotoProfil!.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UpdateProfile()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
