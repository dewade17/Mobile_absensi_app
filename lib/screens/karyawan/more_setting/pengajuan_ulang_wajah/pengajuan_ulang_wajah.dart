import 'package:absensi_app/dto/face_reenrollment.dart';
import 'package:absensi_app/providers/face_reenrollment_provider.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PengajuanUlangWajah extends StatefulWidget {
  const PengajuanUlangWajah({super.key});

  @override
  State<PengajuanUlangWajah> createState() => _PengajuanUlangWajahState();
}

class _PengajuanUlangWajahState extends State<PengajuanUlangWajah> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider =
        Provider.of<FaceReenrollmentProvider>(context, listen: false);
    final request = FaceReenrollment(alasan: _alasanController.text);
    final success = await provider.submitRequest(request);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim')),
      );
      Navigator.pop(context);
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FaceReenrollmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
      ),
      body: Stack(
        children: [
          Container(
            height: 260,
            width: double.infinity,
            color: AppColors.primaryColor,
            padding: const EdgeInsets.only(top: 0),
            child: Center(
                child: Column(
              children: [
                Image.asset(
                  'assets/images/Resubmission.png',
                  width: 200,
                  height: 200,
                ),
                const Text(
                  "Form Pengajuan Ulang Wajah",
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
                  const SizedBox(height: 210),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _alasanController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Keterangan Pengajuan Ulang',
                              alignLabelWithHint: true,
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Icon(Icons.edit_note),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 32),
                          provider.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: () => _submit(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: const Text(
                                    "Kirim Pengajuan",
                                    style: TextStyle(fontSize: 16),
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
