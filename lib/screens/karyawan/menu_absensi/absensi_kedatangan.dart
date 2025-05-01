// ignore: file_names
import 'package:absensi_app/dto/attendancearrival.dart';
import 'package:absensi_app/dto/location.dart';
import 'package:absensi_app/providers/attendance_arrival.dart';
import 'package:absensi_app/providers/face_verification_provider.dart';
import 'package:absensi_app/providers/location_provider.dart';
import 'package:absensi_app/screens/karyawan/menu_faceid/verify_face.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocationAndPosition();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _loadLocationAndPosition() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.fetchLocations();

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
      desiredAccuracy: LocationAccuracy.high,
    );

    final currentLatLng = LatLng(position.latitude, position.longitude);

    final distance = Geolocator.distanceBetween(
      currentLatLng.latitude,
      currentLatLng.longitude,
      _lokasiKantor!.latitude,
      _lokasiKantor!.longitude,
    );

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

    mapController.animateCamera(CameraUpdate.newLatLng(currentLatLng));
  }

  Future<void> _handleFaceVerificationAndAbsen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerifyFace()),
    );

    final faceVerifier =
        Provider.of<FaceVerificationProvider>(context, listen: false);

    if (faceVerifier.isVerified) {
      // Ambil user ID dari shared prefs atau token
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('user_id'); // pastikan kamu simpan user_id di login

      if (userId == null || _currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal ambil data user/lokasi")),
        );
        return;
      }

      final arrivalProvider =
          Provider.of<AttendanceArrivalProvider>(context, listen: false);
      final now = DateTime.now();
      final success = await arrivalProvider.createAttendanceArrival(
        Attendancearrival(
          arrivalId: '', // Provide a unique ID or generate one
          userId: userId,
          tanggal: DateTime(now.year, now.month, now.day),
          jamMasuk: now,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          faceVerified: true,
          createdAt: now, // Use the current timestamp or appropriate value
          updatedAt: now, // Use the current timestamp or appropriate value
        ),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Absensi berhasil")),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Gagal menyimpan absensi")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Wajah tidak cocok")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lokasiProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Kedatangan')),
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
                    if (_locationLoaded)
                      Positioned(
                        bottom: 30,
                        left: 20,
                        right: 20,
                        child: ElevatedButton(
                          onPressed: _isInRadius
                              ? _handleFaceVerificationAndAbsen
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isInRadius ? Colors.green : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _isInRadius
                                ? 'Verifikasi Wajah & Absen Masuk'
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
