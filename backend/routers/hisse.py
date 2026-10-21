from fastapi import APIRouter
import requests
import pandas as pd
import yfinance as yf

# Kendi scanner dosyanı içe aktar
import scanner

router = APIRouter()

@router.get("/tara")
def tara_ve_gonder():
    veriler = scanner.get_scan_results()
    return {"islem_durumu": "basarili", "hisseler": veriler}

@router.get("/tara/{mode}")
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

        if mode == "momentum" and rsi > 60 and rel_vol > 2.0 and change > 2:
            filtrelenmis.append(h)
        elif mode == "opportunity" and rsi < 35 and rel_vol > 1.2:
            filtrelenmis.append(h)
        elif mode == "breakout" and price > ema20 and change > 3.0 and rel_vol > 2.5:
            filtrelenmis.append(h)
        elif mode == "relativeVolume" and vol > (avg_vol * 3):
            filtrelenmis.append(h)
        elif mode == "tradeFocus" and (ema20 < price < ema20 * 1.03) and rsi > 50 and rel_vol > 1.5:
            filtrelenmis.append(h)
        elif mode == "sikisma" and ema20 > 0 and ((bb_up - bb_low) / ema20) < 0.05:
            filtrelenmis.append(h)
        elif mode == "corbaci" and rsi < 25 and price > open_p:
            filtrelenmis.append(h)
        elif mode == "all":
            filtrelenmis.append(h)

    return {"islem_durumu": "basarili", "hisseler": filtrelenmis}

@router.get("/endeksler")
def get_tv_indices():
    url = "https://scanner.tradingview.com/global/scan"
    payload = {
        "symbols": {"tickers": ["BIST:XU100", "BIST:XU030", "BIST:XU500", "FX_IDC:USDTRY", "FX_IDC:EURTRY"], "query": {"types": []}},
        "columns": ["close", "change"]
    }
    
    try:
        response = requests.post(url, json=payload, timeout=10)
        results = []
        for item in response.json().get('data', []):
            sembol = item['s']
            price = item['d'][0]
            change = item['d'][1]
            
            if "XU100" in sembol: endeks_adi = "BIST 100"
            elif "XU030" in sembol: endeks_adi = "BIST 30"
            elif "XU500" in sembol: endeks_adi = "BIST 500"
            elif "USDTRY" in sembol: endeks_adi = "DOLAR / TL"
            elif "EURTRY" in sembol: endeks_adi = "EURO / TL"
            else: continue
            
            formatted_price = f"{price:.2f}" if "TRY" in sembol else f"{price:,.0f}"
            results.append({"name": endeks_adi, "price": formatted_price, "change": f"{'+' if change > 0 else ''}{change:.2f}"})
            
        return {"islem_durumu": "basarili", "veriler": results}
    except Exception as e:
        return {"islem_durumu": "hata", "veriler": []}

@router.get("/tarihsel/{symbol}")
def get_hisse_tarihsel(symbol: str, period: str = "1mo"):
    clean_symbol = symbol.strip().upper()
    ticker_symbol = clean_symbol.replace("BIST:", "")
    if not ticker_symbol.endswith(".IS"):
        ticker_symbol = f"{ticker_symbol}.IS"
        
    interval_map = {"1d": "5m", "5d": "30m", "1mo": "1d", "1y": "1d", "5y": "1wk"}
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
            
        return {"status": "success", "symbol": clean_symbol, "period": period, "data": chart_data}
    except Exception as e:
        return {"status": "error", "message": str(e), "data": []}



@router.get("/gunluk-istatistikler")
def gunluk_istatistikler():
    tum_hisseler = scanner.get_scan_results() 
    
    if not tum_hisseler:
        return {"islem_durumu": "hata", "mesaj": "Veri çekilemedi."}

    gecerli_hisseler = []
    
    # Bozuk veya eksik verileri ayıklayıp float formatına zorluyoruz
    for h in tum_hisseler:
        try:
            symbol = h.get("symbol", "").replace("BIST:", "") # Baştaki BIST: takısını temizle
            change = float(h.get("change", 0))
            volume = float(h.get("volume", 0))
            price = float(h.get("price", 0))
            
            gecerli_hisseler.append({
                "symbol": symbol,
                "price": price,
                "change": change,
                "volume": volume
            })
        except:
            continue

    # 1. En Çok Yükselenler (Değişime göre büyükten küçüğe sırala, ilk 10'u al)
    gainers = sorted(gecerli_hisseler, key=lambda x: x['change'], reverse=True)[:10]
    
    # 2. En Çok Düşenler (Değişime göre küçükten büyüğe sırala, ilk 10'u al)
    losers = sorted(gecerli_hisseler, key=lambda x: x['change'])[:10]
    
    # 3. Hacim Şampiyonları (Hacme göre büyükten küçüğe sırala, ilk 10'u al)
    volume_leaders = sorted(gecerli_hisseler, key=lambda x: x['volume'], reverse=True)[:10]

    return {
        "islem_durumu": "basarili",
        "gainers": gainers,
        "losers": losers,
        "volume_leaders": volume_leaders
    }