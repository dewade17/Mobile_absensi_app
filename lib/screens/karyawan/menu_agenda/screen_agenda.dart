import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:absensi_app/dto/work_agenda_item.dart';
import 'package:absensi_app/providers/agenda_provider.dart';
import 'package:absensi_app/screens/karyawan/menu_agenda/add_agenda_screen.dart';
import 'package:absensi_app/screens/karyawan/menu_agenda/edit_agenda_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class ScreenAgenda extends StatefulWidget {
  const ScreenAgenda({super.key});

  @override
  State<ScreenAgenda> createState() => _ScreenAgendaState();
}

class _ScreenAgendaState extends State<ScreenAgenda> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _limit = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAgendas();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        _loadMoreAgendas();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadAgendas() {
    final provider = Provider.of<WorkAgendaProvider>(context, listen: false);
    provider.fetchWorkAgendas(page: _currentPage, limit: _limit);
  }

  void _loadMoreAgendas() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final provider = Provider.of<WorkAgendaProvider>(context, listen: false);
    await provider.fetchWorkAgendas(
      page: _currentPage,
      limit: _limit,
      append: true, // 🔥 tambahkan opsi append
    );
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        centerTitle: true,
      ),
      body: Consumer<WorkAgendaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.agendas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('❌ ${provider.errorMessage}'));
          }

          if (provider.agendas.isEmpty) {
            return const Center(child: Text('Belum ada agenda.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // 🔄 Reset ke page pertama dan load ulang
              _currentPage = 1;
              await provider.fetchWorkAgendas(
                page: _currentPage,
                limit: _limit,
                append: false,
              );
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.agendas.length + 1,
              itemBuilder: (context, index) {
                if (index == provider.agendas.length) {
                  return _isLoadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox();
                }

                final agenda = provider.agendas[index];
                final item = agenda.items?.isNotEmpty == true
                    ? agenda.items!.first
                    : null;

                return InkWell(
                  onTap: () {
                    if (item != null) {
                      _showAgendaDetailBottomSheet(
                        context,
                        item,
                        agenda.createdAt ?? DateTime.now(),
                        agenda.agendaId!,
                      );
                    }
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item != null
                                    ? DateFormat('dd MMM yyyy', 'id_ID')
                                        .format(item.tanggal!.toLocal())
                                    : 'Tidak ada tanggal',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item != null
                                    ? '${DateFormat('HH:mm', 'id_ID').format(item.jamMulai!.toLocal())} - ${DateFormat('HH:mm', 'id_ID').format(item.jamSelesai!.toLocal())}'
                                    : 'Tidak ada jam',
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAgendaScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAgendaDetailBottomSheet(BuildContext context, WorkagendaItem item,
      DateTime createdAt, String agendaId) {
    final bukti = item.buktiFotoUrl ?? '';
    final isBase64Image = bukti.startsWith('data:image');
    final isPdf = bukti.startsWith('data:application/pdf');

    Uint8List? imageBytes;
    if (isBase64Image) {
      try {
        var cleaned = bukti.split(',').last;
        imageBytes = base64Decode(cleaned);
      } catch (_) {
        imageBytes = null;
      }
    }

    final now = DateTime.now();
    final isEditable = now.difference(createdAt).inHours < 24;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle drag
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

                  Text(
                    'Detail Agenda',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(item.tanggal!.toLocal())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jam Mulai: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(DateFormat('HH:mm', 'id_ID')
                            .format(item.jamMulai!.toLocal())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jam Selesai: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(DateFormat('HH:mm', 'id_ID')
                            .format(item.jamSelesai!.toLocal())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Deskripsi Pekerjaan: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(item.deskripsiPekerjaan ?? '-'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bukti Foto atau PDF
                  if (bukti.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bukti Foto:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (isBase64Image && imageBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Text('Gagal memuat gambar'),
                            ),
                          )
                        else if (isPdf)
                          ListTile(
                            leading: const Icon(Icons.picture_as_pdf,
                                color: Colors.red),
                            title: const Text('Bukti PDF'),
                            subtitle: const Text('Klik untuk melihat/unduh'),
                            onTap: () => openBase64Pdf(bukti),
                          )
                        else
                          const Text('Format bukti tidak dikenali'),
                      ],
                    )
                  else
                    const Text('Tidak ada bukti yang diunggah'),

                  const SizedBox(height: 24),

                  // Tombol Aksi
                  if (isEditable)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text("Edit"),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditAgendaScreen(
                                  agendaId: agendaId, // dari objek agenda
                                  item:
                                      item, // WorkagendaItem yang ingin diedit
                                ),
                              ),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text("Hapus"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            final provider = Provider.of<WorkAgendaProvider>(
                                context,
                                listen: false);
                            await provider.deleteWorkAgenda(agendaId);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    )
                  else
                    Center(
                      child: Text(
                        "Batas waktu edit & hapus telah habis.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
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
