import 'dart:convert';

import 'package:absensi_app/providers/profile_provider.dart';
import 'package:absensi_app/screens/karyawan/menu_faceid/home_face.dart';
import 'package:absensi_app/screens/karyawan/menu_profile/update_profile.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).initUserProfile();
    });
  }

  Future<void> _refreshProfile() async {
    await Provider.of<ProfileProvider>(context, listen: false)
        .initUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profil'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          final user = profileProvider.user;
          final isBase64Image =
              user?.fotoProfil?.startsWith('data:image') ?? false;

          if (user == null)
            return const Center(child: CircularProgressIndicator());

          return RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SafeArea(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: (user.fotoProfil != null &&
                              user.fotoProfil!.isNotEmpty)
                          ? (isBase64Image
                              ? MemoryImage(base64Decode(
                                  user.fotoProfil!.split(',').last))
                              : NetworkImage(user.fotoProfil!)) as ImageProvider
                          : null,
                      child:
                          (user.fotoProfil == null || user.fotoProfil!.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.grey)
                              : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader("Informasi Pribadi"),
                  _buildInfoTile(Icons.person, user.nama),
                  _buildInfoTile(Icons.email, user.email),
                  _buildInfoTile(
                      Icons.phone,
                      user.noHp?.isNotEmpty == true
                          ? user.noHp!
                          : "Lengkapi nomor telepon"),
                  _buildInfoTile(
                      Icons.badge,
                      user.nip?.isNotEmpty == true
                          ? user.nip!
                          : "Lengkapi NIP Anda"),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Pengaturan"),
                  _buildActionTile(Icons.face, "Registrasi Wajah", () {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (_) => HomeFace()));
                  }),
                  _buildActionTile(Icons.warning, "Absensi Darurat", () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => EmergencyScreen()));
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const UpdateProfile()));
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(value),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
