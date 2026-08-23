import json
import yfinance as yf
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import requests
import scanner
import os
import veriTabani
from pydantic import BaseModel
from fastapi.responses import HTMLResponse # Bunu en üste ekle

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/tara")
def tara_ve_gonder():
    veriler = scanner.get_scan_results()
    return {
        "islem_durumu": "basarili",
        "hisseler": veriler
    }

@app.get("/analiz")
def ai_analiz(symbol: str, rsi: str, vol: str, price: str, change: str):
    try:
        rsi_val = float(str(rsi).replace(",", "."))
        vol_val = float(str(vol).replace(",", "."))
        price_val = float(str(price).replace(",", "."))
        change_val = float(str(change).replace(",", "."))
    except Exception as parse_err:
        print(f"🚨 Veri tipi uyuşmazlığı hatası! rsi={rsi}, vol={vol}, price={price}, change={change}")
        return {"status": "error", "message": "Veri biçimi hatalı aga."}

    if vol_val > 2.5 and abs(change_val) < 1.5:
        strateji_etiketi = "Kurumsal Akümülasyon (Gizli Mal Toplama)"
        fon_akisi = "Sessiz ve Güçlü Para Girişi"
    elif change_val < -2.0 and vol_val > 2.0:
        strateji_etiketi = "Sert Silkeleme (Ayı Tuzağı - Bear Trap)"
        fon_akisi = "Panik Satışı / Alttan Tahtacı Karşılaması"
    elif change_val > 3.0 and vol_val > 2.5:
        strateji_etiketi = "Kurumsal Ralli Başlangıcı (Balina Hareketi)"
        fon_akisi = "Agresif ve Hacimli Para Girişi"
    elif rsi_val > 75:
        strateji_etiketi = "Köpük Bölgesi (Küçük Yatırımcıya Mal Çakma Riski)"
        fon_akisi = "Yüksek Riskli Dağıtım Evresi"
    else:
        strateji_etiketi = "Yatay Seyir (Sessiz Bekleme Bölgesi)"
        fon_akisi = "Dengeli Para Akışı"

    risk_skoru = 20.0
    if rsi_val > 70 or rsi_val < 30: risk_skoru += 30
    if vol_val > 3.0: risk_skoru += 25
    if abs(change_val) > 4.0: risk_skoru += 15
    risk_skoru = min(risk_skoru, 95.0)

    pi_key = os.getenv("GROQ_API_KEY")    
    url = "https://api.groq.com/openai/v1/chat/completions"
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": "llama-3.3-70b-versatile",
        "messages": [
            {
                "role": "system",
                "content": f"""Sen profesyonel bir Borsa İstanbul Tahta ve Takas Analistisin. 
                Sana gelen indikatör ve hacim ayak izlerini yorumlayarak, arkadaki kurumsal fonların (balinaların) psikolojisini analiz etmelisin. 
                Sıradan teknik analiz cümleleri kurma, doğrudan tahtacının hamlelerine odaklan. Yatırım tavsiyesi verme.
                Saptanan Mevcut Algoritmik Durum: Strateji={strateji_etiketi}, Risk Skoru=%{risk_skoru}, Fon Akışı={fon_akisi}.
                
                Çıktın KESİNLİKLE VE YALNIZCA AŞAĞIDAKİ JSON FORMATINDA ve tamamen TÜRKÇE olmalıdır. Açıklama metni ekleme:
                {{
                "ozet": "Hissenin tahta durumunu, balina hareketini özetleyen 1-2 cümlelik kurumsal analiz.",
                "teknik_durum": "RSI ve hacim kombinasyonuna göre küçük yatırımcı tuzağı var mı, teknik olarak mal nerede durdurulur?",
                "tahtaci_analizi": "Hesaplanan {strateji_etiketi} ve {fon_akisi} durumuna göre tahtacının anlık psikolojisi ve gizli planı nedir?",
                "destek": 0.00,
                "direnc": 0.00,
                "aksiyon": "BALİNA TAKİBİ / SİLKELEME BÖLGESİ / MAL TOPLAMA / RİSKLİ KÖPÜK"
                }}"""
            },
            {
                "role": "user", 
                "content": f"Hisse: {symbol} | Güncel Fiyat: {price_val} TL | Günlük Değişim: %{change_val} | RSI: {rsi_val} | Göreceli Hacim (Vol): {vol_val}"
            }
        ],
        "response_format": {"type": "json_object"}, 
        "temperature": 0.3
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        res_json = response.json()
        
        if "choices" in res_json:
            raw_content = res_json['choices'][0]['message']['content']
            parsed_data = json.loads(raw_content)
            
            parsed_data["strateji_etiketi"] = strateji_etiketi
            parsed_data["risk_skoru"] = risk_skoru
            parsed_data["fon_akisi"] = fon_akisi

            return {
                "status": "success",
                "data": parsed_data
            }
        else:
            return {"status": "error", "message": "Groq kotaları dolu veya meşgul."}
            
    except Exception as e:
        print(f"Sistem Hatası: {e}")
        return {"status": "error", "message": str(e)}


