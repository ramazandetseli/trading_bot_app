# 📈 Trading Bot App & Finansal Piyasa Terminali

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img alt="FastAPI" src="https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white" />
  <img alt="Python" src="https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img alt="Supabase" src="https://img.shields.io/badge/Supabase-Auth%20%26%20Postgres-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img alt="Render" src="https://img.shields.io/badge/Render-Web%20Service-46E3B7?style=for-the-badge&logo=render&logoColor=white" />
  <img alt="Uvicorn" src="https://img.shields.io/badge/Uvicorn-ASGI%20Server-499848?style=for-the-badge&logo=gunicorn&logoColor=white" />
  <img alt="Material 3" src="https://img.shields.io/badge/Material%203-Slivers%20UI-795548?style=for-the-badge&logo=materialdesign&logoColor=white" />
</p>

Borsa İstanbul (BIST) hisse senetleri ve Takasbank TEFAS yatırım fonlarını tek bir monorepo mimarisi altında toplayan; algoritmik tarama, teknik momentum filtreleri, canlı portföy kâr/zarar takibi ve asenkron veri beslemesi sunan **uçtan uca finansal takip ve analiz platformu**. 

Proje; bağımsız çalışan bir FastAPI mikroservisi, Render üzerinde barındırılan REST mimarisi, Supabase Row-Level Security (RLS) ile yalıtılmış kullanıcı varlıkları ve Flutter istemcisinde `NestedScrollView` / Slivers temelli performans odaklı bir kullanıcı arayüzü içerir.

> **Veri Gecikmesi & Yasal Bildirim:** BIST hisse ve piyasa verileri 15 dakika gecikmeli olarak asenkron işlenir. Uygulama bir yatırım tavsiyesi motoru değil; teknik göstergeleri (Relative Volume, VIP sinyaller, momentum) filtreleyen bir **gözlem ve portföy muhasebe terminalidir**.

---

## 🎯 Ne Yapıyor?

- **Asenkron Piyasa Taraması:** FastAPI arka planında BIST hisselerini periyodik olarak tarar; fiyat, yüzde değişim ve göreceli hacim ($RelVol \ge 2.0$) metriklerini hesaplar.
- **Teknik Sinyal Sınıflandırması:** Taranan hisseleri anlık olarak kural tabanlı algoritmalarla etiketler (`VIP`, `MOMENTUM`).
- **TEFAS Fon Takibi & Akıllı Kategorizasyon:** Kazırcı (scraper) ve servis katmanı üzerinden TEFAS fonlarını çeker; fonları unvan heuristiklerine göre (Para Piyasası, Serbest Döviz, Kıymetli Madenler, Değişken, Katılım vb.) anlık çiplere ayırır.
- **Haftanın Öne Çıkanları:** TEFAS tarafında haftalık getirisi en yüksek fonları ve pazar popülaritesini vitrin görünümünde sunar.
- **Ağırlıklı Ortalama Maliyetli Portföy Yönetimi:** Supabase veritabanında mükerrer varlık kaydı oluşturmaz; aynı enstrüman tekrar alındığında ağırlıklı ortalama birim maliyet ($AOM$) formülü ile varlığı konsolide eder:
  $$\text{Yeni Maliyet} = \frac{(EskiLot \times EskiMaliyet) + (EklenenLot \times EklenenMaliyet)}{EskiLot + EklenenLot}$$
- **Varlık Dağılım & Gerçek Zamanlı K/Z:** Portföydeki varlıkların toplam değerini, `_parsedHisseler` üzerinden beslenen canlı fiyat haritasıyla dinamik hesaplar; kâr/zarar durumunu renk kodlu (`#00E676` / `#FF5252`) metriklerle çizer.
- **Sıfır Taşma (No-Overflow) Arama Modülü:** Ana ekranda klavye açılma gecikmelerini ve piksel taşmalarını önlemek için bağımsız, `autofocus` özellikli ve `rawHisseResults` referanslı bir arama rotası (`MarketSearchScreen`) barındırır.
- **Keep-Alive Cron Entegrasyonu:** Render free-tier üzerinde çalışan sunucunun 15 dakikalık inaktivite sonrası uyku moduna (spin-down) girmesini engellemek için kök `/` endpoint'ine periyodik HTTP health-check ping mekanizması işletir.

---

## 🛠️ Teknoloji Rozetleri & Mimari Yığın

### Teknoloji Rozetleri

