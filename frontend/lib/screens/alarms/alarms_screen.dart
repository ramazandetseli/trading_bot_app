import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/constants/app_constants.dart';
import 'package:trading_bot_app/models/hisse_model.dart';
import 'package:trading_bot_app/services/api_service.dart';
import 'alarm_card.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<dynamic> alarmliHisseler = [];
  List<Hissemodel> tumHisseler = [];
  bool yukleniyor = true;
  bool sembollerYukleniyor = true;
  final ApiService _apiService = ApiService();


  @override
  void initState() {
    super.initState();
    alarmlariGetir();
    _sembolleriYukle();
  }

  Future<void> alarmlariGetir() async {
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() => yukleniyor = false);
      return;
    }

    try {
      final response = await http.get(AppConstants.alarmlarUri(userId));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          alarmliHisseler = data['alarmlar'] ?? [];
          yukleniyor = false;
        });
      } else {
        setState(() => yukleniyor = false);
      }
    } catch (e) {
      debugPrint("Alarmlar çekilemedi: $e");
      if (!mounted) return;
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _sembolleriYukle() async {
    try {
      final response = await http.get(AppConstants.taraUri);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> results = decoded['hisseler'] ?? [];
        setState(() {
          tumHisseler = results.map((v) => Hissemodel.fromMap(v)).toList();
          sembollerYukleniyor = false;
        });
      } else {
        setState(() => sembollerYukleniyor = false);
      }
    } catch (e) {
      debugPrint("Sembol listesi çekilemedi: $e");
      if (!mounted) return;
      setState(() => sembollerYukleniyor = false);
    }
  }

  Future<void> alarmSil(String symbol) async {
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await http.post(
        AppConstants.alarmSilUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "symbol": symbol}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        alarmlariGetir();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$symbol alarmı silindi"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Silme hatası: $e");
    }
  }

  Future<void> alarmGuncelleApiCall(String symbol, String newPrice, double currentPrice) async {
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    double? price = double.tryParse(newPrice.replaceAll(',', '.'));
    if (price == null) return;

    try {
      final response = await http.post(
        AppConstants.alarmDuzenleUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "symbol": symbol,
          "target_price": price,
          "current_price": currentPrice,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        alarmlariGetir();
      }
    } catch (e) {
      debugPrint("Güncelleme hatası: $e");
    }
  }

  Future<void> _alarmKurBagli(Hissemodel model, String hedefFiyatText) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final hedefFiyat = double.tryParse(hedefFiyatText.replaceAll(',', '.'));
    if (hedefFiyat == null) return;

    final basarili = await _apiService.alarmEkleApi(userId, model.symbol, hedefFiyat, model.price);
    if (!mounted) return;

    if (basarili) {
      Navigator.pop(context);
      alarmlariGetir();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${model.symbol} için alarm kuruldu"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alarm kurulamadı"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _yeniAlarmModalGoster() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return _AlarmEkleFormu(
          hisseler: tumHisseler,
          onEkle: _alarmKurBagli,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text("Alarmlarım", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: sembollerYukleniyor ? null : _yeniAlarmModalGoster,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text("Alarm Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      body: yukleniyor
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : RefreshIndicator(
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHigh,
              onRefresh: alarmlariGetir,
              child: alarmliHisseler.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 200),
                        Icon(Icons.notifications_off_outlined, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Center(
                          child: Text("Henüz alarm kurulmamış", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 12, bottom: 90),
                      itemCount: alarmliHisseler.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final Map<String, dynamic> alarm = alarmliHisseler[index];
                        return AlarmCard(
                          alarm: alarm,
                          onSil: () => alarmSil(alarm["symbol"]),
                          onGuncelle: (yeniFiyat) {
                            alarmGuncelleApiCall(
                              alarm["symbol"],
                              yeniFiyat,
                              double.tryParse(alarm['current_price']?.toString() ?? "0") ?? 0.0,
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}

class _AlarmEkleFormu extends StatefulWidget {
  final List<Hissemodel> hisseler;
  final Future<void> Function(Hissemodel model, String hedefFiyat) onEkle;

  const _AlarmEkleFormu({required this.hisseler, required this.onEkle});

  @override
  State<_AlarmEkleFormu> createState() => _AlarmEkleFormuState();
}

class _AlarmEkleFormuState extends State<_AlarmEkleFormu> {
  final kodController = TextEditingController();
  final fiyatController = TextEditingController();
  late final List<MapEntry<String, Hissemodel>> _sembolIndex;
  List<Hissemodel> _oneriler = [];
  Hissemodel? _seciliHisse;
  bool _kuruluyor = false;

  @override
  void initState() {
    super.initState();
    _sembolIndex = widget.hisseler.map((h) => MapEntry(h.symbol.toLowerCase(), h)).toList();
  }

  @override
  void dispose() {
    kodController.dispose();
    fiyatController.dispose();
    super.dispose();
  }

  void _filtrele(String metin) {
    final q = metin.trim().toLowerCase();
    setState(() {
      _seciliHisse = null;
      if (q.isEmpty) {
        _oneriler = [];
      } else {
        _oneriler = _sembolIndex.where((e) => e.key.contains(q)).map((e) => e.value).take(6).toList();
      }
    });
  }

  void _sec(Hissemodel model) {
    setState(() {
      _seciliHisse = model;
      kodController.text = model.symbol;
      fiyatController.text = model.price.toString();
      _oneriler = [];
    });
  }

  Future<void> _kaydet() async {
    if (_seciliHisse == null) return;
    setState(() => _kuruluyor = true);
    await widget.onEkle(_seciliHisse!, fiyatController.text);
    if (mounted) setState(() => _kuruluyor = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Yeni Alarm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          TextField(
            controller: kodController,
            textCapitalization: TextCapitalization.characters,
            onChanged: _filtrele,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: "Hisse Kodu",
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              suffixIcon: _seciliHisse != null ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20) : null,
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2)),
            ),
          ),
          if (_oneriler.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 100 ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _oneriler.length,
                itemBuilder: (context, i) {
                  final h = _oneriler[i];
                  return InkWell(
                    onTap: () => _sec(h),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Text(h.symbol, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 13)),
                          const Spacer(),
                          Text('${h.price} ₺', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: fiyatController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: "Hedef Fiyat (₺)",
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.surfaceContainerHigh,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: (_seciliHisse == null || _kuruluyor) ? null : _kaydet,
              child: _kuruluyor
                  ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                  : const Text("Alarmı Kur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}