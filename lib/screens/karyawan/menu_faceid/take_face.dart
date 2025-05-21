// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:async';
import 'dart:io';
import 'package:absensi_app/providers/face/encode_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

class TakeFace extends StatefulWidget {
  const TakeFace({super.key});

  @override
  State<TakeFace> createState() => _TakeFaceState();
}

class _TakeFaceState extends State<TakeFace> {
  late CameraController _cameraController;
  late FaceDetector _faceDetector;
  bool _isCameraReady = false;
  bool _isSaving = false;
  File? _capturedImage;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableContours: true,
        enableLandmarks: true,
      ),
    );
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
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      debugPrint('❌ Gagal inisialisasi kamera: $e');
    }
  }

  Future<void> _captureAndSubmitFace() async {
    if (_isSaving) return;

    try {
      _isSaving = true;
      final XFile xfile = await _cameraController.takePicture();
      final File file = File(xfile.path);

      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.length == 1) {
        await _audioPlayer.play(AssetSource('audio/kamera.mp3'));

        final savedFile = await file.copy(
          '${(await getTemporaryDirectory()).path}/face.jpg',
        );

        // 🔥 Kompres gambar
        final compressedFile = await _compressImage(savedFile);

        setState(() {
          _capturedImage = compressedFile;
        });

        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ User belum login')),
          );
          return;
        }

        // ✅ Pakai Provider terbaru
        final faceEncoder =
            Provider.of<FaceEncodingProvider>(context, listen: false);
        final success =
            await faceEncoder.encodeAndSaveFace(compressedFile, userId);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Wajah berhasil disimpan!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '❌ Gagal menyimpan wajah: ${faceEncoder.statusMessage}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Pastikan hanya 1 wajah di kamera')),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saat deteksi wajah: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      _isSaving = false;
    }
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        path.join(dir.path, 'compressed_${path.basename(file.path)}');

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60,
    );

    if (compressedFile == null) {
      throw Exception('❌ Gagal mengompres gambar.');
    }

    return File(compressedFile.path);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambil Wajah')),
      body: _isCameraReady
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: _cameraController.value.aspectRatio,
                  child: CameraPreview(_cameraController),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _captureAndSubmitFace,
                  icon: const Icon(Icons.camera),
                  label: const Text('Ambil & Simpan Wajah'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 16),
                if (_capturedImage != null)
                  Image.file(_capturedImage!, height: 200),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
