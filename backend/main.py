from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Rota (Endpoint) Dosyalarını İçeri Aktar
from routers.fon import router as fon_router
from routers.hisse import router as hisse_router
from routers.kullanici import router as kullanici_router
from routers.ai_router import router as ai_router
from routers.piyasa import router as piyasa_router
from routers.economic_calendar import router as calendar_router
from routers.temettu import router as temettu_router

app = FastAPI(title="Finans API", version="2.0")
app = FastAPI(title="Quant Lookalike Engine")

# Router'ı projeye dahil ediyoruz
#app.include_router(pattern_router, prefix="/api")
app.include_router(calendar_router, prefix="/api")

app.include_router(temettu_router, prefix="/api")

# CORS Ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rotaları Bağlama (Prefix ile URL'leri grupladık)
app.include_router(fon_router, prefix="/api/fon", tags=["Fon İşlemleri"])
app.include_router(hisse_router, prefix="/api/hisse", tags=["Hisse ve Piyasa"])
app.include_router(kullanici_router, prefix="/api/kullanici", tags=["Favori ve Alarmlar"])
app.include_router(ai_router, prefix="/api/ai", tags=["Yapay Zeka Analizi"])
app.include_router(piyasa_router, prefix="/api/piyasa", tags=["Piyasa Verileri"])

def ana_sayfa():
    return {"mesaj": "Borsa & Fon Backend API Çalışıyor! 🚀"}