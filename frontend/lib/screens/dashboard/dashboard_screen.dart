import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/models/fon_model.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/market_search_bar.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/hisse_list_view.dart';
import 'package:trading_bot_app/screens/dashboard/widgets/fon_list_view.dart';
import 'package:trading_bot_app/services/fon_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _debounce;

  bool isVipOnly = false;
  bool isYuksekHacimOnly = false;
  bool isFavoriteOnly = false;
  bool isMomentumOnly = false;
  bool hisselerYukleniyor = false;
  bool fonlarYukleniyor = false;
  bool _hisseTabAktif = true;
  String query = '';
  Set<String> favoriHisseler = {};

  String seciliFonKategorisi = 'Tümü';


  final FonService _fonService = FonService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _rawHisseResults = [];
  List<Hissemodel> _parsedHisseler = [];
  List<Hissemodel> _displayHisseler = [];

  List<FonOzetModel> _tumFonlar = [];
  List<FonOzetModel> _displayFonlar = [];
  List<FonOzetModel> haftaninYukselenleri = [];
  List<FonOzetModel> populerFonlar = [];
  bool trendlerYukleniyor = false;
  
  final List<String> fonKategorileri = [
  'Tümü',
  'Para Piyasası Fonları',
  'Fon Sepeti Fonları',
  'Karma Fonlar',
  'Değişken Fonlar',
  'Borçlanma Araçları Fonları',
  'Hisse Senedi Fonları',
  'Kıymetli Madenler Fonları',
  'Katılım Fonları',
  'Serbest Fonlar',
  'Serbest Döviz Fonlar',
];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _hisseTabAktif = _tabController.index == 0;
      });

      if (_tabController.indexIsChanging) {
        _searchController.clear();
        query = '';
        _hesaplaDisplayListeleri();
      }
    });
    _searchController.addListener(_onSearchChanged);

    hisseleriTazele();
    fonlariTazele();
    _favorileriYukle();
    trendFonlariGetir();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _searchController.clear();
      setState(() {
        query = '';
        _hisseTabAktif = _tabController.index == 0;
        _hesaplaDisplayListeleri();
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          query = _searchController.text;
          _hesaplaDisplayListeleri();
        });
      }
    });
  }





