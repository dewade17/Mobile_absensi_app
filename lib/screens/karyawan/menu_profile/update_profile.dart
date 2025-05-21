import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:absensi_app/utils/colors.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final originalFile = File(pickedFile.path);
    final fileSize = await originalFile.length();

    Uint8List finalBytes;

    if (fileSize > 2 * 1024 * 1024) {
      // Kompres jika > 2MB
      finalBytes = await FlutterImageCompress.compressWithFile(
            originalFile.path,
            minWidth: 800,
            minHeight: 800,
            quality: 70,
            format: CompressFormat.jpeg,
          ) ??
          await originalFile.readAsBytes(); // fallback jika gagal kompres
    } else {
      finalBytes = await originalFile.readAsBytes();
    }

    setState(() {
      galleryFile = originalFile;
    });

    final base64Image = "data:image/jpeg;base64,${base64Encode(finalBytes)}";
    _fotoProfilController.text = base64Image;
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
        centerTitle: true,
        title: const Text('Perbarui Profil'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: AppColors.primaryColor,
        child: SafeArea(
          child: Stack(
            children: [
              // Posisi form putih
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // Foto Profil
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: galleryFile != null
                                        ? Image.file(galleryFile!,
                                            fit: BoxFit.cover)
                                        : (_fotoProfilController.text
                                                .startsWith('data:image/')
                                            ? Image.memory(
                                                base64Decode(
                                                  _fotoProfilController.text
                                                      .split(',')
                                                      .last,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : Icon(Icons.person,
                                                size: 60,
                                                color: Colors.grey[400])),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showPicker(context),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.camera_alt,
                                        size: 20, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),

                          // Nama
                          TextFormField(
                            controller: _namaController,
                            decoration: InputDecoration(
                              labelText: 'Nama',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(width: 2, color: Colors.blue),
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Nama wajib diisi'
                                    : null,
                          ),
                          SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(width: 2, color: Colors.blue),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Email wajib diisi'
                                    : null,
                          ),
                          SizedBox(height: 16),

                          // No HP
                          TextFormField(
                            controller: _noHpController,
                            decoration: InputDecoration(
                              labelText: 'No HP',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(width: 2, color: Colors.blue),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'No HP wajib diisi'
                                    : null,
                          ),
                          SizedBox(height: 16),

                          // NIP
                          TextFormField(
                            controller: _nipController,
                            decoration: InputDecoration(
                              labelText: 'NIP',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(width: 2, color: Colors.blue),
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'NIP wajib diisi'
                                    : null,
                          ),
                          SizedBox(height: 32),

                          // Tombol Simpan
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitUpdate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
