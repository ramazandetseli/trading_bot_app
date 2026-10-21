import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 🔥 EKSİK Olan Giriş Yapma Fonksiyonu
  Future<AuthResponse> signIn({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // Giriş başarılıysa OneSignal'a kullanıcıyı kaydet
    if (response.user != null) {
      OneSignal.login(response.user!.id);
    }
    
    return response;
  }

  // 🔥 EKSİK Olan Kayıt Olma Fonksiyonu
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> updatePassword({
    required String oldpassword, 
    required String newpassword,
    required String email
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: oldpassword,
    );

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newpassword),
      );
    } catch (e) {
      throw Exception("Şifre güncellenirken hata: $e");
    }
  }
    
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    OneSignal.logout(); // Çıkış yapınca bildirimleri kes
  }

  User? getCurrentUser() => _supabase.auth.currentUser;

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email); 
    } catch (e) {
      throw Exception("Kod gönderilemedi: $e");
    }
  }

  Future<void> verifyOtpAndSetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception("Kod hatalı veya şifre güncellenemedi: $e");
    }
  }
}