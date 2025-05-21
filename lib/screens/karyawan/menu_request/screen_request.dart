import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
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
        title: const Text('Request'),
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
                      const Center(child: Text('Belum ada data izin')),
                    ...provider.leaveRequests.map((leave) {
                      final isPending =
                          leave.status == null || leave.status == 'PENDING';
                      return InkWell(
                        onTap: () => _showDetailBottomSheet(context, leave),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 8, right: 8, bottom: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      leave.jenisIzin.toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert,
                                          color: Colors.grey[800]),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditRequestScreen(
                                                leave: leave,
                                              ),
                                            ),
                                          );
                                        } else if (value == 'delete') {
                                          _confirmDelete(context, leave);
                                        }
                                      },
                                      itemBuilder: (_) {
                                        if (isPending) {
                                          return [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: ListTile(
                                                leading: Icon(Icons.edit),
                                                title: Text('Edit'),
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: ListTile(
                                                leading: Icon(Icons.delete),
                                                title: Text('Hapus'),
                                              ),
                                            ),
                                          ];
                                        } else {
                                          return [
                                            PopupMenuItem(
                                              enabled: false,
                                              child: Text(
                                              leave.status ?? 'PENDING',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: (leave.status == null || leave.status == 'PENDING')
                                                  ? Colors.red
                                                  : Colors.green,
                                              ),
                                              ),
                                            ),
                                          ];
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                    children: [
                                    Text(
                                      '${leave.tanggalMulai.toLocal().toString().split(' ')[0]} s/d ${leave.tanggalSelesai.toLocal().toString().split(' ')[0]}',
                                    ),
                                    Text(
                                      leave.status ?? 'PENDING',
                                      style: TextStyle(
                                      color: (leave.status == null || leave.status == 'PENDING')
                                        ? Colors.red
                                        : Colors.green,
                                      ),
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
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
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
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            final bukti = leave.buktiFile ?? '';
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
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Detail Izin',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Inlined detail rows
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jenis Izin: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(leave.jenisIzin)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Keterangan: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(leave.alasan)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tanggal Mulai: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                            child: Text(leave.tanggalMulai
                                .toLocal()
                                .toIso8601String()
                                .split('T')[0])),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tanggal Selesai: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                            child: Text(leave.tanggalSelesai
                                .toLocal()
                                .toIso8601String()
                                .split('T')[0])),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(leave.status ?? 'Pending')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bukti gambar
                  if (bukti.isNotEmpty)
                    if (bukti.startsWith('data:image') && imageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Text('Gagal memuat gambar'),
                        ),
                      )
                    else if (bukti.startsWith('data:application/pdf'))
                      ListTile(
                        leading:
                            const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: const Text('Bukti PDF'),
                        subtitle:
                            const Text('Klik tombol untuk melihat atau unduh'),
                        onTap: () => openBase64Pdf(bukti),
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
