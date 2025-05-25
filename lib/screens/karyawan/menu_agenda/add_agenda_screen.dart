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
      appBar: AppBar(backgroundColor: AppColors.primaryColor),
      body: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: AppColors.primaryColor,
            padding: const EdgeInsets.only(bottom: 100),
            child: const Center(
              child: Text(
                "Form Agenda Kerja",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _deskripsiController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Deskripsi Pekerjaan',
                              alignLabelWithHint: true,
                              prefixIcon: const Icon(Icons.work),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Deskripsi tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            readOnly: true,
                            onTap: _selectDate,
                            decoration: InputDecoration(
                              labelText: 'Tanggal',
                              prefixIcon: const Icon(Icons.date_range),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            controller: TextEditingController(
                              text: _tanggal != null
                                  ? formatter.format(_tanggal!)
                                  : '',
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            readOnly: true,
                            onTap: () => _selectTime(isStart: true),
                            decoration: InputDecoration(
                              labelText: 'Jam Mulai',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            controller: TextEditingController(
                              text: _jamMulai != null
                                  ? _jamMulai!.format(context)
                                  : '',
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            readOnly: true,
                            onTap: () => _selectTime(isStart: false),
                            decoration: InputDecoration(
                              labelText: 'Jam Selesai',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            controller: TextEditingController(
                              text: _jamSelesai != null
                                  ? _jamSelesai!.format(context)
                                  : '',
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () => _showPicker(context),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Bukti Foto'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: AppColors.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
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
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitForm,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _isSubmitting ? 'Menyimpan...' : 'Simpan Agenda',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
