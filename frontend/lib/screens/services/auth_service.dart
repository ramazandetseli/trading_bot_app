import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;


  Future<void> updatePassword(
    {
    required String oldpassword, 
    required String newpassword,
    required String email
    }

    
  ) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: oldpassword,
    );

    try {
          await _supabase.auth.updateUser(
          UserAttributes(password: newpassword),
        );
    }
    catch (e) {
      throw Exception("Şifre güncellenirken hata: $e");
    }
    
  }
    
    Future<void> signOut() async {
      await _supabase.auth.signOut();
    }


    User? getCurrentUser()=> _supabase.auth.currentUser;

Future<void> resetPassword(String email) async {
  try {
    await _supabase.auth.resetPasswordForEmail(email); 
    // Supabase ayarlarına göre bu ya link ya kod gönderir. 
    // Birazdan ayarlardan kod (OTP) yapmayı göstereceğim.
  } catch (e) {
    throw Exception("Kod gönderilemedi: $e");
  }
}

// Kodu doğrular ve şifreyi değiştirir
Future<void> verifyOtpAndSetPassword({
  required String email,
  required String token,
  required String newPassword,
}) async {
  try {
    // 1. Kodu doğrula
    await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
    // 2. Şifreyi güncelle (Kod doğruysa bu yetki açılır)
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  } catch (e) {
    throw Exception("Kod hatalı veya şifre güncellenemedi: $e");
  }
}

}