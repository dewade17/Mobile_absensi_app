// ignore_for_file: use_super_parameters

import 'dart:convert';
import 'dart:io';

import 'package:absensi_app/dto/leaverequest.dart';
import 'package:absensi_app/providers/provider_leaverequest.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditRequestScreen extends StatefulWidget {
  final Leaverequest leave;
  const EditRequestScreen({
    Key? key,
    required this.leave,
  }) : super(key: key);

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedJenis;
  late TextEditingController _alasanController;
  late TextEditingController _tanggalMulaiController;
  late TextEditingController _tanggalSelesaiController;

  File? _galleryFile;
  bool _isSubmitting = false;

  final List<String> _jenisIzinList = ['izin', 'cuti', 'sakit'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedJenis = widget.leave.jenisIzin;
    _alasanController = TextEditingController(text: widget.leave.alasan);
    _tanggalMulaiController = TextEditingController(
      text:
          DateFormat('yyyy-MM-dd').format(widget.leave.tanggalMulai.toLocal()),
    );
    _tanggalSelesaiController = TextEditingController(
      text: DateFormat('yyyy-MM-dd')
          .format(widget.leave.tanggalSelesai.toLocal()),
    );
  }

  @override
  void dispose() {
    _alasanController.dispose();
    _tanggalMulaiController.dispose();
    _tanggalSelesaiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isMulai) async {
    final DateTime initial =
        isMulai ? widget.leave.tanggalMulai : widget.leave.tanggalSelesai;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
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
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isMulai) {
          _tanggalMulaiController.text = formatted;
        } else {
          _tanggalSelesaiController.text = formatted;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      final fileSize = bytes.lengthInBytes;
      const maxSize = 1 * 1024 * 1024; // ✅ Maks 1MB

      if (fileSize > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran file maksimal 1MB'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _galleryFile = file;
      });
    }
  }

  Future<void> _showPicker() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Pilih File (Gambar / PDF)'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
      ),
      body: Stack(
        children: [
          // Background header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              color: AppColors.primaryColor,
              child: Padding(
                padding: const EdgeInsets.only(top: 30, left: 100, right: 100),
                child: Text(
                  'Form Perubahan Cuti/Izin/Sakit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // White card form
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Form(
                    key: _formKey,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              // Dropdown jenis izin
                              DropdownButtonFormField<String>(
                                value: _selectedJenis,
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
                                    setState(() => _selectedJenis = val!),
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
                                validator: (v) => v == null || v.isEmpty
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
                                validator: (v) => v == null || v.isEmpty
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
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Masukkan alasan'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              // Preview file baru (_galleryFile) atau file lama (widget.leave.buktiFile)
                              Builder(
                                builder: (context) {
                                  if (_galleryFile != null) {
                                    final ext = _galleryFile!.path
                                        .split('.')
                                        .last
                                        .toLowerCase();
                                    final isImage =
                                        ['jpg', 'jpeg', 'png'].contains(ext);

                                    if (isImage) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _galleryFile!,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    } else {
                                      return ListTile(
                                        leading: const Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red),
                                        title: Text(
                                            _galleryFile!.path.split('/').last),
                                        subtitle:
                                            const Text('File PDF siap dikirim'),
                                      );
                                    }
                                  } else {
                                    // Preview file lama dari base64
                                    if (widget.leave.buktiFile
                                        .startsWith('data:image/')) {
                                      try {
                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.memory(
                                            base64Decode(widget.leave.buktiFile
                                                .split(',')
                                                .last),
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      } catch (e) {
                                        return const Icon(Icons.broken_image,
                                            size: 100, color: Colors.grey);
                                      }
                                    } else if (widget.leave.buktiFile
                                        .startsWith('data:application/pdf')) {
                                      return ListTile(
                                        leading: const Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red),
                                        title: const Text('File PDF Terlampir'),
                                        subtitle: const Text(
                                            'Klik Ubah untuk mengganti file'),
                                      );
                                    } else {
                                      return const Icon(Icons.insert_drive_file,
                                          size: 100, color: Colors.grey);
                                    }
                                  }
                                },
                              ),

                              const SizedBox(height: 16),
                              // Tombol pilih/ubah gambar
                              OutlinedButton.icon(
                                onPressed: _showPicker,
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Unggah Bukti'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Tombol simpan
                              _isSubmitting
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : ElevatedButton(
                                      onPressed: _submitUpdate,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        child: Text('Simpan Perubahan',
                                            style: TextStyle(fontSize: 16)),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    String bukti = widget.leave.buktiFile;

    if (_galleryFile != null) {
      final bytes = await _galleryFile!.readAsBytes();

      final ext = _galleryFile!.path.split('.').last.toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png'].contains(ext);
      final mimeType = isImage
          ? (ext == 'jpg' ? 'image/jpeg' : 'image/$ext')
          : 'application/pdf';

      bukti = 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    final updated = Leaverequest(
      leaveId: widget.leave.leaveId,
      jenisIzin: _selectedJenis,
      tanggalMulai: DateTime.parse(_tanggalMulaiController.text),
      tanggalSelesai: DateTime.parse(_tanggalSelesaiController.text),
      alasan: _alasanController.text.trim(),
      buktiFile: bukti,
    );

    final provider = Provider.of<LeaveRequestProvider>(context, listen: false);
    final success =
        await provider.updateLeaveRequest(widget.leave.leaveId!, updated);

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan izin berhasil diperbarui')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Gagal memperbarui')),
      );
    }
  }
}