@app.get("/tara/{mode}")
def stratejik_tarama(mode: str):
    tum_hisseler = scanner.get_scan_results() 
    
    if not tum_hisseler:
        return {"islem_durumu": "hata", "hisseler": []}
        
    filtrelenmis = []

    for h in tum_hisseler:
        try:
            price   = float(h.get('price', 0))
            change  = float(h.get('change', 0))
            rsi     = float(h.get('rsi', 50))
            vol     = float(h.get('volume', 0))
            avg_vol = float(h.get('avg_vol', 1.0))
            rel_vol = float(h.get('rel_vol', 1.0))
            ema20   = float(h.get('ema20', 0)) 
            bb_up   = float(h.get('bb_up', 0))
            bb_low  = float(h.get('bb_low', 0))
            open_p  = float(h.get('open', 0))
        except:
            continue

        if mode == "momentum":
            if rsi > 60 and rel_vol > 2.0 and change > 2:
                filtrelenmis.append(h)
                
        elif mode == "opportunity":
            if rsi < 35 and rel_vol > 1.2:
                filtrelenmis.append(h)

        elif mode == "breakout":
            if price > ema20 and change > 3.0 and rel_vol > 2.5:
                filtrelenmis.append(h)
                
        elif mode == "relativeVolume":
            if vol > (avg_vol * 3):
                filtrelenmis.append(h)

        elif mode == "tradeFocus":
            if (ema20 < price < ema20 * 1.03) and rsi > 50 and rel_vol > 1.5:
                filtrelenmis.append(h)

        elif mode == "sikisma":
            if ema20 > 0:
                sikisma_orani = (bb_up - bb_low) / ema20
                if sikisma_orani < 0.05:
                    filtrelenmis.append(h)

        elif mode == "corbaci":
            if rsi < 25 and price > open_p:
                filtrelenmis.append(h)

        elif mode == "all":
            filtrelenmis.append(h)

    return {"islem_durumu": "basarili", "hisseler": filtrelenmis}


@app.get("/endeksler")
def get_tv_indices():
    url = "https://scanner.tradingview.com/turkey/scan"
    payload = {
        "symbols": {
            "tickers": ["BIST:XU100", "BIST:XU030", "BIST:XU500"],
            "query": {"types": []}
        },
        "columns": ["close", "change"]
    }
    
    try:
        response = requests.post(url, json=payload, timeout=10)
        data = response.json()
        results = []
        for item in data.get('data', []):
            ticker = item['s'].split(":")[1]
            price = item['d'][0]
            change = item['d'][1]
            
            if ticker == "XU100":
                endeks_adi = "BIST 100"
            elif ticker == "XU500":
                endeks_adi = "BIST 500"
            else:
                endeks_adi = "BIST 30"
            
            results.append({
                "name": endeks_adi,
                "price": f"{price:,.0f}",
                "change": f"{'+' if change > 0 else ''}{change:.2f}"
            })
        return {"islem_durumu": "basarili", "veriler": results}
    except Exception as e:
        print(f"Endeks köprü hatası: {e}")
        return {"islem_durumu": "hata", "veriler": []}






@app.get("/hisse-tarihsel/{symbol}")
def get_hisse_tarihsel(symbol: str, period: str = "1mo"):
    clean_symbol = symbol.strip().upper()
    # TradingView sembolü direkt gelirse (örn: BIST:THYAO veya THYAO) sonunu temizle (.IS ekle)
    ticker_symbol = clean_symbol.replace("BIST:", "")
    if not ticker_symbol.endswith(".IS"):
        ticker_symbol = f"{ticker_symbol}.IS"
        
    # 🎯 Periyotlara göre en stabil veri aralığını (interval) seçiyoruz amk
    interval = "1d"
    if period == "1d":
        interval = "5m"   # 1 Günlük grafikte 5 dakikalık mumlar
    elif period == "5d":
        interval = "15m"  # 1 Haftalık grafikte 15 dakikalık mumlar

    try:
        ticker = yf.Ticker(ticker_symbol)
        df = ticker.history(period=period, interval=interval)
        
        if df.empty:
            return {"status": "error", "message": f"{clean_symbol} için veri bulunamadı amk."}
            
        # İndeksi sıfırlayıp tarihi sütun yapıyoruz
        df.reset_index(inplace=True)
        
        # yfinance bazen 'Date' bazen 'Datetime' döner, onu zırhlıyoruz amk
        time_col = 'Datetime' if 'Datetime' in df.columns else 'Date'
        
        chart_data = []
        for _, row in df.iterrows():
            # Eğer fiyat verisi yoksa veya işlem hacmi 0 ise (hafta sonu gibi) o satırı atla
            if row["Open"] is None or row["Volume"] == 0:
                continue
                
            unix_time = int(row[time_col].timestamp())
            chart_data.append({
                "time": unix_time,
                "open": float(row["Open"]),
                "high": float(row["High"]),
                "low": float(row["Low"]),
                "close": float(row["Close"]),
                "volume": int(row["Volume"])
            })
            
        return {
            "status": "success",
            "symbol": clean_symbol,
            "period": period,
            "interval": interval,
            "data": chart_data
        }
        
    except Exception as e:
        return {"status": "error", "message": str(e)}




class FavoriIstek(BaseModel):
    user_id: str
    symbol: str


@app.post("/favori-ekle")
def favori_ekle(istek: FavoriIstek):
    sonuc = veriTabani.favoriYonetici.ekle(user_id=istek.user_id, symbol=istek.symbol)
    return sonuc


@app.post("/favori-sil")
def favori_sil(istek: FavoriIstek):
    sonuc = veriTabani.favoriYonetici.sil(user_id=istek.user_id, symbol=istek.symbol)
    return sonuc


@app.get("/favoriler/{user_id}")
def favorileri_listele(user_id: str):
    sonuc = veriTabani.favoriYonetici.listele(user_id=user_id)
    return sonuc

class AlarmIstek(BaseModel):
    user_id: str
    symbol: str
    target_price: float
    current_price: float

@app.post("/alarm-kur")
def alarm_kur(istek: AlarmIstek):
    sonuc = veriTabani.alarmYonetici.ekle(
        user_id=istek.user_id, 
        symbol=istek.symbol, 
        target_price=istek.target_price,
        current_price=istek.current_price
    )
    return sonuc