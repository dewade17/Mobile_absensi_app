// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:absensi_app/dto/attendancearrival.dart';
import 'package:absensi_app/dto/location.dart';
import 'package:absensi_app/providers/attendance_arrival.dart';
import 'package:absensi_app/providers/location_provider.dart';
import 'package:absensi_app/providers/face/verify_provider.dart';
import 'package:absensi_app/screens/karyawan/menu_faceid/verify_face.dart';
import 'package:absensi_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AbsensiKedatangan extends StatefulWidget {
  const AbsensiKedatangan({super.key});

  @override
  State<AbsensiKedatangan> createState() => _AbsensiKedatanganState();
}

class _AbsensiKedatanganState extends State<AbsensiKedatangan> {
  late GoogleMapController mapController;
  LatLng _initialPosition = const LatLng(-8.409518, 115.188919);
  Set<Marker> _markers = {};
  bool _isInRadius = false;
  bool _locationLoaded = false;
  Location? _lokasiKantor;
  Position? _currentPosition;
  bool _hasArrivedToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadLocationAndPosition();
      if (!mounted) return;
      await _checkIfAlreadyArrived();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _loadLocationAndPosition() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.fetchLocations();

    if (!mounted) return;

    if (locationProvider.locations.isNotEmpty) {
      _lokasiKantor = locationProvider.locations.first;
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final currentLatLng = LatLng(position.latitude, position.longitude);

    final distance = Geolocator.distanceBetween(
      currentLatLng.latitude,
      currentLatLng.longitude,
      _lokasiKantor!.latitude,
      _lokasiKantor!.longitude,
    );

    if (!mounted) return;

    setState(() {
      _initialPosition = currentLatLng;
      _currentPosition = position;
      _isInRadius = distance <= _lokasiKantor!.radius;
      _locationLoaded = true;

      _markers = {
        Marker(
          markerId: const MarkerId('user'),
          position: currentLatLng,
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        Marker(
          markerId: const MarkerId('kantor'),
          position: LatLng(_lokasiKantor!.latitude, _lokasiKantor!.longitude),
          infoWindow: InfoWindow(title: _lokasiKantor!.namaLokasi),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });

    try {
      if (mounted) {
        mapController.animateCamera(CameraUpdate.newLatLng(currentLatLng));
      }
    } catch (_) {}
  }

  Future<void> _checkIfAlreadyArrived() async {
    final provider =
        Provider.of<AttendanceArrivalProvider>(context, listen: false);
    final todayArrival = await provider.fetchTodayArrival();

    if (!mounted) return;

    if (todayArrival != null) {
      final now = DateTime.now();
      final tgl = todayArrival.tanggal.toLocal(); // pastikan ke local time

      setState(() {
        _hasArrivedToday = tgl.year == now.year &&
            tgl.month == now.month &&
            tgl.day == now.day;
      });
    } else {
      setState(() => _hasArrivedToday = false);
    }
  }

  Future<void> _handleFaceVerificationAndAbsen() async {
    // Navigasi ke halaman verifikasi wajah
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerifyFace()),
    );

    if (!mounted) return; // <-- WAJIB setelah await navigasi

    final faceVerifier =
        Provider.of<FaceVerificationProvider>(context, listen: false);

    if (faceVerifier.isVerified) {
      // Ambil user ID dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final userId = prefs.getString('user_id');
      if (userId == null || _currentPosition == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal ambil data user/lokasi")),
        );
        return;
      }

      final arrivalProvider =
          Provider.of<AttendanceArrivalProvider>(context, listen: false);
      final now = DateTime.now();
      final attendance = Attendancearrival(
        arrivalId: '',
        userId: userId,
        tanggal: DateTime(now.year, now.month, now.day),
        jamMasuk: now,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        faceVerified: true,
        createdAt: now,
        updatedAt: now,
      );
      final success = await arrivalProvider.createAttendanceArrival(attendance);
      if (!mounted) return;

      if (success) {
        setState(() => _hasArrivedToday = true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Absensi berhasil")),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Gagal menyimpan absensi")),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Wajah tidak cocok")),
      );
    }
  }

  Widget _buildStatusCard() {
    final now = DateTime.now();
    final formattedDate = DateFormat("EEEE, dd MMMM yyyy", 'id_ID').format(now);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF176),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lokasiKantor?.namaLokasi ??
                        'Dinas Komunikasi dan Informatika',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Status:', style: TextStyle(color: Colors.black87)),
                Text(
                  _hasArrivedToday ? "Sudah\nabsen" : "Belum\nabsen",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _hasArrivedToday ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lokasiProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Kedatangan'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: lokasiProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lokasiKantor == null
              ? const Center(child: Text("Lokasi kantor belum tersedia"))
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _initialPosition,
                        zoom: 16.0,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: _markers,
                      circles: {
                        Circle(
                          circleId: const CircleId("radius"),
                          center: LatLng(_lokasiKantor!.latitude,
                              _lokasiKantor!.longitude),
                          radius: _lokasiKantor!.radius.toDouble(),
                          strokeColor: Colors.blueAccent,
                          fillColor: Colors.blue.withOpacity(0.1),
                          strokeWidth: 2,
                        )
                      },
                    ),
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: _buildStatusCard(),
                    ),
                    if (_locationLoaded)
                      Positioned(
                        bottom: 30,
                        left: 20,
                        right: 20,
                        child: ElevatedButton(
                          onPressed: (_isInRadius && !_hasArrivedToday)
                              ? _handleFaceVerificationAndAbsen
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInRadius
                                ? (_hasArrivedToday
                                    ? Colors.grey
                                    : Colors.green)
                                : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _isInRadius
                                ? (_hasArrivedToday
                                    ? 'Sudah absen masuk'
                                    : 'Verifikasi Wajah & Absen Masuk')
                                : 'Di luar radius kantor',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
