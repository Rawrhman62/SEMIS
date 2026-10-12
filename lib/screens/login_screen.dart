import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.pets_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 24),
              const Text('SEMIS', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: green, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              const Text('Catat. Pantau. Kembangkan.', style: TextStyle(fontSize: 16, color: Color(0xFF55705D))),
              const SizedBox(height: 34),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 155,
                  width: double.infinity,
                  color: const Color(0xFFDCFCE7),
                  child: Stack(
                    children: [
                      Positioned(right: -8, bottom: -22, child: Icon(Icons.grass_rounded, size: 150, color: Colors.green.shade200)),
                      const Positioned(left: 18, top: 20, child: Icon(Icons.pets_rounded, size: 86, color: green)),
                      const Positioned(left: 20, bottom: 18, child: Text('Manajemen ternak\nlebih terarah', style: TextStyle(fontSize: 18, height: 1.2, fontWeight: FontWeight.bold, color: green))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Selamat datang', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF163321))),
              const SizedBox(height: 6),
              const Text('Masuk untuk melanjutkan', style: TextStyle(color: Color(0xFF6B7C70), fontSize: 14)),
              const SizedBox(height: 22),
              TextField(
                controller: _name,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), labelText: 'Nama pengguna', hintText: 'Masukkan nama pengguna'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: 'Kata sandi',
                  hintText: 'Masukkan kata sandi',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: widget.onLogin,
                  style: FilledButton.styleFrom(backgroundColor: green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Masuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 14),
              const Center(child: Text('Demo aplikasi SEMIS', style: TextStyle(fontSize: 12, color: Color(0xFF829087)))),
            ],
          ),
        ),
      ),
    );
  }
}