Future<void> trendFonlariGetir() async {
  setState(() => trendlerYukleniyor = true);
  
  final sonuc = await FonService().getOneCikanFonlar();
  
  if (mounted) {
    setState(() {
      haftaninYukselenleri = sonuc['yukselenler'] ?? [];
      populerFonlar = sonuc['populer'] ?? [];
      trendlerYukleniyor = false;
    });
  }
}


  void _hesaplaDisplayListeleri() {
    final q = query.trim().toLowerCase();

    // 1. Hisse Filtreleme
    _displayHisseler = _parsedHisseler.where((hisse) {
      final vipOk = isVipOnly ? hisse.signal.contains('VIP') : true;
      final momentumOk = isMomentumOnly ? hisse.signal.toUpperCase().contains('MOMENTUM') : true;
      final hacimOk = isYuksekHacimOnly ? (double.tryParse(hisse.relVol.toString()) ?? 0) >= 2.0 : true;
      final favOk = isFavoriteOnly ? favoriHisseler.contains(hisse.symbol.toUpperCase()) : true;
      final aramaOk = q.isEmpty || hisse.symbol.toLowerCase().contains(q);
      return vipOk && momentumOk && hacimOk && favOk && aramaOk;
    }).toList();

    // 2. Fon Filtreleme (Kategori + Arama)
    _displayFonlar = _tumFonlar.where((fon) {
      // Türkçe karakter duyarlılığını kaldırmak için büyük harfe çevir
      final unvan = fon.unvan.toUpperCase();
      final kod = fon.kod.toUpperCase();
      final qUpper = q.toUpperCase();

      // Arama kontrolü
      final bool aramaOk = q.isEmpty || kod.contains(qUpper) || unvan.contains(qUpper);
      if (!aramaOk) return false;

      // Çip Kategori kontrolü
      // Çip Kategori Kontrolü
      switch (seciliFonKategorisi) {
        case 'Para Piyasası Fonları':
          return (unvan.contains('PARA PİYASASI') || unvan.contains('LİKİT')) &&
                 !unvan.contains('EMEKLİLİK') && !unvan.contains('SERBEST');

        case 'Fon Sepeti Fonları':
          return unvan.contains('FON SEPETİ') &&
                 !unvan.contains('EMEKLİLİK') && !unvan.contains('SERBEST');

        case 'Karma Fonlar':
          return unvan.contains('KARMA') &&
                 !unvan.contains('EMEKLİLİK') && !unvan.contains('SERBEST');

        case 'Değişken Fonlar':
          return unvan.contains('DEĞİŞKEN') &&
                 !unvan.contains('EMEKLİLİK') && !unvan.contains('SERBEST');

        case 'Borçlanma Araçları Fonları':
          return (unvan.contains('BORÇLANMA') || unvan.contains('TAHVİL') || unvan.contains('BONO') || unvan.contains('EUROBOND')) &&
                 !unvan.contains('EMEKLİLİK') && !unvan.contains('SERBEST');

        case 'Hisse Senedi Fonları':
          return unvan.contains('HİSSE') &&
                 !unvan.contains('EMEKLİLİK') && !unvan.contains('EYF') && !unvan.contains('SERBEST');

        case 'Kıymetli Madenler Fonları':
          return (unvan.contains('ALTIN') || unvan.contains('GÜMÜŞ') || unvan.contains('KIYMETLİ MADEN')) &&
                 !unvan.contains('EMEKLİLİK') && !unvan.contains('SERBEST');

        case 'Katılım Fonları':
          return unvan.contains('KATILIM') &&
                 !unvan.contains('EMEKLİLİK');

        case 'Serbest Döviz Fonlar':
          return unvan.contains('SERBEST') &&
                 (unvan.contains('DÖVİZ') || unvan.contains('USD') || unvan.contains('EUR') || unvan.contains('AVRO')) &&
                 !unvan.contains('EMEKLİLİK');

        case 'Serbest Fonlar':
          final isDoviz = unvan.contains('DÖVİZ') || unvan.contains('USD') || unvan.contains('EUR') || unvan.contains('AVRO');
          return unvan.contains('SERBEST') && !isDoviz && !unvan.contains('EMEKLİLİK');

        case 'Tümü':
        default:
          return true;
      }
    }).toList();
  }

  Future<void> hisseleriTazele() async {
    setState(() => hisselerYukleniyor = true);
    try {
      final response = await http.get(AppConstants.taraUri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> results = decodedData['hisseler'] ?? [];
        setState(() {
          _rawHisseResults = results;
          _parsedHisseler = results.map((v) => Hissemodel.fromMap(v)).toList();
          _hesaplaDisplayListeleri();
          hisselerYukleniyor = false;
        });
      } else {
        setState(() => hisselerYukleniyor = false);
      }
    } catch (e) {
      debugPrint("Hisse verisi çekme hatası: $e");
      setState(() => hisselerYukleniyor = false);
    }
  }

  Future<void> fonlariTazele() async {
    setState(() => fonlarYukleniyor = true);
    try {
      final gelenFonlar = await _fonService.getTumFonlar();
      setState(() {
        _tumFonlar = gelenFonlar;
        _hesaplaDisplayListeleri();
        fonlarYukleniyor = false;
      });
    } catch (e) {
      debugPrint("Fon listesi hata: $e");
      setState(() => fonlarYukleniyor = false);
    }
  }

  Future<void> _favorileriYukle() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await http.get(AppConstants.favorilerUri(userId));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> liste = data['data'] ?? [];
        if (!mounted) return;
        setState(() {
          favoriHisseler = Set<String>.from(liste.map((e) => e.toString().toUpperCase()));
          _hesaplaDisplayListeleri();
        });
      }
    } catch (e) {
      debugPrint("Favoriler yüklenirken hata: $e");
    }
  }

  void favoriGuncelle(String symbol) {
    setState(() {
      if (favoriHisseler.contains(symbol)) {
        favoriHisseler.remove(symbol);
      } else {
        favoriHisseler.add(symbol);
      }
      if (isFavoriteOnly) _hesaplaDisplayListeleri();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Piyasa Terminali',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: .4)),
                boxShadow: [
                  BoxShadow(color: colorScheme.shadow.withValues(alpha: .12), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(color: colorScheme.primary.withValues(alpha: .3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(3),
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'BIST Hisseleri'),
                  Tab(text: 'TEFAS Fonları'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 14),
          MarketSearchBar(
            controller: _searchController,
            onClear: () {
              _searchController.clear();
              setState(() {
                query = '';
                _hesaplaDisplayListeleri();
              });
            },
          ),
          
          // 🎯 ÇİPLER BURAYA BAĞLANIYOR
          const SizedBox(height: 10),
          if (_hisseTabAktif) ...[
            _buildFilterChipsBar(colorScheme),
            const SizedBox(height: 10),
            _buildDurumBandi(colorScheme),
          ] else ...[
            _buildFonFilterChipsBar(colorScheme), // 👈 Fon çipleri buraya geliyor
          ],
          
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HisseListView(
                  isLoading: hisselerYukleniyor,
                  displayHisseler: _displayHisseler,
                  rawHisseResults: _rawHisseResults,
                  favoriHisseler: favoriHisseler,
                  onRefresh: hisseleriTazele,
                  onFavoriDegisti: favoriGuncelle,
                ),
                FonListView(
                  isLoading: fonlarYukleniyor,
                  displayFonlar: _displayFonlar,
                  onRefresh: fonlariTazele,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsBar(ColorScheme colorScheme) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterChip(
            label: 'VIP Sinyal',
            icon: Icons.bolt,
            isActive: isVipOnly,
            color: colorScheme.tertiary,
            onTap: () => setState(() { isVipOnly = !isVipOnly; _hesaplaDisplayListeleri(); }),
          ),
          _filterChip(
            label: 'Yüksek Hacim',
            icon: Icons.bar_chart_rounded,
            isActive: isYuksekHacimOnly,
            color: colorScheme.primary,
            onTap: () => setState(() { isYuksekHacimOnly = !isYuksekHacimOnly; _hesaplaDisplayListeleri(); }),
          ),
          _filterChip(
            label: 'Favoriler',
            icon: Icons.star_rounded,
            isActive: isFavoriteOnly,
            color: colorScheme.secondary,
            onTap: () => setState(() { isFavoriteOnly = !isFavoriteOnly; _hesaplaDisplayListeleri(); }),
          ),
          _filterChip(
            label: 'Momentum',
            icon: Icons.trending_up_rounded,
            isActive: isMomentumOnly,
            color: colorScheme.primary,
            onTap: () => setState(() { isMomentumOnly = !isMomentumOnly; _hesaplaDisplayListeleri(); }),
          ),
        ],
      ),
    );
  }


  Widget _buildFonFilterChipsBar(ColorScheme colorScheme) {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: fonKategorileri.length,
        itemBuilder: (context, index) {
          final kat = fonKategorileri[index];
          final isActive = seciliFonKategorisi == kat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    seciliFonKategorisi = kat;
                    _hesaplaDisplayListeleri();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? colorScheme.primary.withValues(alpha: 0.16) : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? colorScheme.primary.withValues(alpha: 0.6) : colorScheme.outlineVariant,
                      width: isActive ? 1.3 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      kat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip({required String label, required IconData icon, required bool isActive, required Color color, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.16) : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? color.withValues(alpha: 0.6) : colorScheme.outlineVariant, width: isActive ? 1.3 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: isActive ? color : colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? color : colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurumBandi(ColorScheme colorScheme) {
    final taranan = _parsedHisseler.length;
    
    final bool filtreAktif = isVipOnly || isYuksekHacimOnly || isFavoriteOnly || isMomentumOnly || query.isNotEmpty;
    
    final int eslesen = filtreAktif 
        ? _displayHisseler.length 
        : _parsedHisseler.where((h) => h.signal.isNotEmpty).length;

    final String etiket = filtreAktif ? 'Filtreye Uyan Gösteriliyor' : 'Genel Sinyalli';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary)),
          const SizedBox(width: 8),
          Text('$taranan Hisse Tarandı', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          Text(' · ', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          Text('$eslesen $etiket', style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}