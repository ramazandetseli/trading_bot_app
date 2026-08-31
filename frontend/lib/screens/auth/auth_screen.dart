import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/services/premium_service.dart';
import 'package:trading_bot_app/main.dart';
import 'package:trading_bot_app/services/auth_service.dart';
import 'package:trading_bot_app/screens/profile/settings/authchangepassword.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  
  bool isLogin=true;
  bool _isObscure = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();


  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating, // Havada dursun, daha modern
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color(0xFF0A0E17),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle
                ),
                child: Icon(Icons.auto_graph_rounded,color: Colors.blueAccent,size: 80,),
              ),
              const SizedBox(height: 30),
              Text(
                isLogin ? "Tekrar Hoş Geldin" : "Hesap Oluştur",
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                isLogin ? "Borsanın nabzını tutmaya devam et." : "Yapay zeka destekli analize ilk adımı at.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 14),
              ),
              const SizedBox(height: 40),


              _buildTextField("E-posta Adresi", Icons.email_outlined, _emailController, false),
              const SizedBox(height: 16),

              _buildTextField("Şifre", Icons.lock_outline, _passwordController, true),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLogin) {
                      signIn(); 
                    } else {
                      signUp(); 
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(16))
                  ),
                  child: Text(
                    isLogin ? "Giriş Yap" : "Kayıt ol" ,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  )

                  ),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed:() => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? "Hesabın yok mu? Kayıt Ol" : "Zaten hesabın var mı? Giriş Yap",
                  style: const TextStyle(color: Colors.blueAccent),
                )),
                const SizedBox(height: 10),
                if (!isLogin) // Sadece giriş modundaysa göster
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPasswordDialog(),
                    child: const Text("Şifremi Unuttum", style: TextStyle(color: Colors.blueAccent)),
                  ),
                ),


                const SizedBox(height: 15,),
                Text(
                  "Bu uygulama Supabase tarafından desteklenmektedir.",
                  style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12),
                )

            ],
          ),
        ),
      ),
    );
  }

Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool isPassword) {
    return TextField(
    
      controller: controller,
      obscureText: isPassword ? _isObscure : false,      
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        suffixIcon: isPassword
        ? IconButton(
           icon: Icon(
          _isObscure ? Icons.visibility_off : Icons.visibility,
          color: Colors.white.withValues(alpha: 0.5),
          )
          ,onPressed:() {
          setState(() {
            _isObscure=!_isObscure;
          });
        }) : null,
        filled: true,
        fillColor: const Color(0xFF131B2B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }


Future<void> signUp() async {
  try {
    await supabase.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı! E-postanı kontrol et veya giriş yap.")),
      );
    }
  } on AuthException catch (e) {
    if (e.message.contains("already registered")) {
      _showError("Bu e-posta zaten kayıtlı, giriş yapmayı dene.");
    } else if (e.message.contains("Password should be")) {
      _showError("Şifre çok kısa! En az 6 karakter lazım.");
    } else if (e.message.contains("Invalid email")) {
      _showError("Geçersiz mail adresi.");
    } else {
      _showError("Kayıt hatası: ${e.message}");
    }
  } catch (e) {
    _showError("Sistemde bir arıza var, destek için ramdet42@gmail.com ile iletişime geçebilirsiniz.");
  }
}


Future<void> signIn() async {
  
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    _showError("email veya şifre alanı boş.");
    return;
  }

  try {
    final response = await supabase.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    
    if (response.user != null && mounted) {
      UserState().fetchPremiumStatus();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TradingBotApp()),
      );
    }
  } on AuthException catch (e) {
    // Giriş hataları
    if (e.message.contains("Invalid login credentials")) {
      _showError("E-posta veya şifre patladı. Kontrol et.");
    } else if (e.message.contains("Email not confirmed")) {
      _showError("E-posta kutundan maili onayla ve tekrar dene.");
    } else {
      _showError("Giriş yapılamadı: ${e.message}");
    }
  } catch (e) {
    _showError("Bağlantıda sıkıntı var,destek için ramdet42@gmail.com ile iletişime geçebilirsiniz.");
  }
}


void _showForgotPasswordDialog(){
  final emailController = TextEditingController();


  showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      title: const Text("Şifre Sıfırlama"),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: "Kayıtlı E-posta Adresin",
          prefixIcon: Icon(Icons.email_outlined),
        ),
      ),
      actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
         ElevatedButton(
  onPressed: () async {
    final email = emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen e-posta adresinizi girin.")));
      return;
    }

    try {
      // 2. Kodu gönder (AuthService içindeki fonksiyonun)
      await AuthService().resetPassword(email);

      if (mounted) {
        // 3. Bilgilendirme yap
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("6 haneli doğrulama kodu e-postanıza gönderildi."))
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  ResetPasswordScreen(email: email), // OTP doğrulama ve şifre sıfırlama ekranı
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    }
  },
  child: const Text("Kodu gönder"),
)
          
          
      ]
    )
  );


}





}