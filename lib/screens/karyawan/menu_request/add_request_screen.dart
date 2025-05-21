import 'dart:convert';
import 'dart:io'; // Tambahkan untuk File
import 'package:absensi_app/providers/provider_leaverequest.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../dto/leaverequest.dart';
import 'package:file_picker/file_picker.dart';

class AddRequestScreen extends StatefulWidget {
  const AddRequestScreen({super.key});

  @override
  State<AddRequestScreen> createState() => _AddRequestScreenState();
}

class _AddRequestScreenState extends State<AddRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _alasanController = TextEditingController();
  final TextEditingController _tanggalMulaiController = TextEditingController();
  final TextEditingController _tanggalSelesaiController =
      TextEditingController();

  String? _selectedJenisIzin;
  final List<String> _jenisIzinList = ['izin', 'cuti', 'sakit'];

  final ImagePicker picker = ImagePicker();
  File? galleryFile;
  bool _isSubmitting = false;
  String? _base64File;
  String? _fileType; // 'image' atau 'pdf'
  String? _fileName;

  DateTime? _selectedTanggalMulai;
  DateTime? _selectedTanggalSelesai;

  @override
  void dispose() {
    _alasanController.dispose();
    _tanggalMulaiController.dispose();
    _tanggalSelesaiController.dispose();
    super.dispose();
  }

  // Menampilkan pilihan Camera / Gallery
  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Pilih File (Gambar / PDF)'),
                onTap: () {
                  _pickFile(); // fungsi kamu yang pakai file_picker
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Mengambil gambar dari source
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      final fileSize = bytes.lengthInBytes;
      const maxSize = 1 * 1024 * 1024; // ✅ Maksimum 1MB

      if (fileSize > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran file melebihi 1MB. Pilih file lain.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final ext = result.files.single.extension!.toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png'].contains(ext);
      final mimeType = isImage
          ? (ext == 'jpg' ? 'image/jpeg' : 'image/$ext')
          : 'application/pdf';

      setState(() {
        galleryFile = file;
        _fileType = isImage ? 'image' : 'pdf';
        _fileName = result.files.single.name;
        _base64File = 'data:$mimeType;base64,${base64Encode(bytes)}';
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User ID not found in SharedPreferences');
      }

      final base64File = _base64File ?? '';

      final leaveRequest = Leaverequest(
        userId: userId,
        jenisIzin: _selectedJenisIzin ?? '',
        tanggalMulai: DateTime.parse(_tanggalMulaiController.text),
        tanggalSelesai: DateTime.parse(_tanggalSelesaiController.text),
        alasan: _alasanController.text,
        buktiFile: base64File,
      );

      final success =
          await Provider.of<LeaveRequestProvider>(context, listen: false)
              .createLeaveRequest(leaveRequest);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave Request Created Successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create leave request.')),
        );
      }
    } catch (e) {
      print('❌ Submit Form Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isMulai) async {
    FocusScope.of(context).requestFocus(FocusNode());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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
      setState(() {
        if (isMulai) {
          _selectedTanggalMulai = picked;
          _tanggalMulaiController.text = picked.toIso8601String().split('T')[0];
        } else {
          _selectedTanggalSelesai = picked;
          _tanggalSelesaiController.text =
              picked.toIso8601String().split('T')[0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primaryColor),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              color: AppColors.primaryColor,
              child: Padding(
                padding: EdgeInsets.only(top: 30, left: 70, right: 70),
                child: Text("Form Permohonan Cuti/Izin/Sakit",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 90),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            // Dropdown jenis izin
                            DropdownButtonFormField<String>(
                              value: _selectedJenisIzin,
                              decoration: InputDecoration(
                                labelText: 'Jenis Izin',
                                prefixIcon: const Icon(Icons.list_alt),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _jenisIzinList
                                  .map((j) => DropdownMenuItem(
                                      value: j, child: Text(j)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedJenisIzin = val),
                              validator: (v) =>
                                  v == null ? 'Pilih jenis izin' : null,
                            ),
                            const SizedBox(height: 20),

                            // Tanggal mulai
                            TextFormField(
                              controller: _tanggalMulaiController,
                              readOnly: true,
                              onTap: () => _selectDate(context, true),
                              decoration: InputDecoration(
                                labelText: 'Mulai (YYYY-MM-DD)',
                                prefixIcon: const Icon(Icons.date_range),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Pilih tanggal mulai'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // Tanggal selesai
                            TextFormField(
                              controller: _tanggalSelesaiController,
                              readOnly: true,
                              onTap: () => _selectDate(context, false),
                              decoration: InputDecoration(
                                labelText: 'Selesai (YYYY-MM-DD)',
                                prefixIcon:
                                    const Icon(Icons.date_range_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Pilih tanggal selesai'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // Alasan
                            TextFormField(
                              controller: _alasanController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Alasan',
                                alignLabelWithHint: true,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Icon(Icons.comment),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Masukkan alasan'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Preview gambar
                            if (galleryFile != null)
                              _fileType == 'image'
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        galleryFile!,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : ListTile(
                                      leading: Icon(Icons.picture_as_pdf,
                                          color: Colors.red),
                                      title: Text(_fileName ?? 'PDF Terpilih'),
                                      subtitle: Text('File siap dikirim'),
                                    ),
                            const SizedBox(height: 32),
                            // Tombol pilih gambar
                            OutlinedButton.icon(
                              onPressed: () => _showPicker(context),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Unggah Bukti'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: AppColors.primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Tombol submit
                            _isSubmitting
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: Text(
                                        'Kirim Permintaan',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),

                    // Tambahan bottom padding supaya scroll nyaman
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
