"""
Lookalike / Pattern Matching servisi.
FastAPI projesinde doğrudan router olarak import edilebilir.
"""
from __future__ import annotations

import asyncio
from typing import Literal, Optional

import numpy as np
import pandas as pd
import yfinance as yf
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

# ------------------------------------------------------------------
# Pydantic Modelleri
# ------------------------------------------------------------------

class PatternRequest(BaseModel):
    symbol: str = Field(..., examples=["THYAO.IS", "BTC-USD", "AAPL"])
    interval: Literal["1d", "4h"] = "1d"
    period_years: int = Field(5, ge=1, le=10)
    forward_days: int = Field(5, ge=1, le=30, description="İleriye bakış ufku (bar sayısı)")
    rsi_tolerance: float = Field(5.0, ge=1, le=20, description="RSI ± toleransı")
    ema_tolerance: float = Field(2.0, ge=0.5, le=10, description="EMA20 mesafe ± toleransı (%)")
    bb_tolerance: float = Field(0.15, ge=0.05, le=0.5, description="BB pozisyon ± toleransı [0..1]")
    # Anlık göstergeleri override etmek isterseniz (örn. canlı feed'den geliyorsa):
    rsi_override: Optional[float] = None
    ema_dist_override: Optional[float] = None
    bb_pos_override: Optional[float] = None


class Scenario(BaseModel):
    name: str
    probability_pct: float
    description: str


class PatternResponse(BaseModel):
    symbol: str
    interval: str
    last_close: float
    current_indicators: dict
    match_count: int
    win_rate_pct: float
    avg_return_pct: float
    median_return_pct: float
    max_drawdown_pct: float
    best_return_pct: float
    worst_return_pct: float
    scenarios: list[Scenario]
    sample_dates: list[str]


# ------------------------------------------------------------------
# Servis
# ------------------------------------------------------------------

