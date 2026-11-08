from fastapi import APIRouter
import httpx
import asyncio
import requests
from services.fon_servisi import fetch_one_cikanlar, fetch_fon_detay, fetch_tum_fonlar

router = APIRouter()

# --- ÖNBELLEKLER (API anlık kesilirse boş dönmemesi için) ---
_cached_yabanci = {"islem_durumu": "basarili", "tum_yabancilar": [], "kazananlar": [], "kaybedenler": []}
_cached_kripto = {"islem_durumu": "basarili", "tum_kriptolar": [], "kazananlar": [], "kaybedenler": []}


def _sinyal_uret(price: float, ema20: float, rsi: float, rel_vol: float) -> str:
    """BIST hisselerindeki gibi VIP / AGRESİF / POZİTİF sinyal etiketi üretir."""
    if rel_vol >= 2.0 and price > ema20 and 50 <= rsi <= 75:
        return "VIP SİNYAL"
    elif rel_vol >= 1.5 and rsi > 60:
        return "AGRASİF"
    elif price > ema20:
        return "POZİTİF"
    return "NÖTR"


# ============================================================================
# 1. ALTIN PİYASASI
# ============================================================================
def _fetch_canli_altin_piyasasi():
    try:
        url = "https://finans.truncgil.com/today.json"
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
        res = requests.get(url, headers=headers, timeout=10)
        
        if res.status_code != 200:
            return []

        data = res.json()
        altin_kodlari = {
            "gram-altin": {"kod": "GRA", "name": "Gram Altın"},
            "gram-gumus": {"kod": "GUMUS", "name": "Gram Gümüş"},
            "ceyrek-altin": {"kod": "CEY", "name": "Çeyrek Altın"},
            "yarim-altin": {"kod": "YAR", "name": "Yarım Altın"},
            "tam-altin": {"kod": "TAM", "name": "Tam Altın"},
            "cumhuriyet-altini": {"kod": "CUM", "name": "Cumhuriyet Altını"},
            "ata-altin": {"kod": "ATA", "name": "Ata Altın"},
            "22-ayar-bilezik": {"kod": "BLZ", "name": "22 Ayar Bilezik"},
            "ons": {"kod": "ONS", "name": "Ons Altın"}
        }

        altin_listesi = []
        for key, meta in altin_kodlari.items():
            if key in data:
                item = data[key]
                try:
                    alis = float(str(item.get("Alış", "0")).replace(".", "").replace(",", "."))
                    satis = float(str(item.get("Satış", "0")).replace(".", "").replace(",", "."))
                    degisim_str = str(item.get("Değişim", "0")).replace("%", "").replace(",", ".").strip()
                    degisim = float(degisim_str) if degisim_str else 0.0
                except Exception:
                    alis, satis, degisim = 0.0, 0.0, 0.0

                altin_listesi.append({
                    "symbol": meta["kod"],
                    "kod": meta["kod"],
                    "name": meta["name"],
                    "full_name": meta["name"],
                    "price": f"₺{satis:,.2f}" if satis > 0 else "₺0.00",
                    "raw_price": satis,
                    "change": f"{'+' if degisim > 0 else ''}{degisim:.2f}%",
                    "raw_change": degisim,
                    "is_positive": degisim >= 0
                })

        gram_ref = next((x["raw_change"] for x in altin_listesi if x["kod"] == "GRA"), 0.0)
        for item in altin_listesi:
            if item["raw_change"] == 0.0 and item["kod"] not in ["GUMUS", "ONS"]:
                item["raw_change"] = gram_ref
                item["change"] = f"{'+' if gram_ref > 0 else ''}{gram_ref:.2f}%"
                item["is_positive"] = gram_ref >= 0

        return altin_listesi
    except Exception as e:
        print(f"Altın Piyasa Hatası: {e}")
        return []

@router.get("/altinlar")
async def get_altinlar_piyasasi():
    try:
        altinlar = await asyncio.to_thread(_fetch_canli_altin_piyasasi)
        return {"islem_durumu": "basarili", "veri": altinlar}
    except Exception as e:
        return {"islem_durumu": "hata", "hata_detayi": str(e), "veri": []}





