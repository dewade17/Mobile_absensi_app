// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'package:absensi_app/dto/attendace_departure.dart';
import 'package:absensi_app/dto/location.dart';
import 'package:absensi_app/providers/attendance_departure_provider.dart';
import 'package:absensi_app/providers/location_provider.dart';
import 'package:absensi_app/providers/face/verify_provider.dart';
import 'package:absensi_app/screens/karyawan/menu_faceid/verify_face.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AbsensiKepulangan extends StatefulWidget {
  const AbsensiKepulangan({super.key});

  @override
  State<AbsensiKepulangan> createState() => _AbsensiKepulanganState();
}

class _AbsensiKepulanganState extends State<AbsensiKepulangan> {
  late GoogleMapController mapController;
  LatLng _initialPosition = const LatLng(-8.409518, 115.188919);
  Set<Marker> _markers = {};
  bool _isInRadius = false;
  bool _locationLoaded = false;
  Location? _lokasiKantor;
  Position? _currentPosition;
  bool _hasDepartedToday = false;

 @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadLocationAndPosition();
      if (!mounted) return; // <--- TAMBAH INI!
      await _checkIfAlreadyDeparted();
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
        permission == LocationPermission.deniedForever) return;

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

Future<void> _checkIfAlreadyDeparted() async {
    final provider =
        Provider.of<AttendanceDepartureProvider>(context, listen: false);
    final todayDeparture = await provider.fetchTodayDeparture();

    if (!mounted) return;

    if (todayDeparture != null) {
      final now = DateTime.now();
      final tgl = todayDeparture.tanggal.toLocal(); // ⬅️ penting

      setState(() {
        _hasDepartedToday = tgl.year == now.year &&
            tgl.month == now.month &&
            tgl.day == now.day;
      });
    } else {
      setState(() => _hasDepartedToday = false);
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
                    _lokasiKantor?.namaLokasi ?? 'Kantor Winni Code',
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
                  _hasDepartedToday ? "Sudah\nabsen" : "Belum\nabsen",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _hasDepartedToday ? Colors.green : Colors.red,
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

  Future<void> _handleFaceVerificationAndAbsenPulang() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerifyFace()),
    );

    if (!mounted) return; // setelah navigasi

    final faceVerifier =
        Provider.of<FaceVerificationProvider>(context, listen: false);

    if (faceVerifier.isVerified) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final userId = prefs.getString('user_id');
      if (!mounted || userId == null || _currentPosition == null) return;

      final departureProvider =
          Provider.of<AttendanceDepartureProvider>(context, listen: false);
      final now = DateTime.now();

      final success = await departureProvider.createDeparture(
        AttendaceDeparture(
          departureId: '',
          userId: userId,
          tanggal: DateTime(now.year, now.month, now.day),
          jamKeluar: now,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          faceVerified: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;

      if (success) {
        setState(() => _hasDepartedToday = true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Absen pulang berhasil")),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Gagal menyimpan absen pulang")),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Wajah tidak cocok")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final lokasiProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Kepulangan')),
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
                          strokeColor: Colors.redAccent,
                          fillColor: Colors.red.withOpacity(0.1),
                          strokeWidth: 2,
                        )
                      },
                    ),
                    Positioned(
                      top: 40,
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
                          onPressed: (_isInRadius && !_hasDepartedToday)
                              ? _handleFaceVerificationAndAbsenPulang
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInRadius
                                ? (_hasDepartedToday ? Colors.grey : Colors.red)
                                : Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                          ),
                          child: Text(
                            _isInRadius
                                ? (_hasDepartedToday
                                    ? 'Sudah absen pulang'
                                    : 'Verifikasi Wajah & Absen Pulang')
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
