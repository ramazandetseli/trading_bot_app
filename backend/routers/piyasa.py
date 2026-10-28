from fastapi import APIRouter
import httpx
import asyncio
import inspect
import requests
from services.fon_servisi import fetch_tum_fonlar

router = APIRouter()

def _fetch_canli_altin_piyasasi():
    """
    Truncgil canlı altın piyasası verilerini çeker, 
    değişimi 0 gelen fiziki altınların değişimini Gram Altın'a endeksler.
    """
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
                    "price": f"₺{satis:,.2f}" if satis > 0 else "₺0.00",
                    "raw_price": satis,
                    "change": f"{'+' if degisim > 0 else ''}{degisim:.2f}%",
                    "raw_change": degisim,
                    "is_positive": degisim >= 0
                })

        # Çeyrek/Yarım gibi oranları 0 dönenlerin değişimini Gram Altın'dan tamamla
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
    """
    Canlı fiziki altın ve kıymetli maden piyasası verilerini döner.
    """
    try:
        altinlar = await asyncio.to_thread(_fetch_canli_altin_piyasasi)
        return {
            "islem_durumu": "basarili",
            "veri": altinlar
        }
    except Exception as e:
        return {"islem_durumu": "hata", "hata_detayi": str(e), "veri": []}



@router.get("/endeksler")
async def get_piyasa_tabela():
    """
    Sadece üst yatay tabela şeridi için TradingView Scanner üzerinden
    BIST Endekslerini, Döviz Kurlarını ve Gram Altın özetini çeker.
    """
    tv_url = "https://scanner.tradingview.com/global/scan"
    tickers = [
        "BIST:XU100",     # BIST 100
        "BIST:XU030",     # BIST 30
        "BIST:XU050",     # BIST 50
        "BIST:XUTUM",     # BIST Tüm
        "FX_IDC:USDTRY",  # Dolar / TL
        "FX_IDC:EURTRY",  # Euro / TL
        "FX_IDC:XAUUSD",  # Ons Altın ($)
    ]

    payload = {
        "symbols": {"tickers": tickers, "query": {"types": []}},
        "columns": ["close", "change"]
    }

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.post(tv_url, json=payload, headers=headers)

        if response.status_code != 200:
            return {
                "islem_durumu": "hata",
                "mesaj": f"TradingView status: {response.status_code}",
                "veriler": []
            }

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
            
            # Döviz ve emtialarda küsurat göster, endekslerde tam sayıya yuvarla
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

        # Üst şeritte Gram Altın kutucuğu da bulunsun (Ons ve Dolar üzerinden anlık)
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

        return {
            "islem_durumu": "basarili",
            "veriler": results
        }

    except Exception as e:
        return {
            "islem_durumu": "hata",
            "hata_detayi": str(e),
            "veriler": []
        }

@router.get("/kriptolar")
async def get_kripto_piyasasi():
    """
    Binance Public API üzerinden en popüler kripto paraların
    son fiyatlarını ve 24 saatlik yüzdesel değişimlerini çeker.
    """
    url = "https://api.binance.com/api/v3/ticker/24hr"
    takip_listesi = [
        "BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT",
        "DOGEUSDT", "ADAUSDT", "AVAXUSDT", "DOTUSDT", "LINKUSDT",
    ]
    tanimlar = {
        "BTC": "Bitcoin", "ETH": "Ethereum", "SOL": "Solana",
        "BNB": "BNB", "XRP": "Ripple", "DOGE": "Dogecoin",
        "ADA": "Cardano", "AVAX": "Avalanche", "DOT": "Polkadot", "LINK": "Chainlink",
    }
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.get(url, headers=headers)

        if response.status_code != 200:
            return {"islem_durumu": "hata", "kazananlar": [], "kaybedenler": []}

        data = response.json()
        kripto_sonuclar = []

        for item in data:
            symbol = item.get("symbol", "")
            if symbol in takip_listesi:
                temiz_kod = symbol.replace("USDT", "")
                fiyat = float(item.get("lastPrice", 0.0))
                degisim = float(item.get("priceChangePercent", 0.0))

                if fiyat >= 1000:
                    formatted_price = f"${fiyat:,.2f}"
                elif fiyat >= 1:
                    formatted_price = f"${fiyat:.2f}"
                else:
                    formatted_price = f"${fiyat:.4f}"

                kripto_sonuclar.append({
                    "symbol": temiz_kod,
                    "name": tanimlar.get(temiz_kod, temiz_kod),
                    "price": formatted_price,
                    "raw_price": fiyat,
                    "change": f"{'+' if degisim > 0 else ''}{degisim:.2f}%",
                    "raw_change": degisim,
                    "is_positive": degisim >= 0
                })

        sirali = sorted(kripto_sonuclar, key=lambda x: x["raw_change"], reverse=True)
        return {
            "islem_durumu": "basarili",
            "kazananlar": sirali[:5],
            "kaybedenler": list(reversed(sirali[-5:])),
            "tum_kriptolar": sirali
        }

    except Exception as e:
        return {"islem_durumu": "hata", "hata_detayi": str(e), "kazananlar": [], "kaybedenler": []}


