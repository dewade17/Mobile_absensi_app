import 'dart:convert';
import 'dart:io';
import 'package:absensi_app/dto/agenda.dart';
import 'package:absensi_app/dto/work_agenda_item.dart';
import 'package:absensi_app/providers/agenda_provider.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditAgendaScreen extends StatefulWidget {
  final WorkagendaItem item;
  final String agendaId;

  const EditAgendaScreen({
    super.key,
    required this.item,
    required this.agendaId,
  });

  @override
  State<EditAgendaScreen> createState() => _EditAgendaScreenState();
}

class _EditAgendaScreenState extends State<EditAgendaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _deskripsiController;

  DateTime? _tanggal;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  File? galleryFile;
  bool _isSubmitting = false;
  DateTime? jamMulaiParsed;
  DateTime? jamSelesaiParsed;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _deskripsiController =
        TextEditingController(text: widget.item.deskripsiPekerjaan);

    if (widget.item.tanggal != null) {
      _tanggal = widget.item.tanggal;
    }

    if (widget.item.jamMulai != null) {
      _jamMulai = TimeOfDay.fromDateTime(widget.item.jamMulai!.toLocal());
    }

    if (widget.item.jamSelesai != null) {
      _jamSelesai = TimeOfDay.fromDateTime(widget.item.jamSelesai!.toLocal());
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.length();
      const maxSize = 2 * 1024 * 1024;

      if (bytes > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran file melebihi 2MB.'),
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
        _jamSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua field.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    String buktiBase64 = widget.item.buktiFotoUrl!;
    if (galleryFile != null) {
      final bytes = await galleryFile!.readAsBytes();
      buktiBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
    }

    final item = WorkagendaItem(
      tanggal: _tanggal,
      jamMulai: startDateTime,
      jamSelesai: endDateTime,
      deskripsiPekerjaan: _deskripsiController.text,
      buktiFotoUrl: buktiBase64,
    );

    final agenda = Workagenda(
      agendaId: widget.agendaId,
      items: [item],
    );

    print('Item: ${item.toJson()}');

    setState(() => _isSubmitting = true);
    final success =
        await Provider.of<WorkAgendaProvider>(context, listen: false)
            .updateWorkAgendaWithItems(widget.agendaId, agenda);
    setState(() => _isSubmitting = false);

    if (success == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agenda berhasil diperbarui')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui agenda'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime.now(),
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
            padding: const EdgeInsets.only(top: 30),
            child: const Center(
              child: Text(
                "Edit Agenda Kerja",
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 100),
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
                        children: [
                          TextFormField(
                            controller: _deskripsiController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Deskripsi Pekerjaan',
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
                          SizedBox(
                            width: double
                                .infinity, // agar tombol melebar mengikuti layar
                            child: OutlinedButton.icon(
                              onPressed: () => _getImage(ImageSource.gallery),
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload Bukti Foto"),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: AppColors.primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (galleryFile != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                galleryFile!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (widget.item.buktiFotoUrl != null &&
                              widget.item.buktiFotoUrl!
                                  .startsWith('data:image/'))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(
                                    widget.item.buktiFotoUrl!.split(',').last),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
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
                                    _isSubmitting
                                        ? 'Menyimpan...'
                                        : 'Simpan Perubahan',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
