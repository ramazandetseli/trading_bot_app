import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/main.dart';
import 'package:trading_bot_app/screens/auth/auth_screen.dart';
import 'package:trading_bot_app/screens/profile/settings/changepassword.dart';
import 'package:trading_bot_app/screens/profile/settings/notification_screen.dart';
import 'package:trading_bot_app/screens/profile/settings/premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _cikisYap(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      // Çıkış yaptıktan sonra login veya splash ekranına yönlendirme
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Supabase'den gerçek kullanıcı verilerini alıyoruz
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? "Giriş yapılmadı";
    // Eğer veritabanında isim yoksa varsayılan olarak ismini gösteriyoruz
    final userName = user?.userMetadata?['name'] ?? "Kullanıcı"; 
    final initials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : "U";

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Profilim", 
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 1. PROFİL KARTI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.onPrimary,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "VIP Üye",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 2. TERCİHLER
          _sectionTitle(context, "Uygulama Tercihleri"),
          _card(context, [
            _settingRow(
              context,
              icon: Icons.dark_mode_rounded,
              iconColor: Colors.indigoAccent,
              title: "Koyu Tema",
              trailing: Switch(
                value: Theme.of(context).brightness == Brightness.dark,
                activeColor: colorScheme.primary,
                onChanged: (_) => ThemeManager.toggleTheme(),
              ),
            ),
            Divider(height: 1, indent: 64, color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
            _settingRow(
              context,
              icon: Icons.notifications_active_rounded,
              iconColor: Colors.amber.shade600,
              title: "Bildirim Ayarları",
              trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
            ),
          ]),
          const SizedBox(height: 24),

          // 3. SİSTEM & BAĞLANTI (Geliştirici veya Sistem Durumu)
          _sectionTitle(context, "Sistem Durumu"),
          _card(context, [
            _settingRow(
              context,
              icon: AppConstants.isDevelopment ? Icons.dns_rounded : Icons.cloud_done_rounded,
              iconColor: AppConstants.isDevelopment ? Colors.orange : Colors.green,
              title: "Veri Sunucusu",
              subtitle: AppConstants.isDevelopment ? "Yerel Geliştirme (Local)" : "Canlı (Production)",
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (AppConstants.isDevelopment ? Colors.orange : Colors.green).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.isDevelopment ? Colors.orange : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Aktif",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.isDevelopment ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // 4. HESAP İŞLEMLERİ
          _sectionTitle(context, "Hesap İşlemleri"),
          _card(context, [
             _settingRow(
              context,
              icon: Icons.workspace_premium_outlined,
              iconColor: Colors.amber,
              title: "Premium Üyelik İşlemleri",
              trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
            ),
            _settingRow(
              context,
              icon: Icons.shield_rounded,
              iconColor: Colors.teal,
              title: "Şifre Değiştir",
              trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
              onTap: () {
                // Şifre değiştirme ekranına yönlendirme
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Changepassword()),
                );
              },
            ),
            Divider(height: 1, indent: 64, color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
            _settingRow(
              context,
              icon: Icons.logout_rounded,
              iconColor: colorScheme.error,
              title: "Çıkış Yap",
              isDestructive: true,
              onTap:() {
                _cikisYap(context);
                Navigator.push(context, 
                MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
            ),
          ]),
          
          const SizedBox(height: 32),
          // ALT BİLGİ
          Center(
            child: Column(
              children: [
                Text(
                  "Finansal Terminal v1.0.0",
                  style: TextStyle(color: colorScheme.outline, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "© 2026 Tüm Hakları Saklıdır",
                  style: TextStyle(color: colorScheme.outline, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorScheme.primary, 
          fontSize: 12, 
          fontWeight: FontWeight.w800, 
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _settingRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: isDestructive ? colorScheme.error.withValues(alpha: 0.1) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive 
                      ? colorScheme.error.withValues(alpha: 0.1) 
                      : iconColor.withValues(alpha: 0.12), 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isDestructive ? colorScheme.error : iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title, 
                      style: TextStyle(
                        color: isDestructive ? colorScheme.error : colorScheme.onSurface, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle, 
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
            ],
          ),
        ),
      ),
    );
  }
}