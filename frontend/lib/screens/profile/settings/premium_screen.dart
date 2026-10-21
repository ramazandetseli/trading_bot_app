import 'package:flutter/material.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // TODO: İleride bunu Supabase veya RevenueCat'ten çekeceğiz
  // Test etmek için bunu true/false yaparak iki farklı tasarımı görebilirsin.
  bool _isPremiumUser = false; 
  
  // 0: Aylık, 1: Yıllık
  int _selectedPlanIndex = 1; 

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isPremiumUser ? "VIP Üyeliğim" : "Premium'a Geç",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isPremiumUser ? _buildActivePremiumView(colorScheme) : _buildMarketingView(colorScheme),
      // Alt kısma yapışık Satın Alma butonu (Sadece VIP değilse görünür)
      bottomNavigationBar: _isPremiumUser ? null : _buildBottomCheckout(colorScheme),
    );
  }

  // =========================================================================
  // 1. KULLANICI VIP İSE GÖSTERİLECEK YÖNETİM EKRANI
  // =========================================================================
  Widget _buildActivePremiumView(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB8860B), Color(0xFFFFD700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFFB8860B).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                "VIP Üyeliğiniz Aktif",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "Tüm premium özelliklere sınırsız erişiminiz var.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text("Üyelik Bilgileri", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildInfoRow(context, "Mevcut Plan", "Yıllık VIP Paket"),
        _buildInfoRow(context, "Yenilenme Tarihi", "12 Ekim 2027"),
        _buildInfoRow(context, "Durum", "Otomatik Yenileme Açık", isHighlight: true),
        const SizedBox(height: 32),
        const Text("İşlemler", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: colorScheme.surfaceContainerHigh,
          leading: const Icon(Icons.restore_rounded),
          title: const Text("Satın Almaları Geçmişi"),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {},
        ),
        const SizedBox(height: 8),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: colorScheme.error.withValues(alpha: 0.1),
          leading: Icon(Icons.cancel_outlined, color: colorScheme.error),
          title: Text("Aboneliği İptal Et", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
          onTap: () {
            // İptal onay dialogu
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Abonelik iptal işlemleri App Store/Google Play üzerinden yapılacaktır.")),
            );
          },
        ),
      ],
    );
  }

  // =========================================================================
  // 2. KULLANICI NORMAL İSE GÖSTERİLECEK SATIŞ EKRANI
  // =========================================================================
  Widget _buildMarketingView(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
      children: [
        // BAŞLIK & İKON
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFB8860B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.diamond_rounded, size: 54, color: Color(0xFFDAA520)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Piyasanın Hakimi Olun",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Yapay zeka analizleri ve VIP sinyallerle yatırımlarınızı bir üst seviyeye taşıyın.",
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 32),

        // ÖZELLİKLER LİSTESİ
        const Text("Neler Kazanacaksınız?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.auto_awesome, "Sınırsız AI Projeksiyonu", "Tüm fonlar için günlük limitsiz yapay zeka getirisi hesaplama."),
        _buildFeatureItem(Icons.bolt_rounded, "VIP Momentum Sinyalleri", "Yükseliş trendine giren hisseleri anında tespit edin."),
        _buildFeatureItem(Icons.speed_rounded, "Öncelikli Sunucu Erişimi", "Gecikme olmadan anlık veri akışı ve hızlı tarama."),
        _buildFeatureItem(Icons.block_rounded, "Reklamsız Deneyim", "Sadece piyasaya odaklanın, dikkatiniz dağılmasın."),
        
        const SizedBox(height: 32),

        // PLAN SEÇİMİ
        const Text("Planınızı Seçin", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPlanCard(0, "Aylık", "₺99", "/ay", null)),
            const SizedBox(width: 12),
            Expanded(child: _buildPlanCard(1, "Yıllık", "₺79", "/ay", "En Popüler - %20 Kâr")),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // BİLEŞENLER
  // =========================================================================

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index, String title, String price, String period, String? badge) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF00C853), borderRadius: BorderRadius.circular(8)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            Text(title, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(period, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20)
            else
              Icon(Icons.circle_outlined, color: colorScheme.outlineVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCheckout(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            // TODO: İleride RevenueCat veya Google Play entegrasyonu buraya gelecek.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Ödeme altyapısı yakında aktif edilecektir! Şu an ücretsiz kullanıyorsunuz.")),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            _selectedPlanIndex == 0 ? "Aylık VIP Başlat (₺99)" : "Yıllık VIP Başlat (₺948)",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String title, String value, {bool isHighlight = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? const Color(0xFF00C853) : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}