import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

List<CameraDescription> _cameras = <CameraDescription>[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\n${e.description}');
  }
  runApp(const CameraApp());
}

class CameraApp extends StatelessWidget {
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kamera Modern',
      theme: ThemeData.dark(), // Tema gelap ala kamera profesional
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Selamat Datang',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aplikasi Kamera Modern & Minimalis',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SimpleCameraScreen()),
                );
              },
              icon: const Icon(Icons.camera_alt, size: 28),
              label: const Text('Buka Kamera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.tealAccent.withOpacity(0.5),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleCameraScreen extends StatefulWidget {
  const SimpleCameraScreen({super.key});

  @override
  State<SimpleCameraScreen> createState() => _SimpleCameraScreenState();
}

class _SimpleCameraScreenState extends State<SimpleCameraScreen> {
  CameraController? controller;
  XFile? imageFile;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    if (_cameras.isNotEmpty) {
      _initCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initCamera(int index) async {
    if (controller != null) {
      await controller!.dispose();
    }

    controller = CameraController(_cameras[index], ResolutionPreset.high);
    try {
      await controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Gagal inisialisasi kamera: $e');
    }
  }

  void _toggleCamera() {
    if (_cameras.length > 1) {
      setState(() {
        // Ganti antara kamera utama (0) dan depan (1)
        _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
      });
      _initCamera(_selectedCameraIndex);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jika kamera belum siap
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Selalu pertahankan CameraPreview di layar paling belakang
          Positioned.fill(
            child: CameraPreview(controller!),
          ),
          
          // 2. Jika ada foto, tutupi layar dengan gambar hasil jepretan
          if (imageFile != null) ...[
            Positioned.fill(
              child: Image.file(
                File(imageFile!.path),
                fit: BoxFit.contain,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(bottom: 40, top: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          imageFile = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      label: const Text(
                        'Ulangi',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          // Menyimpan foto hasil jepretan ke Galeri HP
                          await Gal.putImage(imageFile!.path);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Foto berhasil disimpan ke Galeri!')),
                            );
                            setState(() {
                              imageFile = null; // Kembali ke mode kamera
                            });
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menyimpan: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check, color: Colors.greenAccent, size: 28),
                      label: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] 
          // 3. Jika belum memotret, tampilkan tombol kontrol kamera
          else ...[
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(bottom: 40, top: 20),
                color: Colors.black.withOpacity(0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 48), // Spacer untuk keseimbangan
                    // Tombol Jepret (Shutter) Kustom
                    GestureDetector(
                      onTap: () async {
                        try {
                          final XFile file = await controller!.takePicture();
                          setState(() {
                            imageFile = file;
                          });
                        } catch (e) {
                          print('Gagal mengambil gambar: $e');
                        }
                      },
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Tombol Ganti Kamera Depan/Belakang
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                      onPressed: _toggleCamera,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 4. Tombol Back di pojok kiri atas
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  }