class PatternAnalysisService:
    """Geçmişte benzer teknik durumları bulup forward getiri istatistiği üretir."""

    def __init__(self, symbol: str, interval: str = "1d", period_years: int = 5):
        self.symbol = symbol
        self.interval = interval
        self.period_years = period_years

    # -------- Veri Çekme --------
    async def _fetch_history(self) -> pd.DataFrame:
        if self.interval == "4h":
            # yfinance native 4h yok → 1h çekip 4h'a resample ediyoruz
            # Not: yfinance 1h verisi sadece son ~730 gün için var.
            raw_interval, period = "60m", "730d"
        else:
            raw_interval, period = "1d", f"{self.period_years}y"

        def _download() -> pd.DataFrame:
            return yf.Ticker(self.symbol).history(
                period=period, interval=raw_interval, auto_adjust=True
            )

        try:
            df = await asyncio.to_thread(_download)
        except Exception as e:
            raise ValueError(f"Veri çekme hatası ({self.symbol}): {e}") from e

        if df is None or df.empty:
            raise ValueError(f"{self.symbol} için veri bulunamadı. Sembol doğru mu?")

        df = df.dropna(subset=["Close", "High", "Low"])

        if self.interval == "4h":
            df = df.resample("4h").agg(
                {"Open": "first", "High": "max", "Low": "min",
                 "Close": "last", "Volume": "sum"}
            ).dropna()

        return df

    # -------- İndikatörler --------
    @staticmethod
    def _rsi(series: pd.Series, length: int = 14) -> pd.Series:
        delta = series.diff()
        gain = delta.clip(lower=0).rolling(length).mean()
        loss = (-delta.clip(upper=0)).rolling(length).mean()
        rs = gain / loss.replace(0, np.nan)
        return 100 - (100 / (1 + rs))

    @staticmethod
    def _bollinger_position(series: pd.Series, length: int = 20, n_std: float = 2.0) -> pd.Series:
        ma = series.rolling(length).mean()
        std = series.rolling(length).std()
        width = (2 * n_std * std).replace(0, np.nan)
        return (series - (ma - n_std * std)) / width  # 0=alt bant, 1=üst bant

    def _enrich(self, df: pd.DataFrame) -> pd.DataFrame:
        df = df.copy()
        df["RSI"] = self._rsi(df["Close"])
        df["EMA20"] = df["Close"].ewm(span=20, adjust=False).mean()
        df["EMA_DIST"] = (df["Close"] - df["EMA20"]) / df["EMA20"] * 100.0
        df["BB_POS"] = self._bollinger_position(df["Close"])
        return df

    # -------- Ana analiz --------
    async def analyze(
        self,
        forward_days: int,
        rsi_tolerance: float,
        ema_tolerance: float,
        bb_tolerance: float,
        rsi_override: Optional[float] = None,
        ema_dist_override: Optional[float] = None,
        bb_pos_override: Optional[float] = None,
    ) -> PatternResponse:

        df = await self._fetch_history()
        df = self._enrich(df)

        if len(df) < 60:
            raise ValueError("Analiz için yetersiz veri (min 60 bar gerekli).")

        last = df.iloc[-1]
        current_rsi = rsi_override if rsi_override is not None else float(last["RSI"])
        current_ema_dist = (
            ema_dist_override if ema_dist_override is not None
            else float(last["EMA_DIST"])
        )
        current_bb_pos = (
            bb_pos_override if bb_pos_override is not None
            else float(last["BB_POS"]) if not pd.isna(last["BB_POS"]) else 0.5
        )

        # --- Lookalike koşulu ---
        cond = (
            df["RSI"].between(current_rsi - rsi_tolerance, current_rsi + rsi_tolerance)
            & df["EMA_DIST"].between(
                current_ema_dist - ema_tolerance, current_ema_dist + ema_tolerance
            )
            & ((df["BB_POS"] - current_bb_pos).abs() <= bb_tolerance)
            & df["BB_POS"].notna()
        )

        match_positions = np.where(cond.values)[0]
        # İleri verisi olmayan son barları ele
        match_positions = match_positions[
            match_positions < (len(df) - forward_days)
        ]

        if len(match_positions) == 0:
            raise ValueError(
                "Benzer tarihsel koşul bulunamadı. Toleransları gevşetmeyi deneyin."
            )

        closes = df["Close"].values
        lows = df["Low"].values

        fwd_returns, fwd_drawdowns = [], []
        for p in match_positions:
            entry = closes[p]
            future_close = closes[p + forward_days]
            future_low = lows[p + 1 : p + 1 + forward_days].min()

            fwd_returns.append((future_close - entry) / entry * 100.0)
            fwd_drawdowns.append((future_low - entry) / entry * 100.0)

        fwd_returns = np.asarray(fwd_returns)
        fwd_drawdowns = np.asarray(fwd_drawdowns)

        win_rate = float((fwd_returns > 0).mean() * 100.0)
        avg_ret = float(fwd_returns.mean())
        med_ret = float(np.median(fwd_returns))
        max_dd = float(fwd_drawdowns.min())
        best = float(fwd_returns.max())
        worst = float(fwd_returns.min())

        # --- Senaryolar (gerçek dağılımdan türetilmiş) ---
        total = len(fwd_returns)
        pos_mask = fwd_returns > 2.0
        neu_mask = (fwd_returns >= -2.0) & (fwd_returns <= 2.0)
        neg_mask = fwd_returns < -2.0

        scenarios = [
            Scenario(
                name="Senaryo A: Pozitif Devam",
                probability_pct=round(float(pos_mask.sum()) / total * 100.0, 2),
                description=(
                    f"Fiyat {forward_days} bar içinde %+2'nin üzerinde kapanış yapar."
                ),
            ),
            Scenario(
                name="Senaryo B: Konsolidasyon / Yatay",
                probability_pct=round(float(neu_mask.sum()) / total * 100.0, 2),
                description="Fiyat -%2 ile +%2 bandında yatay seyreder.",
            ),
            Scenario(
                name="Senaryo C: Stop Avı / Düşüş",
                probability_pct=round(float(neg_mask.sum()) / total * 100.0, 2),
                description="Fiyat -%2'nin altına sarkar (risk senaryosu).",
            ),
        ]

        sample_dates = [
            df.index[i].strftime("%Y-%m-%d") for i in match_positions[-10:]
        ]

        return PatternResponse(
            symbol=self.symbol,
            interval=self.interval,
            last_close=float(last["Close"]),
            current_indicators={
                "rsi": round(current_rsi, 2),
                "ema20_distance_pct": round(current_ema_dist, 2),
                "bollinger_position": round(current_bb_pos, 3),
            },
            match_count=int(total),
            win_rate_pct=round(win_rate, 2),
            avg_return_pct=round(avg_ret, 2),
            median_return_pct=round(med_ret, 2),
            max_drawdown_pct=round(max_dd, 2),
            best_return_pct=round(best, 2),
            worst_return_pct=round(worst, 2),
            scenarios=scenarios,
            sample_dates=sample_dates,
        )


# ------------------------------------------------------------------
# FastAPI Router
# ------------------------------------------------------------------

router = APIRouter(prefix="/analysis", tags=["Pattern Analysis"])


@router.post("/pattern", response_model=PatternResponse)
async def analyze_pattern(payload: PatternRequest):
    try:
        service = PatternAnalysisService(
            symbol=payload.symbol,
            interval=payload.interval,
            period_years=payload.period_years,
        )
        return await service.analyze(
            forward_days=payload.forward_days,
            rsi_tolerance=payload.rsi_tolerance,
            ema_tolerance=payload.ema_tolerance,
            bb_tolerance=payload.bb_tolerance,
            rsi_override=payload.rsi_override,
            ema_dist_override=payload.ema_dist_override,
            bb_pos_override=payload.bb_pos_override,
        )
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analiz hatası: {e}")