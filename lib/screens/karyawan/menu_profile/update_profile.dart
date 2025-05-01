import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:absensi_app/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _noHpController;
  late TextEditingController _nipController;
  late TextEditingController _fotoProfilController;

  final ImagePicker picker = ImagePicker();
  File? galleryFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().user;
    _namaController = TextEditingController(text: user?.nama ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _noHpController = TextEditingController(text: user?.noHp ?? '');
    _nipController = TextEditingController(text: user?.nip ?? '');
    _fotoProfilController = TextEditingController(text: user?.fotoProfil ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _nipController.dispose();
    _fotoProfilController.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();

      const maxSize = 2 * 1024 * 1024; // 2MB in bytes

      if (fileSize > maxSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Ukuran foto maksimal 2MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // Jangan lanjut jika ukuran terlalu besar
      }

      setState(() {
        galleryFile = file;
      });

      final bytes = await pickedFile.readAsBytes();
      final base64Image = "data:image/png;base64,${base64Encode(bytes)}";
      _fotoProfilController.text = base64Image;
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<ProfileProvider>().updateUserProfile(
            nama: _namaController.text,
            email: _emailController.text,
            noHp: _noHpController.text,
            nip: _nipController.text,
            fotoProfil: _fotoProfilController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profil berhasil diperbarui')),
        );
        Navigator.pop(context); // kembali ke profile screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Nama wajib diisi' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Email wajib diisi' : null,
              ),
              TextFormField(
                controller: _noHpController,
                decoration: const InputDecoration(labelText: 'No HP'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'No HP wajib diisi' : null,
              ),
              TextFormField(
                controller: _nipController,
                decoration: const InputDecoration(labelText: 'NIP'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'NIP wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text("Upload Foto Profil"),
              const SizedBox(height: 8),
              galleryFile != null
                  ? Image.file(galleryFile!)
                  : _fotoProfilController.text.startsWith('data:image/')
                      ? Image.memory(
                          base64Decode(
                            _fotoProfilController.text.split(',').last,
                          ),
                          height: 150,
                        )
                      : const Icon(Icons.image, size: 100, color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _getImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text("Galeri"),
                  ),
                  TextButton.icon(
                    onPressed: () => _getImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Kamera"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitUpdate,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