@router.get("/tabela-verileri")
async def get_piyasa_tabela():
    tv_url = "https://scanner.tradingview.com/global/scan"
    tickers = [
        "BIST:XU100", "BIST:XU030", "BIST:XU050", "BIST:XUTUM",
        "FX_IDC:USDTRY", "FX_IDC:EURTRY", "FX_IDC:XAUUSD",
    ]
    payload = {
        "symbols": {"tickers": tickers, "query": {"types": []}},
        "columns": ["close", "change"]
    }
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.post(tv_url, json=payload, headers=headers)

        if response.status_code != 200:
            return {"islem_durumu": "hata", "veriler": []}

        data = response.json().get("data", [])
        results = []
        ham_fiyatlar = {}

        tanimlar = {
            "XU100": {"ad": "BIST 100", "tip": "endeks"},
            "XU030": {"ad": "BIST 30", "tip": "endeks"},
            "XU050": {"ad": "BIST 50", "tip": "endeks"},
            "XUTUM": {"ad": "BIST Tüm", "tip": "endeks"},
            "USDTRY": {"ad": "DOLAR / TL", "tip": "doviz"},
            "EURTRY": {"ad": "EURO / TL", "tip": "doviz"},
            "XAUUSD": {"ad": "ONS ALTIN", "tip": "emtia"},
        }

        for item in data:
            sembol = item.get("s", "")
            dizi = item.get("d", [])
            if len(dizi) < 2 or dizi[0] is None:
                continue

            price = float(dizi[0])
            change = float(dizi[1]) if dizi[1] is not None else 0.0

            bulunan_anahtar = next((k for k in tanimlar if k in sembol), None)
            if not bulunan_anahtar:
                continue

            ham_fiyatlar[bulunan_anahtar] = {"fiyat": price, "degisim": change}
            ayar = tanimlar[bulunan_anahtar]

            if ayar["tip"] == "doviz":
                formatted_price = f"₺{price:,.2f}"
            elif bulunan_anahtar == "XAUUSD":
                formatted_price = f"${price:,.2f}"
            else:
                formatted_price = f"{price:,.0f}"

            results.append({
                "kod": bulunan_anahtar,
                "name": ayar["ad"],
                "tip": ayar["tip"],
                "price": formatted_price,
                "raw_price": price,
                "change": f"{'+' if change > 0 else ''}{change:.2f}%",
                "raw_change": round(change, 2),
                "is_positive": change >= 0
            })

        if "USDTRY" in ham_fiyatlar and "XAUUSD" in ham_fiyatlar:
            usd = ham_fiyatlar["USDTRY"]["fiyat"]
            usd_ch = ham_fiyatlar["USDTRY"]["degisim"]
            ons = ham_fiyatlar["XAUUSD"]["fiyat"]
            ons_ch = ham_fiyatlar["XAUUSD"]["degisim"]

            gram_tl = (ons * usd) / 31.1034768
            gram_change = (((1 + (ons_ch / 100.0)) * (1 + (usd_ch / 100.0))) - 1) * 100.0

            results.append({
                "kod": "GRAM_ALTIN",
                "name": "GRAM ALTIN",
                "tip": "emtia",
                "price": f"₺{gram_tl:,.2f}",
                "raw_price": round(gram_tl, 2),
                "change": f"{'+' if gram_change > 0 else ''}{gram_change:.2f}%",
                "raw_change": round(gram_change, 2),
                "is_positive": gram_change >= 0
            })

        return {"islem_durumu": "basarili", "veriler": results}
    except Exception as e:
        return {"islem_durumu": "hata", "hata_detayi": str(e), "veriler": []}


