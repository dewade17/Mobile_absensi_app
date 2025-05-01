import 'package:absensi_app/screens/karyawan/menu_faceid/take_face.dart';
import 'package:absensi_app/screens/karyawan/menu_faceid/verify_face.dart';
import 'package:flutter/material.dart';

class HomeFace extends StatefulWidget {
  const HomeFace({super.key});

  @override
  State<HomeFace> createState() => _HomeFaceState();
}

class _HomeFaceState extends State<HomeFace> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Face ID'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Selamat datang di Home Face ID',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aksi yang ingin dilakukan saat tombol ditekan
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TakeFace()),
                );
              },
              child: const Text('Mulai Face ID'),
            ),
            ElevatedButton(
              onPressed: () {
                // Aksi yang ingin dilakukan saat tombol ditekan
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerifyFace()),
                );
              },
              child: const Text('verify Face ID'),
            ),
          ],
        ),
      ),
    );
  }
}
