import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  AuthUser? _savedSession;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _authService.initialize();
    if (!mounted) return;

    final session = await _authService.getSavedSession();
    setState(() {
      _savedSession = session;
      _isOnline = _authService.isOnlineNotifier.value;
    });

    _authService.isOnlineNotifier.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {
        _isOnline = _authService.isOnlineNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    _authService.isOnlineNotifier.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  /// Handles Google OAuth 2.0 Sign-In and Offline fallback
  Future<void> _handleGoogleSignIn({
    bool simulateScopeDenial = false,
    bool simulateOffline = false,
  }) async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle(
        simulateScopeDenial: simulateScopeDenial,
        simulateOffline: simulateOffline,
      );

      if (!mounted) return;

      switch (result.status) {
        case AuthStatus.success:
          _showToast(
            'Selamat datang, ${result.user?.name ?? 'Peternak'}! Terhubung ke Google Drive.',
            isError: false,
          );
          widget.onLogin();
          break;

        case AuthStatus.offlineSuccess:
          _showToast(
            'Mode Offline: Masuk menggunakan sesi lokal (${result.user?.name ?? 'Peternak'}).',
            isWarning: true,
          );
          widget.onLogin();
          break;

        case AuthStatus.permissionDenied:
          // AC 3: Jika Peternak menolak akses Google Drive, aplikasi menampilkan pesan peringatan bahwa izin Drive diperlukan untuk menyimpan data.
          _showPermissionDeniedDialog(result.message);
          break;

        case AuthStatus.offlineNoSession:
          _showOfflineNoSessionDialog(result.message);
          break;

        case AuthStatus.cancelled:
          _showToast('Login Google dibatalkan.', isError: false);
          break;

        case AuthStatus.error:
          _showToast(result.message, isError: true);
          break;
      }
    } finally {
      if (mounted) {
        final updatedSession = await _authService.getSavedSession();
        setState(() {
          _isLoading = false;
          _savedSession = updatedSession;
        });
      }
    }
  }

  /// Handles direct offline session login
  Future<void> _handleOfflineLogin() async {
    setState(() => _isLoading = true);
    final result = await _authService.signInOffline();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.status == AuthStatus.offlineSuccess) {
      _showToast(
        'Mode Offline: Masuk menggunakan sesi lokal (${result.user?.name}).',
        isWarning: true,
      );
      widget.onLogin();
    } else {
      _showOfflineNoSessionDialog(result.message);
    }
  }

  /// Shows Alert Dialog when Google Drive scope is denied (AC 3)
  void _showPermissionDeniedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Izin Google Drive Diperlukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleGoogleSignIn();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF14532D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows Alert Dialog when offline without existing session
  void _showOfflineNoSessionDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFDC2626),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tidak Ada Sesi Offline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF475569),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF14532D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message, {bool isError = false, bool isWarning = false}) {
    Color bg = const Color(0xFF14532D);
    IconData icon = Icons.check_circle_outline;

    if (isError) {
      bg = const Color(0xFFB91C1C);
      icon = Icons.error_outline;
    } else if (isWarning) {
      bg = const Color(0xFFD97706);
      icon = Icons.wifi_off_rounded;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const forestGreen = Color(0xFF14532D);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Status Badge (Online / Offline status indicator)
              Align(
                alignment: Alignment.centerRight,
                child: _buildNetworkStatusBadge(),
              ),

              const SizedBox(height: 16),

              // Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14532D).withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/icon_small.jpeg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SEMIS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: forestGreen,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sistem Informasi Silsilah & Pemuliaan Domba',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Hero Feature Card
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 145,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE2F9E8), Color(0xFFD1FAE5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -20,
                        child: Icon(
                          Icons.cloud_sync_rounded,
                          size: 135,
                          color: Colors.green.shade200.withValues(alpha: 0.6),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: forestGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Cloud & Offline-First',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Manajemen ternak mandiri,\nterintegrasi Google Drive.',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.25,
                                fontWeight: FontWeight.bold,
                                color: forestGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Welcome Title
              const Text(
                'Selamat Datang',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masuk dengan akun Google untuk mengelola silsilah dan menyinkronkan data ternak Anda.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5, height: 1.4),
              ),

              const SizedBox(height: 24),

              // Primary "Sign in with Google" Button
              _buildGoogleSignInButton(),

              const SizedBox(height: 16),

              // Saved Offline Session Card (if available)
              if (_savedSession != null) ...[
                _buildSavedSessionCard(),
                const SizedBox(height: 16),
              ] else if (!_isOnline) ...[
                // Offline Warning when no session exists
                _buildOfflineNoticeWithoutSession(),
                const SizedBox(height: 16),
              ],

              // Google Drive Scope info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: forestGreen,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Autentikasi menggunakan Google OAuth 2.0 dengan izin Google Drive untuk penyimpanan cloud yang aman.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Network Status Badge on top
  Widget _buildNetworkStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isOnline ? 'Online' : 'Mode Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isOnline ? const Color(0xFF065F46) : const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  /// Google Sign-In Button with Google logo styling
  Widget _buildGoogleSignInButton() {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => _handleGoogleSignIn(),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14532D)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleGLogo(),
                  const SizedBox(width: 14),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Saved Local Session Card
  Widget _buildSavedSessionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF14532D),
                child: Text(
                  _savedSession!.name.isNotEmpty
                      ? _savedSession!.name[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _savedSession!.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF14532D),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Sesi Tersimpan',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _savedSession!.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _handleOfflineLogin,
              icon: const Icon(Icons.offline_bolt_rounded, size: 18),
              label: Text(
                'Lanjutkan Sebagai ${_savedSession!.name.split(' ').first} (Offline)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF14532D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Offline Notice when no session is cached
  Widget _buildOfflineNoticeWithoutSession() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Perangkat tidak terhubung ke internet dan belum ada sesi akun tersimpan di Secure Storage. Harap hubungkan internet untuk login pertama kali.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF991B1B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Vector Widget rendering the standard multi-color Google 'G' icon
class _GoogleGLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double radius = w / 2;

    // Red sector (top left to top right)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    // Yellow sector (bottom left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    // Green sector (bottom)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    // Blue sector (horizontal bar and right arc)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - 2);

    // Draw arcs
    canvas.drawArc(rect, -2.3, 1.4, false, redPaint);
    canvas.drawArc(rect, 2.3, 1.4, false, yellowPaint);
    canvas.drawArc(rect, 0.9, 1.4, false, greenPaint);
    canvas.drawArc(rect, -0.9, 1.8, false, bluePaint);

    // Draw horizontal inner bar for G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(w - 2.5, h / 2), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