# ============================================================================
# 3. KRİPTO PİYASASI (TÜM USDT PARİTELERİ + TEKNİK İNDİKATÖRLER)
# ============================================================================
@router.get("/kriptolar")
async def get_kripto_piyasasi():
    """
    TradingView Crypto Scanner + Binance üzerinden aktif hacimli TÜM USDT kripto paralarını
    fiyat, değişim, RSI, EMA20, Bollinger ve Hacim verileriyle birlikte çeker.
    HisseDetayScreen ile %100 uyumludur.
    """
    global _cached_kripto
    tv_url = "https://scanner.tradingview.com/crypto/scan"

    # Binance üzerindeki en yüksek hacimli 250 USDT paritesini tüm teknik verileriyle çek
    payload = {
        "filter": [
            {"left": "exchange", "operation": "equal", "right": "BINANCE"},
            {"left": "name", "operation": "match", "right": "USDT$"}
        ],
        "options": {"lang": "tr"},
        "symbols": {"query": {"types": []}, "tickers": []},
        "columns": [
            "name",                     # 0: Sembol (BTCUSDT)
            "close",                    # 1: Fiyat
            "change",                   # 2: Günlük Değişim %
            "description",              # 3: Tam Ad (Bitcoin / TetherUS)
            "RSI",                      # 4: RSI (14)
            "EMA20",                    # 5: EMA 20
            "BB.upper",                 # 6: Bollinger Üst
            "BB.lower",                 # 7: Bollinger Alt
            "relative_volume_10d_calc", # 8: Bağıl Hacim
            "24h_vol|5"                 # 9: 24s Hacim
        ],
        "sort": {"sortBy": "24h_vol|5", "sortOrder": "desc"},
        "range": [0, 250]
    }
    headers = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

    tanimlar = {
        "BTC": "Bitcoin", "ETH": "Ethereum", "SOL": "Solana", "BNB": "BNB",
        "XRP": "Ripple", "DOGE": "Dogecoin", "ADA": "Cardano", "AVAX": "Avalanche",
        "DOT": "Polkadot", "LINK": "Chainlink", "PEPE": "Pepe", "SHIB": "Shiba Inu",
        "NEAR": "NEAR Protocol", "APT": "Aptos", "ARB": "Arbitrum", "SUI": "Sui",
        "FET": "Artificial Superintelligence", "TRX": "TRON", "TON": "Toncoin", "RENDER": "Render"
    }
    # Stabil coinleri kazanan/kaybeden listesinden hariç tutmak için
    stabil_coinler = {"USDC", "FDUSD", "TUSD", "USDP", "DAI", "USDE", "EUR", "BUSD"}

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(tv_url, json=payload, headers=headers)

        if response.status_code == 200:
            data = response.json().get("data", [])
            kripto_sonuclar = []

            for item in data:
                d = item.get("d", [])
                if len(d) < 4 or d[1] is None:
                    continue

                raw_sym = str(d[0]).upper().strip()
                temiz_kod = raw_sym.replace("USDT", "")
                if temiz_kod in stabil_coinler or temiz_kod.endswith(("UP", "DOWN", "BULL", "BEAR")):
                    continue

                fiyat = float(d[1])
                degisim = float(d[2]) if d[2] is not None else 0.0
                rsi = round(float(d[4]), 2) if len(d) > 4 and d[4] is not None else 50.0
                ema20 = round(float(d[5]), 4) if len(d) > 5 and d[5] is not None else fiyat
                bb_up = round(float(d[6]), 4) if len(d) > 6 and d[6] is not None else round(fiyat * 1.05, 4)
                bb_low = round(float(d[7]), 4) if len(d) > 7 and d[7] is not None else round(fiyat * 0.95, 4)
                rel_vol = round(float(d[8]), 2) if len(d) > 8 and d[8] is not None else 1.0

                # Okunaklı tam isim
                ham_isim = str(d[3]).split("/")[0].strip() if d[3] else temiz_kod
                tam_isim = tanimlar.get(temiz_kod, ham_isim)

                if fiyat >= 1000:
                    formatted_price = f"${fiyat:,.2f}"
                elif fiyat >= 1:
                    formatted_price = f"${fiyat:.2f}"
                elif fiyat >= 0.0001:
                    formatted_price = f"${fiyat:.4f}"
                else:
                    formatted_price = f"${fiyat:.6f}"

                kripto_sonuclar.append({
                    "symbol": temiz_kod,
                    "kod": temiz_kod,
                    "name": tam_isim,
                    "full_name": tam_isim,
                    "price": formatted_price,
                    "raw_price": fiyat,
                    "change": f"{'+' if degisim > 0 else ''}{degisim:.2f}%",
                    "raw_change": round(degisim, 2),
                    "is_positive": degisim >= 0,
                    "rsi": rsi,
                    "ema20": ema20,
                    "bb_up": bb_up,
                    "bb_low": bb_low,
                    "rel_vol": rel_vol,
                    "signal": _sinyal_uret(fiyat, ema20, rsi, rel_vol)
                })

            if kripto_sonuclar:
                sirali = sorted(kripto_sonuclar, key=lambda x: x["raw_change"], reverse=True)
                _cached_kripto = {
                    "islem_durumu": "basarili",
                    "kazananlar": sirali[:5],
                    "kaybedenler": list(reversed(sirali[-5:])),
                    "tum_kriptolar": kripto_sonuclar # Hacim sırasına göre en popüler 250 coin
                }
                return _cached_kripto

    except Exception as e:
        print(f"Kripto Tarama Hatası: {e}")

    if _cached_kripto["tum_kriptolar"]:
        return _cached_kripto

    return {"islem_durumu": "hata", "kazananlar": [], "kaybedenler": [], "tum_kriptolar": []}


