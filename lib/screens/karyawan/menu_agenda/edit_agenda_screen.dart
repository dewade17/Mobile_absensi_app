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
      appBar: AppBar(
        title: const Text('Edit Agenda'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Pekerjaan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Deskripsi tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Colors.grey[200],
                title: Text(_tanggal != null
                    ? formatter.format(_tanggal!)
                    : 'Pilih Tanggal'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Colors.grey[200],
                title: Text(_jamMulai != null
                    ? 'Jam Mulai: ${_jamMulai!.format(context)}'
                    : 'Pilih Jam Mulai'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(isStart: true),
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Colors.grey[200],
                title: Text(_jamSelesai != null
                    ? 'Jam Selesai: ${_jamSelesai!.format(context)}'
                    : 'Pilih Jam Selesai'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(isStart: false),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  Widget fileInfo;

                  if (galleryFile != null) {
                    final ext = galleryFile!.path.split('.').last.toLowerCase();
                    final isImage = ['jpg', 'jpeg', 'png'].contains(ext);

                    fileInfo = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _getImage(ImageSource.gallery),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isImage ? Icons.image : Icons.picture_as_pdf,
                                  color: isImage ? Colors.black54 : Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    galleryFile!.path.split('/').last,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.edit, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              galleryFile!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    );
                  } else if (widget.item.buktiFotoUrl != null &&
                      widget.item.buktiFotoUrl!.isNotEmpty) {
                    final bukti = widget.item.buktiFotoUrl!;

                    if (bukti.startsWith('data:image/')) {
                      try {
                        final imageBytes = base64Decode(bukti.split(',').last);
                        fileInfo = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _getImage(ImageSource.gallery),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.image),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Gambar lama digunakan, klik untuk mengganti',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.grey),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.edit, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                imageBytes,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        );
                      } catch (e) {
                        fileInfo = GestureDetector(
                          onTap: () => _getImage(ImageSource.gallery),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.broken_image, color: Colors.grey),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Gagal memuat gambar, klik untuk mengganti',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.red),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.edit, size: 18),
                              ],
                            ),
                          ),
                        );
                      }
                    } else if (bukti.startsWith('data:application/pdf')) {
                      fileInfo = GestureDetector(
                        onTap: () => _getImage(ImageSource.gallery),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.picture_as_pdf, color: Colors.red),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'PDF lama digunakan, klik untuk mengganti',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.edit, size: 18),
                            ],
                          ),
                        ),
                      );
                    } else {
                      fileInfo = const SizedBox();
                    }
                  } else {
                    // No file at all
                    fileInfo = GestureDetector(
                      onTap: () => _getImage(ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.upload),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Klik untuk upload bukti (opsional)',
                                style:
                                    TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.edit, size: 18),
                          ],
                        ),
                      ),
                    );
                  }

                  return fileInfo;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label:
                    Text(_isSubmitting ? 'Menyimpan...' : 'Simpan Perubahan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
