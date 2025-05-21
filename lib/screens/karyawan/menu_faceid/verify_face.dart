// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';
import 'dart:async';
import 'package:absensi_app/providers/face/verify_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class VerifyFace extends StatefulWidget {
  const VerifyFace({super.key});

  @override
  State<VerifyFace> createState() => _VerifyFaceState();
}

class _VerifyFaceState extends State<VerifyFace> {
  late CameraController _cameraController;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  String? _errorMessage; // Untuk pesan error saat wajah tidak cocok
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });

      _captureAndVerifyFace(); // Mulai otomatis
    } catch (e) {
      debugPrint('❌ Gagal inisialisasi kamera: $e');
    }
  }

  Future<void> _captureAndVerifyFace() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final XFile xfile = await _cameraController.takePicture();
      File originalFile = File(xfile.path);

      File compressedFile = await _compressImage(originalFile);

      setState(() {
        _imageFile = compressedFile;
      });

      final faceVerifier =
          Provider.of<FaceVerificationProvider>(context, listen: false);

      final success = await faceVerifier.verifyFace(compressedFile);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ Wajah cocok: ID ${faceVerifier.matchedUserId}')),
        );
        Navigator.pop(context, true); // Keluar kalau cocok
      } else {
        setState(() {
          _errorMessage = "❌ Wajah tidak cocok, silakan ulangi kembali...";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(faceVerifier.statusMessage ?? '❌ Wajah tidak cocok')),
        );

        await Future.delayed(const Duration(seconds: 1));
        _isProcessing = false;
        _captureAndVerifyFace(); // Ulangi capture lagi
      }
    } catch (e) {
      debugPrint('❌ Error mengambil/verifikasi wajah: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error saat verifikasi wajah: $e')),
      );
      Navigator.pop(context, false);
    }
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        path.join(dir.path, 'compressed_${path.basename(file.path)}');

    final compressedXFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60,
    );

    return compressedXFile != null ? File(compressedXFile.path) : file;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faceVerifier = Provider.of<FaceVerificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Wajah'),
      ),
      body: _isCameraReady
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 4),
                    ),
                    child: ClipOval(
                      child: CameraPreview(_cameraController),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (faceVerifier.isVerifying || _isProcessing)
                    const CircularProgressIndicator(),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
