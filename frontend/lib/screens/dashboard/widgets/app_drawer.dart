import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String kullaniciAdi;
  final String eposta;

  const AppDrawer({
    super.key,
    this.kullaniciAdi = 'Ramazan Detseli',
    this.eposta = 'ramazan@detseli.com',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Kullanıcı Bilgi Alanı
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      kullaniciAdi.isNotEmpty ? kullaniciAdi[0] : 'U',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kullaniciAdi,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade900.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ÜCRETSİZ PLAN',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Premium Yükselt Kartı
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade800, Colors.deepPurple.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text('TradingBot PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Anlık derinlik, VIP algoritmik sinyaller ve sınırsız alarm ayrıcalığı.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        elevation: 0,
                      ),
                      onPressed: () {},
                      child: const Text('PRO\'ya Yükselt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Menü Linkleri
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Profil & Hesap Ayarları'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Portföy & Varlıklarım'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded),
              title: const Text('Canlı Müşteri Hizmetleri'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Uygulama Ayarları'),
              onTap: () {},
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent)),
              onTap: () {},
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}