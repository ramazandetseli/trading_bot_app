import os
import json
import requests
import pandas as pd
import yfinance as yf
from pydantic import BaseModel
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import scanner
import veriTabani
from fonlar import router as fon_router
from ai_router import router as ai_router
app = FastAPI()

app.include_router(fon_router, tags=["Fon İşlemleri"])
app.include_router(ai_router)

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
    print(" PYTHON: /endeksler endpoint'ine istek geldi! Çalışıyor...") # BURAYA EKLE
    
    url = "https://scanner.tradingview.com/global/scan"
    payload = {
        "symbols": {
            "tickers": ["BIST:XU100", "BIST:XU030", "BIST:XU500", "FX_IDC:USDTRY", "FX_IDC:EURTRY"],
            "query": {"types": []}
        },
        "columns": ["close", "change"]
    }
    
    try:
        response = requests.post(url, json=payload, timeout=10)
        print(f"PYTHON: TradingView'dan yanıt alındı. Status: {response.status_code}") # BURAYA EKLE
        
        data = response.json()
        results = []
        
        for item in data.get('data', []):
            sembol = item['s']
            price = item['d'][0]
            change = item['d'][1]
            
            if "XU100" in sembol: endeks_adi = "BIST 100"
            elif "XU030" in sembol: endeks_adi = "BIST 30"
            elif "XU500" in sembol: endeks_adi = "BIST 500"
            elif "USDTRY" in sembol: endeks_adi = "DOLAR / TL"
            elif "EURTRY" in sembol: endeks_adi = "EURO / TL"
            else: continue
            
            if "TRY" in sembol: formatted_price = f"{price:.2f}"
            else: formatted_price = f"{price:,.0f}"
            
            results.append({
                "name": endeks_adi,
                "price": formatted_price,
                "change": f"{'+' if change > 0 else ''}{change:.2f}"
            })
            
        print(f"🔥 PYTHON: Gönderilen veriler: {results}") # BURAYA EKLE
        return {"islem_durumu": "basarili", "veriler": results}
        
    except Exception as e:
        print(f"🚨 PYTHON HATA: {e}") # BURAYA EKLE
        return {"islem_durumu": "hata", "veriler": []}



@app.get("/hisse-tarihsel/{symbol}")
def get_hisse_tarihsel(symbol: str, period: str = "1mo"):
    clean_symbol = symbol.strip().upper()
    ticker_symbol = clean_symbol.replace("BIST:", "")
    if not ticker_symbol.endswith(".IS"):
        ticker_symbol = f"{ticker_symbol}.IS"
        
    interval_map = {
        "1d": "5m",
        "5d": "30m",
        "1mo": "1d",
        "1y": "1d",
        "5y": "1wk"
    }
    interval = interval_map.get(period, "1d")

    try:
        ticker = yf.Ticker(ticker_symbol)
        df = ticker.history(period=period, interval=interval)
        
        if df is None or df.empty:
            return {"status": "error", "message": f"{clean_symbol} için veri bulunamadı.", "data": []}
            
        df.reset_index(inplace=True)
        time_col = 'Datetime' if 'Datetime' in df.columns else 'Date'
        df = df.dropna(subset=['Close', time_col])
        
        chart_data = []
        for _, row in df.iterrows():
            dt_val = row[time_col]
            unix_time = int(dt_val.timestamp()) if hasattr(dt_val, "timestamp") else int(pd.to_datetime(dt_val).timestamp())

            chart_data.append({
                "time": unix_time,
                "open": round(float(row.get("Open", row["Close"])), 2),
                "close": round(float(row["Close"]), 2),
                "high": round(float(row.get("High", row["Close"])), 2),
                "low": round(float(row.get("Low", row["Close"])), 2),
                "volume": int(row.get("Volume", 0) if not pd.isna(row.get("Volume")) else 0)
            })
            
        return {
            "status": "success",
            "symbol": clean_symbol,
            "period": period,
            "data": chart_data
        }
        
    except Exception as e:
        return {"status": "error", "message": str(e), "data": []}
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

class AlarmSilIstek(BaseModel):
    user_id: str
    symbol: str

@app.get("/alarmlar/{user_id}")
def alarmlari_listele(user_id: str):
    sonuc = veriTabani.alarmYonetici.listele(user_id=user_id)
    return sonuc

@app.post("/alarm-sil")
def alarm_sil(istek: AlarmSilIstek):
    sonuc = veriTabani.alarmYonetici.sil(user_id=istek.user_id, symbol=istek.symbol)
    return sonuc

    
class AlarmDuzenleIstek(BaseModel):
    user_id: str
    symbol: str
    target_price: float

@app.post("/alarm-duzenle")
def alarm_duzenle(istek: AlarmDuzenleIstek):
    sonuc = veriTabani.alarmYonetici.duzenle(
        user_id=istek.user_id, 
        symbol=istek.symbol, 
        target_price=istek.target_price
    )
    return sonuc