import 'dart:convert';
import 'dart:io';

import 'package:absensi_app/dto/agenda.dart';
import 'package:absensi_app/dto/work_agenda_item.dart';
import 'package:absensi_app/providers/agenda_provider.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddAgendaScreen extends StatefulWidget {
  const AddAgendaScreen({super.key});

  @override
  State<AddAgendaScreen> createState() => _AddAgendaScreenState();
}

class _AddAgendaScreenState extends State<AddAgendaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();
  DateTime? _tanggal;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  bool _isSubmitting = false;
  File? galleryFile;
  final picker = ImagePicker();

  // 🔽 Memilih gambar
  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
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
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.length();
      const maxSizeInBytes = 1 * 1024 * 1024; // 1MB

      if (bytes > maxSizeInBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran file melebihi 1MB. Silakan pilih file lain.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        galleryFile = file;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _tanggal == null ||
        _jamMulai == null ||
        _jamSelesai == null ||
        galleryFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field dan pilih foto.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID tidak ditemukan. Harap login ulang.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();

    final startDateTime = DateTime(
      _tanggal!.year,
      _tanggal!.month,
      _tanggal!.day,
      _jamMulai!.hour,
      _jamMulai!.minute,
    );

    final endDateTime = DateTime(
      _tanggal!.year,
      _tanggal!.month,
      _tanggal!.day,
      _jamSelesai!.hour,
      _jamSelesai!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai tidak boleh lebih awal dari jam mulai.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bytes = await galleryFile!.readAsBytes();
    final base64Image = 'data:image/png;base64,${base64Encode(bytes)}';

    // Buat item agenda
    final item = WorkagendaItem(
      tanggal: _tanggal,
      jamMulai: startDateTime,
      jamSelesai: endDateTime,
      deskripsiPekerjaan: _deskripsiController.text,
      buktiFotoUrl: base64Image,
    );

    // Buat agenda utama
    final agenda = Workagenda(
      userId: userId,
      agendaId: 'AGENDA_${now.millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
      items: [item],
    );

    print('📤 Payload dikirim: ${agenda.toJsonWithItems()}');

    setState(() => _isSubmitting = true);
    final result = await Provider.of<WorkAgendaProvider>(
      context,
      listen: false,
    ).createWorkAgendaWithItems(agenda);
    setState(() => _isSubmitting = false);

    if (result == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agenda berhasil ditambahkan')),
      );
    } else if (result is Map && result['errors'] != null) {
      // Menampilkan pesan error validasi dari backend
      final errors = result['errors'] as List;
      final errorMessages = errors
          .map((e) => 'Item ke-${(e['index'] ?? 0) + 1}: ${e['message']}')
          .join('\n');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessages),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambahkan agenda'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: const TextTheme(
              headlineLarge: TextStyle(fontSize: 20),
              titleLarge: TextStyle(fontSize: 16),
              bodyLarge: TextStyle(fontSize: 14),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _tanggal = picked);
    }
  }

  Future<void> _selectTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _jamMulai = picked;
        } else {
          _jamSelesai = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd');
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Agenda Hari Ini'),
        centerTitle: true,
        backgroundColor: Colors.lightBlue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi Pekerjaan',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Deskripsi tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        tileColor: Colors.grey[100],
                        title: Text(
                          _tanggal != null
                              ? formatter.format(_tanggal!)
                              : 'Pilih Tanggal',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        tileColor: Colors.grey[100],
                        title: Text(
                          _jamMulai != null
                              ? 'Jam Mulai: ${_jamMulai!.format(context)}'
                              : 'Pilih Jam Mulai',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectTime(isStart: true),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        tileColor: Colors.grey[100],
                        title: Text(
                          _jamSelesai != null
                              ? 'Jam Selesai: ${_jamSelesai!.format(context)}'
                              : 'Pilih Jam Selesai',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectTime(isStart: false),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        tileColor: Colors.grey[100],
                        title: const Text("Upload Bukti Foto"),
                        subtitle: Text(
                          galleryFile != null
                              ? galleryFile!.path.split('/').last
                              : "Belum ada file",
                          style:
                              const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.upload_file),
                        onTap: () => _showPicker(context),
                      ),
                      if (galleryFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              galleryFile!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Menyimpan...' : 'Simpan Agenda'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
