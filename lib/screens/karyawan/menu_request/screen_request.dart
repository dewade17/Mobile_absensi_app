// ignore_for_file: unnecessary_to_list_in_spreads, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:absensi_app/utils/colors.dart';
import 'package:open_file/open_file.dart';
import 'package:absensi_app/dto/leaverequest.dart';
import 'package:absensi_app/providers/provider_leaverequest.dart';
import 'package:absensi_app/screens/karyawan/menu_request/add_request_screen.dart';
import 'package:absensi_app/screens/karyawan/menu_request/edit_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class ScreenRequest extends StatefulWidget {
  const ScreenRequest({super.key});

  @override
  State<ScreenRequest> createState() => _ScreenRequestState();
}

class _ScreenRequestState extends State<ScreenRequest> {
  @override
  void initState() {
    super.initState();
    // Fetch leave requests saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveRequestProvider>(context, listen: false)
          .fetchLeaveRequests();
    });
  }

  Future<void> _refreshData() async {
    await Provider.of<LeaveRequestProvider>(context, listen: false)
        .fetchLeaveRequests();
  }

  void _confirmDelete(BuildContext context, Leaverequest leave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus request ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Panggil provider.deleteLeaveRequest atau metode serupa
              context
                  .read<LeaveRequestProvider>()
                  .deleteLeaveRequest(leave.leaveId!);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Cuti/Izin/Sakit'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Consumer<LeaveRequestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text('${provider.errorMessage}'));
          }
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (provider.leaveRequests.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                            ),
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: Opacity(
                                opacity: 0.5,
                                child: Image.asset(
                                  'assets/images/Empty-data.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const Text(
                              'Saat Ini Kamu Tidak Memiliki Pengajuan.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                    ...provider.leaveRequests.map((leave) {
                      final isPending =
                          leave.status == null || leave.status == 'PENDING';
                      return InkWell(
                        onTap: () => _showDetailBottomSheet(context, leave),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.description,
                                        color: Colors.blueAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        leave.jenisIzin.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (isPending)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EditRequestScreen(
                                                        leave: leave),
                                              ),
                                            );
                                          } else if (value == 'delete') {
                                            _confirmDelete(context, leave);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit,
                                                  color: Colors.blueAccent),
                                              title: Text('Edit'),
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(Icons.delete,
                                                  color: Colors.redAccent),
                                              title: Text('Hapus'),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left:
                                              4), // Atur padding kiri untuk semua item
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start, // Rapi ke kiri
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Mulai: ${leave.tanggalMulai.toLocal().toString().split(' ')[0]}',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Berakhir: ${leave.tanggalSelesai.toLocal().toString().split(' ')[0]}',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        leave.status?.toUpperCase() ??
                                            'PENDING',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      backgroundColor: (leave.status == null ||
                                              leave.status == 'PENDING')
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRequestScreen()),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showDetailBottomSheet(BuildContext context, Leaverequest leave) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            final bukti = leave.buktiFile;
            final isBase64Image = bukti.startsWith('data:image');
            Uint8List? imageBytes;
            if (isBase64Image) {
              try {
                var cleaned = bukti.split(',').last;
                imageBytes = base64Decode(cleaned);
              } catch (_) {
                imageBytes = null;
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Title
                  Row(
                    children: const [
                      Icon(Icons.description, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Detail Izin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Detail Row 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.assignment,
                          size: 20, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                            children: [
                              const TextSpan(
                                text: 'Jenis Izin: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: leave.jenisIzin),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Detail Row 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 20, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                            children: [
                              const TextSpan(
                                text: 'Keterangan: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: leave.alasan),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tanggal Mulai
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.date_range,
                          size: 20, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                            children: [
                              const TextSpan(
                                text: 'Tanggal Mulai: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                  text: leave.tanggalMulai
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tanggal Selesai
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.event_available,
                          size: 20, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                            children: [
                              const TextSpan(
                                text: 'Tanggal Berakhir: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                  text: leave.tanggalSelesai
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user,
                          size: 20, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                            children: [
                              const TextSpan(
                                text: 'Status: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: leave.status ?? 'Pending'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),
                  const Text(
                    'Bukti Pengajuan:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Bukti
                  if (bukti.isNotEmpty)
                    if (bukti.startsWith('data:image') && imageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Text('Gagal memuat gambar'),
                        ),
                      )
                    else if (bukti.startsWith('data:application/pdf'))
                      Card(
                        color: Colors.red[50],
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf,
                              color: Colors.red),
                          title: const Text('Bukti PDF'),
                          subtitle: const Text('Klik untuk melihat atau unduh'),
                          onTap: () => openBase64Pdf(bukti),
                        ),
                      )
                    else
                      const Text('Format bukti tidak dikenali')
                  else
                    const Text('Tidak ada bukti yang diunggah'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> openBase64Pdf(String base64String) async {
    try {
      final base64Data = base64String.split(',').last;
      final bytes = base64Decode(base64Data);

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/bukti_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Buka file
      await OpenFile.open(file.path);

      // Jadwal penghapusan setelah 10 detik
      Future.delayed(Duration(seconds: 10), () async {
        if (await file.exists()) {
          await file.delete();
          print('🗑️ File sementara dihapus: $filePath');
        }
      });
    } catch (e) {
      print('❌ Gagal membuka atau menghapus PDF: $e');
    }
  }
}
