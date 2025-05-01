import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/face_verification_provider.dart';

class VerifyFace extends StatefulWidget {
  const VerifyFace({super.key});

  @override
  State<VerifyFace> createState() => _VerifyFaceState();
}

class _VerifyFaceState extends State<VerifyFace> {
  late CameraController _cameraController;
  bool _isCameraReady = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras
          .firstWhere((c) => c.lensDirection == CameraLensDirection.front);

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
    } catch (e) {
      debugPrint('Gagal inisialisasi kamera: $e');
    }
  }

  Future<void> _captureAndVerifyFace() async {
    try {
      final XFile xfile = await _cameraController.takePicture();
      File originalFile = File(xfile.path);

      File compressedFile = await _compressImage(originalFile);

      setState(() {
        _imageFile = compressedFile;
      });

      final faceVerifier =
          Provider.of<FaceVerificationProvider>(context, listen: false);

      await faceVerifier.verifyFace(compressedFile);

      // ✅ Tambahkan bagian ini untuk kembali ke halaman sebelumnya
      if (faceVerifier.isVerified) {
        Navigator.pop(context, true); // Kirim sinyal berhasil
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wajah tidak cocok")),
        );
      }
    } catch (e) {
      debugPrint('Error mengambil/verifikasi wajah: $e');
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
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: _cameraController.value.aspectRatio,
                  child: CameraPreview(_cameraController),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed:
                      faceVerifier.isVerifying ? null : _captureAndVerifyFace,
                  icon: const Icon(Icons.camera),
                  label: const Text('Ambil & Verifikasi Wajah'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 16),
                if (_imageFile != null) Image.file(_imageFile!, height: 200),
                if (faceVerifier.isVerifying)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                if (faceVerifier.statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Result: ${faceVerifier.statusMessage}'),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
