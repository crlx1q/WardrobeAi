import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import 'scan_confirm_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _lens = CameraLensDirection.back;
  bool _cameraAvailable = true;
  FlashMode _flash = FlashMode.off;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _cameraAvailable = false);
        return;
      }
      final cam = _cameras.firstWhere(
        (c) => c.lensDirection == _lens,
        orElse: () => _cameras.first,
      );
      _lens = cam.lensDirection;
      final controller = CameraController(cam, ResolutionPreset.high, enableAudio: false);
      _controller = controller;
      await controller.initialize();
      try {
        await controller.setFlashMode(_flash);
      } catch (_) {}
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _cameraAvailable = false);
    }
  }

  bool get _hasFrontAndBack =>
      _cameras.any((c) => c.lensDirection == CameraLensDirection.back) &&
      _cameras.any((c) => c.lensDirection == CameraLensDirection.front);

  Future<void> _switchCamera() async {
    if (!_hasFrontAndBack) return;
    _lens = _lens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _controller?.dispose();
    _controller = null;
    if (mounted) setState(() {});
    await _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null) return;
    // Front cameras usually have no torch.
    if (_lens == CameraLensDirection.front) return;
    final next = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await c.setFlashMode(next);
      setState(() => _flash = next);
    } catch (_) {}
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      await _openConfirm(file.path);
    } catch (e) {
      if (mounted) showSnack(context, 'Не удалось сделать фото', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      await _openConfirm(picked.path);
    } catch (e) {
      if (mounted) showSnack(context, 'Не удалось открыть галерею', error: true);
    }
  }

  Future<void> _openConfirm(String path) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ScanConfirmScreen(imagePath: path)),
    );
    if (saved == true && mounted) {
      showSnack(context, 'Вещь добавлена в гардероб');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          const _ScanOverlay(),
          _buildTopBar(),
          _buildControls(),
          if (_busy) Container(color: Colors.black45, child: const LoadingView(label: 'Обработка…')),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (!_cameraAvailable) {
      return Container(
        color: const Color(0xFF2A2724),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Камера недоступна на этом устройстве.\nИспользуйте кнопку «Галерея», чтобы выбрать фото.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const ColoredBox(color: Colors.black, child: LoadingView());
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: c.value.previewSize?.height ?? 1,
        height: c.value.previewSize?.width ?? 1,
        child: CameraPreview(c),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text(
                'Поместите вещь в центр кадра при хорошем свете',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ),
          if (_cameraAvailable && _hasFrontAndBack) ...[
            const SizedBox(width: 10),
            _roundButton(Icons.cameraswitch_outlined, _switchCamera),
          ],
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(32, 20, 32, MediaQuery.of(context).padding.bottom + 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _controlButton(Icons.photo_library_outlined, 'Галерея', _pickFromGallery),
            _CaptureButton(onTap: _cameraAvailable ? _capture : _pickFromGallery),
            _controlButton(
              _flash == FlashMode.off ? Icons.flash_off : Icons.flash_on,
              'Вспышка',
              (_cameraAvailable && _lens == CameraLensDirection.back) ? _toggleFlash : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CaptureButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        ),
      ),
    );
  }
}

/// Scanner bracket frame + animated scanning line (no fake attribute chips).
class _ScanOverlay extends StatefulWidget {
  const _ScanOverlay();

  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final frameW = w * 0.82;
        final frameH = h * 0.5;
        final left = (w - frameW) / 2;
        final top = (h - frameH) / 2 - 20;

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: frameW,
              height: frameH,
              child: CustomPaint(painter: _FramePainter()),
            ),
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return Positioned(
                  left: left + 12,
                  width: frameW - 24,
                  top: top + 12 + (frameH - 24) * _anim.value,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.6), blurRadius: 8)],
                      gradient: LinearGradient(colors: [
                        AppColors.accent.withValues(alpha: 0),
                        AppColors.accent,
                        AppColors.accent.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const r = 28.0;
    const corner = 32.0;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(r));
    final path = Path();
    path.moveTo(0, corner + r);
    path.lineTo(0, r);
    path.arcToPoint(const Offset(r, 0), radius: const Radius.circular(r));
    path.lineTo(corner + r, 0);
    path.moveTo(size.width - corner - r, 0);
    path.lineTo(size.width - r, 0);
    path.arcToPoint(Offset(size.width, r), radius: const Radius.circular(r));
    path.lineTo(size.width, corner + r);
    path.moveTo(size.width, size.height - corner - r);
    path.lineTo(size.width, size.height - r);
    path.arcToPoint(Offset(size.width - r, size.height), radius: const Radius.circular(r));
    path.lineTo(size.width - corner - r, size.height);
    path.moveTo(corner + r, size.height);
    path.lineTo(r, size.height);
    path.arcToPoint(Offset(0, size.height - r), radius: const Radius.circular(r));
    path.lineTo(0, size.height - corner - r);
    canvas.drawPath(path, paint);
    canvas.drawRRect(rrect, paint..color = Colors.white.withValues(alpha: 0.2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
