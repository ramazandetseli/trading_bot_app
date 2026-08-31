// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:trading_bot_app/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; // Giriş ekranından gönderdiğimiz maili burada yakalıyoruz
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Görünürlük ayarları
  bool isNewPasswordVisible = true; // Şifreler başta gizli olsun (obscureText için)
  bool isNewPasswordAgainVisible = true;
  
  // Controller'lar
  TextEditingController otpCodeController = TextEditingController(); // Eski şifre yerine KOD geldi
  TextEditingController newpassword = TextEditingController();
  TextEditingController newpasswordagain = TextEditingController();
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Şifre Belirle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Klavye açılınca taşma yapmasın diye
          child: Column(
            children: [
              Text("${widget.email} adresine gelen kodu giriniz.", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 20),
              
              // 1. KUTU: DOĞRULAMA KODU (OTP)
              TextField(
                controller: otpCodeController,
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(
                  labelText: '6 Haneli Kod',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.vibration, size: 15),
                ),
              ),
              const SizedBox(height: 20),
              
              // 2. KUTU: YENİ ŞİFRE
              TextField(
                controller: newpassword,
                obscureText: isNewPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.lock_outline, size: 15),
                  suffixIcon: IconButton(
                    icon: Icon(isNewPasswordVisible ? Icons.visibility_off : Icons.visibility, size: 15),
                    onPressed: () => setState(() => isNewPasswordVisible = !isNewPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 3. KUTU: YENİ ŞİFRE TEKRAR
              TextField(
                controller: newpasswordagain,
                obscureText: isNewPasswordAgainVisible,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: const Icon(Icons.lock_outline, size: 15),
                  suffixIcon: IconButton(
                    icon: Icon(isNewPasswordAgainVisible ? Icons.visibility_off : Icons.visibility, size: 15),
                    onPressed: () => setState(() => isNewPasswordAgainVisible = !isNewPasswordAgainVisible),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // GÜNCELLE BUTONU
              _isLoading 
                ? const CircularProgressIndicator() 
                : ElevatedButton(
                    onPressed: _handlePasswordReset,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Şifreyi Güncelle', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // Şifre sıfırlama mantığı
  Future<void> _handlePasswordReset() async {
    if (newpassword.text != newpasswordagain.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifreler birbiriyle uyuşmuyor!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // BURASI ÖNEMLİ: AuthService içindeki yeni OTP fonksiyonunu çağırıyoruz
      await AuthService().verifyOtpAndSetPassword(
        email: widget.email,
        token: otpCodeController.text.trim(),
        newPassword: newpassword.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre başarıyla sıfırlandı!")));
        // Kullanıcıyı en başa (Login ekranına) atıyoruz
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}