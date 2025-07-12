// ignore_for_file: deprecated_member_use

import 'package:absensi_app/providers/face/encode_provider.dart';
import 'package:absensi_app/providers/face_reenrollment_provider.dart';
import 'package:absensi_app/screens/karyawan/menu_faceid/take_face.dart';
import 'package:absensi_app/screens/karyawan/more_setting/pengajuan_ulang_wajah/pengajuan_ulang_wajah.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/dto/face_reenrollment.dart';

class HomeFace extends StatefulWidget {
  const HomeFace({super.key});

  @override
  State<HomeFace> createState() => _HomeFaceState();
}

class _HomeFaceState extends State<HomeFace> {
  bool? _faceRegistered;
  bool _loading = true;
  List<FaceReenrollment> _recentRequests = [];

  @override
  void initState() {
    super.initState();
    _checkFaceRegistration();
  }

  Future<void> _checkFaceRegistration() async {
    final encodingProvider =
        Provider.of<FaceEncodingProvider>(context, listen: false);
    final reenrollProvider =
        Provider.of<FaceReenrollmentProvider>(context, listen: false);

    final registered = await encodingProvider.isFaceRegistered();

    if (!mounted) return;

    if (registered == true) {
      await reenrollProvider.fetchRequests(limit: 10);
      _recentRequests = reenrollProvider.requests;
    }

    if (!mounted) return;

    setState(() {
      _faceRegistered = registered;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.face_retouching_natural, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Identifikasi Wajah',
              style: TextStyle(
                color: Colors.black87,
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _checkFaceRegistration,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 170),
                      if (_faceRegistered != true) ...[
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/Face.png',
                                width: 200,
                                height: 200,
                              ),
                              const Text(
                                'Silakan Lakukan Registrasi Wajah \n  Terlebih Dahulu.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const TakeFace()),
                                  );
                                },
                                child: const Text('Daftar Face ID'),
                              ),
                            ],
                          ),
                        )
                      ] else ...[
                        Card(
                          color: Colors.orange[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.verified_user,
                                        color: Colors.green, size: 28),
                                    SizedBox(width: 10),
                                    Text(
                                      "Registrasi Wajah Berhasil",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Anda sudah melakukan registrasi wajah.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Ajukan ulang jika data wajah sudah tidak sesuai.",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_recentRequests.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Colors.blue[50], // Latar belakang biru lembut
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.history_edu,
                                        color: Colors.indigo),
                                    SizedBox(width: 8),
                                    Text(
                                      'Riwayat Pengajuan Wajah',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _recentRequests.length,
                                  itemBuilder: (context, index) {
                                    final request = _recentRequests[index];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '📝 Alasan:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(request.alasan),
                                          const SizedBox(height: 8),
                                          const Text(
                                            '📌 Status:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: request.status ==
                                                      'diterima'
                                                  ? Colors.green.shade100
                                                  : request.status == 'ditolak'
                                                      ? Colors.red.shade100
                                                      : Colors.orange.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              request.status!.toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: request.status ==
                                                        'DISETUJUI'
                                                    ? Colors.green
                                                    : request.status ==
                                                            'DITOLAK'
                                                        ? Colors.red
                                                        : Colors.orange,
                                              ),
                                            ),
                                          ),
                                          if (request.catatan != null) ...[
                                            const SizedBox(height: 8),
                                            const Text(
                                              '📄 Catatan:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(request.catatan!),
                                          ]
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8), // untuk jarak vertikal luar
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16), // jarak dalam
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Text(
                                "Belum ada pengajuan ulang wajah",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54),
                              ),
                            ),
                          ),
                        ]
                      ]
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: (_faceRegistered == true)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PengajuanUlangWajah(),
                  ),
                );
              },
              child: const Icon(Icons.add_circle),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