<p>
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white" />
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Cross%20Platform-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img alt="FastAPI" src="https://img.shields.io/badge/FastAPI-REST%20Engine-009688?style=flat-square&logo=fastapi&logoColor=white" />
  <img alt="Python" src="https://img.shields.io/badge/Python-3.11-3776AB?style=flat-square&logo=python&logoColor=white" />
  <img alt="Supabase" src="https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?style=flat-square&logo=supabase&logoColor=white" />
  <img alt="PostgreSQL" src="https://img.shields.io/badge/PostgreSQL-15-4169E1?style=flat-square&logo=postgresql&logoColor=white" />
  <img alt="Render" src="https://img.shields.io/badge/Render-Cloud%20Hosting-46E3B7?style=flat-square&logo=render&logoColor=white" />
  <img alt="Uvicorn" src="https://img.shields.io/badge/Uvicorn-ASGI-499848?style=flat-square&logo=gunicorn&logoColor=white" />
  <img alt="HTTP Client" src="https://img.shields.io/badge/HTTP-Dart%20Package-blue?style=flat-square" />
</p>

### Mimari Özeti

- **Mobil İstemci:** Flutter SDK (Material 3, Dark Theme UI, SingleTickerProviderStateMixin, Debounced Search Listener, Slivers & NestedScrollView).
- **Backend Servis:** FastAPI + Uvicorn ASGI; `routers/` modüler mimarisi, Pydantic doğrulama şemaları.
- **Veritabanı Katmanı:** Supabase (PostgreSQL), kullanıcı bazlı RLS politikaları, JWT yetkilendirme.
- **Harici Entegrasyonlar:** BIST asenkron tarayıcı soketleri, TEFAS veri işleme servisleri, harici Cron-Job keep-alive servisi.

---

## 📁 Monorepo Dizin Yapısı

```text
trading_bot_app/
├── backend/
│   ├── main.py                      # FastAPI ana giriş noktası, keep-alive rotası ve CORS middleware
│   ├── requirements.txt             # Backend bağımlılıkları (fastapi, uvicorn, httpx, supabase)
│   ├── routers/
│   │   ├── hisse.py                 # /api/hisse/tara ve anlık teknik istatistik rotaları
│   │   ├── fon.py                   # /api/fon/tum-fonlar ve trend TEFAS rotaları
│   │   ├── kullanici.py             # Portföy CRUD, maliyet konsolidasyon ve favoriler
│   │   └── ai_router.py             # Opsiyonel teknik gösterge ve tahmin motoru
│   └── services/
│       ├── borsa_servisi.py         # Hisse veri kazıma, parse ve sinyal üretimi
│       └── fon_servisi.py           # TEFAS veri akışı ve kategorizasyon filtreleri
│
├── frontend/
│   ├── pubspec.yaml                 # Flutter bağımlılık listesi (supabase_flutter, http, vb.)
│   └── lib/
│       ├── constants/
│       │   └── app_constants.dart   # API URI'leri, çevre sabitleri ve rota şablonları
│       ├── models/
│       │   ├── hisse_model.dart     # Hisse JSON parse ve tip dönüşüm şemaları
│       │   └── fon_model.dart       # Fon ve FonOzetModel veri yapıları
│       ├── portfolio/
│       │   ├── portfolio_summary_card.dart  # Dinamik kâr/zarar ve varlık özet kartı
│       │   └── add_asset_sheet.dart         # Yeni varlık ekleme / maliyet güncelleme arayüzü
│       ├── screens/
│       │   ├── dashboard/
│       │   │   ├── dashboard_screen.dart    # Slivers tabanlı ana terminal ekranı
│       │   │   ├── market_search_screen.dart# İzole tam ekran hisse arama motoru
│       │   │   └── widgets/
│       │   │       ├── hisse_list_view.dart # Sanallaştırılmış BIST liste akışı
│       │   │       ├── fon_list_view.dart   # TEFAS kartları ve kategori filtreleri
│       │   │       └── piyasa_vitrini_widget.dart # Top 5 özet bandı
│       │   ├── hisse/
│       │   │   └── hisse_detay_screen.dart  # Detaylı grafik ve indikatör inceleme ekranı
│       │   └── fon/
│       │       └── fon_detay_screen.dart    # Fon dağılım ve getiri analiz ekranı
│       └── services/
│           └── fon_service.dart     # Client-side HTTP TEFAS istek yöneticisi
│
└── README.md
