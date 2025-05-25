import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/dto/emergency_attendance.dart';
import 'package:absensi_app/providers/emergency_attendance_provider.dart';

class AddAbsensiEmergencyScreen extends StatefulWidget {
  const AddAbsensiEmergencyScreen({super.key});

  @override
  State<AddAbsensiEmergencyScreen> createState() =>
      _AddAbsensiEmergencyScreenState();
}

class _AddAbsensiEmergencyScreenState extends State<AddAbsensiEmergencyScreen> {
  final TextEditingController _alasanController = TextEditingController();
  String _selectedJenis = 'MASUK';
  DateTime _tanggal = DateTime.now();
  TimeOfDay _jamMasuk = TimeOfDay.now();

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
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
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jamMasuk,
    );
    if (picked != null) setState(() => _jamMasuk = picked);
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    final provider =
        Provider.of<EmergencyAttendanceProvider>(context, listen: false);
    final alasan = _alasanController.text.trim();

    if (alasan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alasan tidak boleh kosong")),
      );
      return;
    }

    final emergency = EmergencyAttendance(
      tanggal: DateTime(_tanggal.year, _tanggal.month, _tanggal.day),
      jamMasuk: _combineDateTime(_tanggal, _jamMasuk),
      jenis: _selectedJenis,
      alasan: alasan,
    );

    final success = await provider.submitEmergency(emergency);
    if (success) {
      _alasanController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(provider.successMessage ?? "Berhasil menyimpan")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? "Terjadi kesalahan")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmergencyAttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primaryColor),
      body: Stack(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            color: AppColors.primaryColor,
            padding: const EdgeInsets.only(top: 0),
            child: Center(
                child: Column(
              children: [
                Image.asset(
                  'assets/images/Urgent.png',
                  width: 200,
                  height: 200,
                ),
                Text(
                  "Form Absensi Darurat",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 220),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedJenis,
                          decoration: InputDecoration(
                            labelText: 'Jenis Absensi',
                            prefixIcon: const Icon(Icons.event_note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'MASUK', child: Text('MASUK')),
                            DropdownMenuItem(
                                value: 'PULANG', child: Text('PULANG')),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedJenis = value!),
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
                            text: "${_tanggal.toLocal()}".split(' ')[0],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          readOnly: true,
                          onTap: _selectTime,
                          decoration: InputDecoration(
                            labelText: 'Jam',
                            prefixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _jamMasuk.format(context),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _alasanController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Keterangan',
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Icon(Icons.comment),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        provider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.send),
                                label: const Text('Kirim Absensi Darurat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                      ],
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
