import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/api/premium_service.dart';
import 'package:trading_bot_app/main.dart';
import 'package:trading_bot_app/screens/auth/auth_screen.dart';
import 'package:trading_bot_app/screens/settings/changepassword.dart';
import 'package:trading_bot_app/screens/settings/notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  String userMail = "";
  bool isLoading = true; // Sayfa ilk açılış yüklemesi için kontrol

  // 🎯 Renkleri ve Temayı Premium Durumuna Göre Dinamik Yapıyoruz Aga
  Color get accentColor => UserState().isPremium ? Colors.amber : Colors.blueAccent;
  Color get avatarBg => UserState().isPremium ? Colors.amber.withValues(alpha: 0.1) : Colors.blueAccent.withValues(alpha: 0.1);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        userMail = user.email ?? "";
      });

      // 🎯 Global UserState'i Supabase'den güncelliyoruz
      await UserState().fetchPremiumStatus();
    }
    setState(() {
      isLoading = false;
    });
  }

  // 🎯 Test Amaçlı Anlık Supabase Premium Aktifleştirici (Simülasyon)
  Future<void> _makeUserPremiumSimulated() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      isLoading = true; 
    });

    try {
      // 1. Supabase'deki profiles tablosunda premium_status'u true yapıyoruz
      await supabase
          .from('profiles')
          .update({'premium_status': true})
          .eq('id', user.id);

      // 2. Bizim global UserState'i de lokal olarak güncelliyoruz ki tüm sayfalar anlasın
      UserState().isPremium = true;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("🚀 Ödeme Başarılı! PRO Üyeliğiniz Aktif Edildi.", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Simülasyon Hatası: $e")),
      );
    }

    setState(() {
      isLoading = false; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF070B14),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kullanıcı Profili", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: avatarBg,
                    child: Icon(Icons.person, size: 50, color: accentColor),
                  ),
                  if (UserState().isPremium) // Premiumsa köşede şık bir taç belirsin
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.workspace_premium, size: 16, color: Colors.black),
                      ),
                    )
                  else // Standart üyeyse normal kalem düzenleme ikonu
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: accentColor,
                        child: const Icon(Icons.edit, size: 15, color: Colors.white),
                      ),
                    )
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(userMail, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // 🎯 Dinamik Premium Statü Alanı ve Butonu (Yan yana derli toplu düzen)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  UserState().isPremium ? Icons.verified : Icons.account_circle,
                  color: UserState().isPremium ? Colors.amber : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  UserState().isPremium ? "Premium Üye" : "Standart Üye",
                  style: TextStyle(color: UserState().isPremium ? Colors.amber : Colors.grey, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    if (!UserState().isPremium) {
                      _makeUserPremiumSimulated(); // Basınca şak diye premium yapacak simülasyon
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UserState().isPremium ? Colors.amber.withValues(alpha: .2) : Colors.amber,
                    foregroundColor: UserState().isPremium ? Colors.amber : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: UserState().isPremium ? 0 : 2,
                    side: UserState().isPremium ? const BorderSide(color: Colors.amber) : null,
                  ),
                  child: UserState().isPremium 
                      ? const Text("Üyelik Aktif", style: TextStyle(fontWeight: FontWeight.bold))
                      : const Text("Aylık 19 ₺ Ol", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),

            const SizedBox(height: 20),

            _profilMenuItem(Icons.palette, "Tema Ayarları", Theme.of(context).brightness == Brightness.dark ? "Karanlık mod açık" : "Aydınlık mod açık"),
            _profilMenuItem(Icons.notifications, "Bildirimler", "Sinyal bildirimleri açık"),
            _profilMenuItem(Icons.security, "Güvenlik", "Şifre değiştir"),
             
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await supabase.auth.signOut();
                  UserState().isPremium = false; // Çıkışta temizlik
                  if (!mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Çıkış yap", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20,)
          ],
        ),
      ),
    );
  }

  Widget _profilMenuItem(IconData icon, String title, String subtitle){
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: accentColor), // 🎯 Sol ikonların renkleri de premium durumuna göre değişiyor!
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        if(title == "Tema Ayarları"){
          ThemeManager.toggleTheme(); 
        } else if(title == "Bildirimler"){
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
        } else if(title == "Güvenlik"){
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Changepassword()));
        }
      },
    );
  }
}