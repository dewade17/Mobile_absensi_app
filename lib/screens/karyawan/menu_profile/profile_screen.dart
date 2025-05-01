import 'dart:convert';

import 'package:absensi_app/providers/profile_provider.dart';
import 'package:absensi_app/screens/karyawan/menu_profile/update_profile.dart';
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
      appBar: AppBar(
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isBase64Image
                          ? Image.memory(
                              base64Decode(user.fotoProfil!.split(',').last),
                              width: 100,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image),
                            )
                          : Image.network(
                              user.fotoProfil ?? '',
                              width: 100,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image),
                            ),
                      const SizedBox(height: 16),
                      Text("Nama: ${user.nama}"),
                      Text("Email: ${user.email}"),
                      Text("No HP: ${user.noHp}"),
                      Text("NIP: ${user.nip}"),
                    ],
                  ),
                ),
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
