import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:absensi_app/providers/recap_attendance_provider.dart';
import 'package:absensi_app/dto/recap_attendance.dart';

class DataAbsensiScreen extends StatefulWidget {
  const DataAbsensiScreen({super.key});

  @override
  State<DataAbsensiScreen> createState() => _DataAbsensiScreenState();
}

class _DataAbsensiScreenState extends State<DataAbsensiScreen> {
  late ScrollController _scrollController;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<int> _years =
      List.generate(6, (index) => DateTime.now().year - index);
  final List<String> _months = List.generate(12,
      (index) => DateFormat('MMMM', 'id_ID').format(DateTime(0, index + 1)));

  String get _filterKey =>
      '${_selectedYear.toString().padLeft(4, '0')}-${_selectedMonth.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<RecapAttendanceProvider>(context, listen: false);
      provider.fetchRecapAttendance(tanggal: _filterKey, refresh: true);
    });
  }

  void _scrollListener() {
    final provider =
        Provider.of<RecapAttendanceProvider>(context, listen: false);
    final meta = provider.getMeta(_filterKey);

    if (!provider.isLoadingFor(_filterKey) &&
        meta != null &&
        meta.currentPage < meta.totalPages &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      provider.fetchRecapAttendance(
          tanggal: _filterKey, page: meta.currentPage + 1);
    }
  }

  Future<void> _refreshData() async {
    final provider =
        Provider.of<RecapAttendanceProvider>(context, listen: false);
    await provider.fetchRecapAttendance(tanggal: _filterKey, refresh: true);
  }

  List<Map<String, dynamic>> groupAttendanceByDate(
      List<RecapAttendance> arrivals, List<RecapAttendance> departures) {
    Map<String, Map<String, dynamic>> grouped = {};

    for (var item in [...arrivals, ...departures]) {
      if (item.tanggal == null) continue;
      final key = DateFormat('yyyy-MM-dd').format(item.tanggal!);
      grouped.putIfAbsent(key, () {
        return {
          'tanggal': item.tanggal,
          'jamMasuk': null,
          'jamKeluar': null,
        };
      });
      if (item.arrivalId != null && item.jamMasuk != null) {
        grouped[key]!['jamMasuk'] = item.jamMasuk;
      }
      if (item.departureId != null && item.jamKeluar != null) {
        grouped[key]!['jamKeluar'] = item.jamKeluar;
      }
    }

    return grouped.values.toList()
      ..sort((a, b) =>
          (b['tanggal'] as DateTime).compareTo(a['tanggal'] as DateTime));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Absensi')),
      body: Column(
        children: [
          // Filter Bulan & Tahun
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_months[i]),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMonth = val);
                        _refreshData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    items: _years
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYear = val);
                        _refreshData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // List Absensi
          Expanded(
            child: Consumer<RecapAttendanceProvider>(
              builder: (context, provider, child) {
                final arrivals = provider.getArrivals(_filterKey);
                final departures = provider.getDepartures(_filterKey);
                final isLoading = provider.isLoadingFor(_filterKey);
                final errorMessage = provider.getErrorFor(_filterKey);

                final groupedAttendance =
                    groupAttendanceByDate(arrivals, departures);

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: Builder(builder: (_) {
                    if (isLoading && groupedAttendance.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (errorMessage != null) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(child: Text('Error: $errorMessage')),
                        ],
                      );
                    }

                    if (groupedAttendance.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('Belum ada data absensi.')),
                        ],
                      );
                    }

                    // Di dalam ListView.builder bagian Consumer
                    return ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: groupedAttendance.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < groupedAttendance.length) {
                          final data = groupedAttendance[index];

                          final tanggal =
                              (data['tanggal'] as DateTime?)?.toLocal();
                          final jamMasuk =
                              (data['jamMasuk'] as DateTime?)?.toLocal();
                          final jamKeluar =
                              (data['jamKeluar'] as DateTime?)?.toLocal();

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 26),
                                    child: Text(
                                      (tanggal != null)
                                          ? DateFormat(
                                                  'EEEE, dd MMMM yyyy', 'id_ID')
                                              .format(tanggal)
                                          : 'Tanggal tidak tersedia',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              color: Colors.red, size: 30),
                                          const SizedBox(width: 5),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("Jam Masuk"),
                                              Text(
                                                jamMasuk != null
                                                    ? DateFormat('HH:mm')
                                                        .format(jamMasuk)
                                                    : "-",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              color: Colors.red, size: 30),
                                          const SizedBox(width: 5),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("Jam Pulang"),
                                              Text(
                                                jamKeluar != null
                                                    ? DateFormat('HH:mm')
                                                        .format(jamKeluar)
                                                    : "-",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // Loading ketika scroll
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
