import asyncio
import httpx
import pandas as pd
import yfinance as yf
from fastapi import APIRouter

# Kendi scanner dosyanı içe aktar
import scanner

router = APIRouter()

# ==========================================
# 1. TARAMA ENDPOINT'LERİ (/tara ve /tara/{mode})
# ==========================================
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


# ==========================================
# 2. TARİHSEL GRAFİK ENDPOINT'İ (/tarihsel/{symbol})
# ==========================================
def _fetch_yahoo_data(clean_symbol: str, period: str, interval: str):
    """Yahoo Finance senkron çalıştığı için ayrı thread'e devrediyoruz."""
    try:
        ticker = yf.Ticker(clean_symbol)
        df = ticker.history(period=period, interval=interval)
        if (df is None or df.empty) and not clean_symbol.endswith(".IS"):
            ticker = yf.Ticker(f"{clean_symbol}.IS")
            df = ticker.history(period=period, interval=interval)
        return df
    except Exception:
        return None

@router.get("/tarihsel/{symbol}")
async def get_hisse_tarihsel(symbol: str, period: str = "1mo"):
    clean_symbol = symbol.strip().upper().replace("BIST:", "").replace("BINANCE:", "").replace("NASDAQ:", "")

    # 1. Binance Aselsan / Kripto Kontrolü
    binance_sym = clean_symbol if clean_symbol.endswith("USDT") else f"{clean_symbol}USDT"
    binance_intervals = {
        "1d": ("15m", 96),
        "5d": ("1h", 120),
        "1mo": ("1d", 30),
        "1y": ("1w", 52),
        "5y": ("1M", 60),
    }
    b_interval, b_limit = binance_intervals.get(period, ("1d", 30))
    binance_url = f"https://api.binance.com/api/v3/klines?symbol={binance_sym}&interval={b_interval}&limit={b_limit}"

    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            b_res = await client.get(binance_url)
            if b_res.status_code == 200:
                raw_klines = b_res.json()
                if isinstance(raw_klines, list) and len(raw_klines) > 0:
                    chart_data = []
                    for k in raw_klines:
                        unix_time = int(k[0]) // 1000
                        chart_data.append({
                            "time": unix_time,
                            "open": round(float(k[1]), 4 if float(k[1]) < 1 else 2),
                            "high": round(float(k[2]), 4 if float(k[2]) < 1 else 2),
                            "low": round(float(k[3]), 4 if float(k[3]) < 1 else 2),
                            "close": round(float(k[4]), 4 if float(k[4]) < 1 else 2),
                            "volume": int(float(k[5]))
                        })
                    return {"status": "success", "symbol": clean_symbol, "period": period, "data": chart_data}
    except Exception:
        pass

    # 2. Yahoo Finance / BIST - NASDAQ Kontrolü
    interval_map = {"1d": "5m", "5d": "30m", "1mo": "1d", "1y": "1d", "5y": "1wk"}
    interval = interval_map.get(period, "1d")

    df = await asyncio.to_thread(_fetch_yahoo_data, clean_symbol, period, interval)

    if df is None or df.empty:
        return {"status": "error", "message": f"{clean_symbol} için veri bulunamadı.", "data": []}

    try:
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


# ==========================================
# 3. GÜNLÜK İSTATİSTİKLER ENDPOINT'İ (/gunluk-istatistikler)
# ==========================================
@router.get("/gunluk-istatistikler")
def gunluk_istatistikler():
    tum_hisseler = scanner.get_scan_results() 
    
    if not tum_hisseler:
        return {"islem_durumu": "hata", "mesaj": "Veri çekilemedi."}

    gecerli_hisseler = []
    for h in tum_hisseler:
        try:
            symbol = h.get("symbol", "").replace("BIST:", "")
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

    gainers = sorted(gecerli_hisseler, key=lambda x: x['change'], reverse=True)[:10]
    losers = sorted(gecerli_hisseler, key=lambda x: x['change'])[:10]
    volume_leaders = sorted(gecerli_hisseler, key=lambda x: x['volume'], reverse=True)[:10]

    return {
        "islem_durumu": "basarili",
        "gainers": gainers,
        "losers": losers,
        "volume_leaders": volume_leaders
    }