import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class InAppCamera extends StatefulWidget {
  const InAppCamera({super.key});

  @override
  State<InAppCamera> createState() => _InAppCameraState();
}

class _InAppCameraState extends State<InAppCamera> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  // When not null, we show the full-screen preview
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }
      await _startCamera(_selectedCameraIndex);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _startCamera(int index) async {
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera start error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isInitialized = false);
    await _controller?.dispose();
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    if (_selectedCameraIndex != 0) _flashMode = FlashMode.off;
    await _startCamera(_selectedCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    final next = {
      FlashMode.off: FlashMode.always,
      FlashMode.always: FlashMode.torch,
      FlashMode.torch: FlashMode.off,
    }[_flashMode]!;
    try {
      await _controller!.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
      default:
        return Icons.flash_off;
    }
  }

  Color get _flashColor =>
      _flashMode == FlashMode.off ? Colors.white : Colors.amber;

  Future<void> _takePicture() async {
    if (_controller == null || !_isInitialized || _isTakingPicture) return;
    setState(() => _isTakingPicture = true);
    try {
      final XFile file = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          _capturedImage = File(file.path);
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      debugPrint('Take picture error: $e');
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  void _retake() {
    setState(() => _capturedImage = null);
    // Re-start camera in case it was paused
    _startCamera(_selectedCameraIndex);
  }

  void _sendPhoto() {
    if (_capturedImage != null) Navigator.pop(context, _capturedImage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_capturedImage != null) return; // in preview — don't touch camera
    if (_controller == null || !_isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_selectedCameraIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Full-screen preview after capture
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPreview() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen image
          Positioned.fill(
            child: Image.file(
              _capturedImage!,
              fit: BoxFit.contain,
            ),
          ),

          // Top: close (dismiss entire camera)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),

          // Bottom: Retake | Send
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Retake
                GestureDetector(
                  onTap: _retake,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Retake',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // Send
                GestureDetector(
                  onTap: _sendPhoto,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff9D6E2D),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Send',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.send, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Camera viewfinder
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCamera() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isInitialized && _controller != null)
              Positioned.fill(child: CameraPreview(_controller!))
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Top bar: close + flash
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  if (_selectedCameraIndex == 0)
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                        ),
                        child: Icon(
                          _flashIcon,
                          color: _flashColor,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: _switchCamera,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: const Icon(
                        Icons.flip_camera_android,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isTakingPicture ? null : _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isTakingPicture
                            ? Colors.grey
                            : Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _capturedImage != null ? _buildPreview() : _buildCamera();
  }
}