# ============================================================================
# 4. YABANCI PİYASA / NASDAQ & NYSE (GENİŞ HAVUZ + TEKNİK İNDİKATÖRLER)
# ============================================================================
@router.get("/yabanci-piyasa")
async def get_yabanci_enleri():
    """
    TradingView America Scanner üzerinden en büyük 250 ABD hissesini (NASDAQ & NYSE)
    fiyat, değişim, RSI, EMA20, Bollinger ve Hacim verileriyle birlikte çeker.
    """
    global _cached_yabanci
    url = "https://scanner.tradingview.com/america/scan"

    payload = {
        "filter": [
            {"left": "type", "operation": "in_range", "right": ["stock", "dr"]},
            {"left": "subtype", "operation": "in_range", "right": ["common"]},
            {"left": "is_primary", "operation": "equal", "right": True}
        ],
        "options": {"lang": "en"},
        "symbols": {"query": {"types": []}, "tickers": []},
        "columns": [
            "name",                     # 0: Sembol (AAPL, NVDA)
            "close",                    # 1: Fiyat
            "change",                   # 2: Günlük Değişim %
            "description",              # 3: Şirket Tam Adı (Apple Inc.)
            "RSI",                      # 4: RSI (14)
            "EMA20",                    # 5: EMA 20
            "BB.upper",                 # 6: Bollinger Üst
            "BB.lower",                 # 7: Bollinger Alt
            "relative_volume_10d_calc", # 8: Bağıl Hacim
            "volume"                    # 9: Hacim
        ],
        "sort": {"sortBy": "market_cap_basic", "sortOrder": "desc"},
        "range": [0, 250]  # En büyük 250 ABD şirketi
    }
    headers = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(url, json=payload, headers=headers)

        if response.status_code == 200:
            data = response.json().get("data", [])
            sonuclar = []

            for item in data:
                d = item.get("d", [])
                if len(d) < 3 or d[1] is None:
                    continue

                sembol = str(d[0]).upper().strip()
                price = round(float(d[1]), 2)
                change = round(float(d[2]), 2) if d[2] is not None else 0.0
                sirket_adi = str(d[3]).strip() if len(d) > 3 and d[3] else sembol

                rsi = round(float(d[4]), 2) if len(d) > 4 and d[4] is not None else 50.0
                ema20 = round(float(d[5]), 2) if len(d) > 5 and d[5] is not None else price
                bb_up = round(float(d[6]), 2) if len(d) > 6 and d[6] is not None else round(price * 1.05, 2)
                bb_low = round(float(d[7]), 2) if len(d) > 7 and d[7] is not None else round(price * 0.95, 2)
                rel_vol = round(float(d[8]), 2) if len(d) > 8 and d[8] is not None else 1.0

                sonuclar.append({
                    "symbol": sembol,
                    "kod": sembol,
                    "name": sirket_adi,
                    "full_name": sirket_adi,
                    "price": f"${price:,.2f}",
                    "raw_price": price,
                    "change": f"{'+' if change > 0 else ''}{change:.2f}%",
                    "raw_change": change,
                    "is_positive": change >= 0,
                    "rsi": rsi,
                    "ema20": ema20,
                    "bb_up": bb_up,
                    "bb_low": bb_low,
                    "rel_vol": rel_vol,
                    "signal": _sinyal_uret(price, ema20, rsi, rel_vol)
                })

            if sonuclar:
                sirali = sorted(sonuclar, key=lambda x: x["raw_change"], reverse=True)
                _cached_yabanci = {
                    "islem_durumu": "basarili",
                    "tum_yabancilar": sonuclar,
                    "kazananlar": sirali[:5],
                    "kaybedenler": list(reversed(sirali[-5:]))
                }
                return _cached_yabanci

    except Exception as e:
        print(f"TradingView ABD Tarama Hatası: {e}")

    if _cached_yabanci["tum_yabancilar"]:
        return _cached_yabanci

    return {"islem_durumu": "hata", "tum_yabancilar": [], "kazananlar": [], "kaybedenler": []}