@router.get("/yabanci-piyasa")
async def get_yabanci_enleri():
    """
    TradingView Scanner üzerinden popüler ABD devlerini (Mega-Cap)
    ve küresel ETF'leri çekip kazanan/kaybeden olarak döner.
    """
    url = "https://scanner.tradingview.com/global/scan"
    tickers = [
        "NASDAQ:NVDA", "NASDAQ:AAPL", "NASDAQ:TSLA", "NASDAQ:MSFT", "NASDAQ:AMZN",
        "AMEX:SPY", "NASDAQ:QQQ", "NASDAQ:GOOGL", "NASDAQ:META", "NYSE:BRK.B"
    ]
    payload = {
        "symbols": {"tickers": tickers, "query": {"types": []}},
        "columns": ["close", "change"]
    }
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.post(url, json=payload, headers=headers)

        if response.status_code != 200:
            return {"islem_durumu": "hata", "kazananlar": [], "kaybedenler": []}

        data = response.json().get('data', [])
        sonuclar = []

        for item in data:
            sembol = item.get('s', '').split(':')[-1]
            dizi = item.get('d', [])
            if len(dizi) < 2 or dizi[0] is None:
                continue

            price = float(dizi[0])
            change = float(dizi[1]) if dizi[1] is not None else 0.0

            sonuclar.append({
                "symbol": sembol,
                "name": sembol,
                "price": f"${price:,.2f}",
                "raw_price": price,
                "change": f"{'+' if change > 0 else ''}{change:.2f}%",
                "raw_change": change,
                "is_positive": change >= 0
            })

        sirali = sorted(sonuclar, key=lambda x: x["raw_change"], reverse=True)
        return {
            "islem_durumu": "basarili",
            "kazananlar": sirali[:5],
            "kaybedenler": list(reversed(sirali[-5:]))
        }

    except Exception as e:
        return {"islem_durumu": "hata", "hata_detayi": str(e), "kazananlar": [], "kaybedenler": []}

import asyncio
from services.fon_servisi import fetch_one_cikanlar, fetch_fon_detay, fetch_tum_fonlar

@router.get("/fon-enleri")
async def get_yatirim_fon_enleri():
    try:
        # 1. Adım: Sadece TEFAS'ta açık olan fonların kodlarını çekelim
        tum_fonlar_res = await asyncio.to_thread(fetch_tum_fonlar)
        acik_fon_kodlari = set()
        
        if tum_fonlar_res.get("islem_durumu") == "basarili":
            for f in tum_fonlar_res.get("fonlar", []):
                acik_fon_kodlari.add(f["kod"])

        # 2. Adım: Popüler/Yükselen adaylarını alalım
        res = await asyncio.to_thread(fetch_one_cikanlar)
        if not isinstance(res, dict) or res.get("islem_durumu") != "basarili":
            return {"islem_durumu": "hata", "kazananlar": [], "kaybedenler": []}

        yukselenler = res.get("haftanin_yukselenleri", [])
        populer = res.get("populer_fonlar", [])
        
        # Adayları topla ve SADECE açık olanlarla kesiştir
        aday_kodlar = {item['kod'] for item in (yukselenler + populer)}
        islenecek_kodlar = list(aday_kodlar.intersection(acik_fon_kodlari))[:20] 

        parsed = []

        # 3. Adım: Günlük değişim ve SON FİYAT bilgisini çek
        async def fon_bilgisi_getir(kod):
            detay = await asyncio.to_thread(fetch_fon_detay, kod, "1ay")
            if detay["islem_durumu"] != "basarili":
                return None
            
            grafik = detay.get("grafik_verileri", [])
            if len(grafik) < 2:
                return None
            
            dun_fiyat = grafik[-2]["price"]
            bugun_fiyat = grafik[-1]["price"] # BU ARTIK GÜNCEL FİYAT
            
            if dun_fiyat == 0: 
                return None
                
            degisim = ((bugun_fiyat - dun_fiyat) / dun_fiyat) * 100
            raw_change = round(degisim, 2)
            
            return {
                "symbol": kod,
                "kod": kod,
                "name": detay.get("fon_unvani", "")[:24],
                "price": f"{bugun_fiyat:,.2f} TL", # YÜZDE YERİNE FİYAT
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

        # 4. Adım: Sıralama ve Ayıklama
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