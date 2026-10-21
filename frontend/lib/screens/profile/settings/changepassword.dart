import 'package:flutter/material.dart';
import 'package:trading_bot_app/services/auth_service.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});
  
  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureNewAgain = true;
  
  final TextEditingController _oldPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _newPasswordAgain = TextEditingController();
  
  bool _isLoading = false;

  void _sifreDegistir() async {
    // 1. Boş Alan Kontrolü
    if (_oldPassword.text.isEmpty || _newPassword.text.isEmpty || _newPasswordAgain.text.isEmpty) {
      _showSnackBar("Lütfen tüm alanları doldurun.", isError: true);
      return;
    }

    // 2. Yeni Şifre Eşleşme Kontrolü (Backend'i yormadan lokalde çözüyoruz)
    if (_newPassword.text != _newPasswordAgain.text) {
      _showSnackBar("Yeni şifreler birbiriyle uyuşmuyor!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().updatePassword(
        email: AuthService().getCurrentUser()?.email ?? '',
        oldpassword: _oldPassword.text,
        newpassword: _newPassword.text,
      );

      if (mounted) {
        _showSnackBar("Şifreniz başarıyla güncellendi!", isError: false);
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, 
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Şifre Değiştir',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ÜST İKON VE AÇIKLAMA (Güven hissiyatı vermek için)
            Icon(Icons.lock_reset_rounded, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              "Hesap Güvenliği",
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              "Hesabınızı güvende tutmak için güçlü bir şifre belirleyin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 32),

            // ŞİFRE ALANLARI
            _buildPasswordField(
              controller: _oldPassword,
              label: 'Mevcut Şifre',
              obscureText: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _newPassword,
              label: 'Yeni Şifre',
              obscureText: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _newPasswordAgain,
              label: 'Yeni Şifre (Tekrar)',
              obscureText: _obscureNewAgain,
              onToggle: () => setState(() => _obscureNewAgain = !_obscureNewAgain),
              colorScheme: colorScheme,
              isLast: true,
            ),
            
            const SizedBox(height: 40),

            // KAYDET BUTONU
            ElevatedButton(
              onPressed: _isLoading ? null : _sifreDegistir,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Şifreyi Güncelle',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Kod tekrarını önleyen özel TextField metodu
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required ColorScheme colorScheme,
    bool isLast = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: colorScheme.onSurfaceVariant),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
            size: 20, 
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}