# ============================================================================
# 5. YATIRIM FONLARI ENLERİ
# ============================================================================
@router.get("/fon-enleri")
async def get_yatirim_fon_enleri():
    try:
        tum_fonlar_res = await asyncio.to_thread(fetch_tum_fonlar)
        acik_fon_kodlari = set()
        
        if tum_fonlar_res.get("islem_durumu") == "basarili":
            for f in tum_fonlar_res.get("fonlar", []):
                acik_fon_kodlari.add(f["kod"])

        res = await asyncio.to_thread(fetch_one_cikanlar)
        if not isinstance(res, dict) or res.get("islem_durumu") != "basarili":
            return {"islem_durumu": "hata", "kazananlar": [], "kaybedenler": []}

        yukselenler = res.get("haftanin_yukselenleri", [])
        populer = res.get("populer_fonlar", [])
        
        aday_kodlar = {item['kod'] for item in (yukselenler + populer)}
        islenecek_kodlar = list(aday_kodlar.intersection(acik_fon_kodlari))[:20] 

        async def fon_bilgisi_getir(kod):
            detay = await asyncio.to_thread(fetch_fon_detay, kod, "1ay")
            if detay["islem_durumu"] != "basarili":
                return None
            
            grafik = detay.get("grafik_verileri", [])
            if len(grafik) < 2:
                return None
            
            dun_fiyat = grafik[-2]["price"]
            bugun_fiyat = grafik[-1]["price"]
            if dun_fiyat == 0: 
                return None
                
            degisim = ((bugun_fiyat - dun_fiyat) / dun_fiyat) * 100
            raw_change = round(degisim, 2)
            
            return {
                "symbol": kod,
                "kod": kod,
                "name": detay.get("fon_unvani", "")[:24],
                "full_name": detay.get("fon_unvani", ""),
                "price": f"{bugun_fiyat:,.2f} TL",
                "raw_price": bugun_fiyat,
                "change": f"{'+' if raw_change > 0 else ''}{raw_change:.2f}%",
                "raw_change": raw_change,
                "is_positive": raw_change >= 0
            }

        tasks = [fon_bilgisi_getir(kod) for kod in islenecek_kodlar]
        results = await asyncio.gather(*tasks)
        parsed = [r for r in results if r is not None]

        if not parsed:
            return {"islem_durumu": "hata", "mesaj": "Veri yok", "kazananlar": [], "kaybedenler": []}

        parsed.sort(key=lambda x: x["raw_change"], reverse=True)
        kazananlar = [p for p in parsed if p["is_positive"]][:5]
        kaybedenler = [p for p in parsed if not p["is_positive"]][-5:]
        kaybedenler.reverse() 

        return {
            "islem_durumu": "basarili",
            "kazananlar": kazananlar,
            "kaybedenler": kaybedenler
        }
    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e), "kazananlar": [], "kaybedenler": []}
