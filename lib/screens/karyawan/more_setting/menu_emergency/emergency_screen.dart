import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/emergency_attendance_provider.dart';
import 'package:absensi_app/dto/emergency_attendance.dart';
import 'package:intl/intl.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Provider.of<EmergencyAttendanceProvider>(context, listen: false)
        .fetchEmergencies();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmergencyAttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              "Absensi Darurat",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.errorMessage != null
                ? Center(child: Text(provider.errorMessage!))
                : provider.emergencies.isEmpty
                    ? Column(
                        children: [
                          SizedBox(height: 130),
                          Image.asset(
                            'assets/images/Empty-data.png',
                            fit: BoxFit.cover,
                          ),
                          const Center(
                              child: Text(
                            "Belum Ada Data Absensi Darurat.",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ))
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.emergencies.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final EmergencyAttendance data =
                              provider.emergencies[index];
                          return ListTile(
                            leading: Icon(
                              data.jenis == 'MASUK'
                                  ? Icons.login
                                  : Icons.logout,
                              color: data.jenis == 'MASUK'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(
                                "Jenis: ${data.jenis} - ${DateFormat('yyyy-MM-dd').format(data.tanggal.toLocal())}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Jam: ${DateFormat('HH:mm').format(data.jamMasuk.toLocal())}"),
                                if (data.alasan != null)
                                  Text("Alasan: ${data.alasan}"),
                              ],
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/emergency-absensi');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
