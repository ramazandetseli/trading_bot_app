import os
from supabase import create_client, Client

# Prefer a server-side SERVICE_ROLE key provided via env for RLS bypass on trusted backend.
# Set SUPABASE_SERVICE_ROLE_KEY in your environment; fall back to the existing key if absent.
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://pslgppeawgjpwnhqcqtn.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzbGdwcGVhd2dqcHduaHFjcXRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczMjIzNTIsImV4cCI6MjA5Mjg5ODM1Mn0.Ed_vGrbEuvUuUUZXTIdMkEq09AiFaqmp9bvctVrfjTE")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


class favoriYonetici:
    @staticmethod
    def ekle(user_id: str, symbol: str):
        try:
            clean_symbol = symbol.strip().upper()
            response = supabase.from_("favorites").insert({
                "user_id": user_id,
                "symbol": clean_symbol
            }).execute()

            # Log raw response for easier debugging (RLS errors show up here)
            print(f"🛰️ Supabase insert response: {response}")

            # supabase-py may include an 'error' attribute when rules block the action
            err = getattr(response, 'error', None)
            if err:
                print(f"🚨 Favori ekleme hatası (supabase): {err}")
                return {"status": "error", "message": str(err)}

            print(f"📡 [FAVORİ EKLEDİ] Kullanıcı: {user_id} -> Hisse: {clean_symbol}")
            return {"status": "success", "message": f"{clean_symbol} favorilere eklendi aga."}
        except Exception as e:
            print(f"🚨 Favori ekleme hatası: {e}")
            return {"status": "error", "message": "Bu hisse zaten favorilerinde var veya sistem hatası amk."}
    
    @staticmethod
    def sil(user_id: str, symbol: str):
        try:
            clean_symbol = symbol.strip().upper()
            supabase.from_("favorites")\
                .delete()\
                .eq("user_id", user_id)\
                .eq("symbol", clean_symbol)\
                .execute()
                
            print(f"🗑️ [FAVORİ SİLDİ] Kullanıcı: {user_id} -> Hisse: {clean_symbol}")
            return {"status": "success", "message": f"{clean_symbol} favorilerden kaldırıldı aga."}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    
    @staticmethod
    def listele(user_id: str):
        try:
            response = supabase.from_("favorites")\
                .select("symbol")\
                .eq("user_id", user_id)\
                .execute()
            
            hisse_listesi = [item["symbol"] for item in response.data]
            return {"status": "success", "data": hisse_listesi}
        except Exception as e:
            return {"status": "error", "data": []}



class alarmYonetici:
    @staticmethod
    def ekle(user_id: str, symbol: str, target_price: float, current_price: float):
        try:
            clean_symbol = symbol.strip().upper()
            
            condition = "ABOVE" if target_price > current_price else "BELOW"
            
            response = supabase.from_("alarms").insert({
                "user_id": user_id,
                "symbol": clean_symbol,
                "target_price": target_price,
                "current_price": current_price,
                "alarm_condition": condition,
                "is_triggered": False
            }).execute()

            # Log raw response
            print(f"🛰️ Supabase alarm insert: {response}")

            err = getattr(response, 'error', None)
            if err:
                print(f"🚨 Alarm ekleme hatası (supabase): {err}")
                return {"status": "error", "message": str(err)}

            print(f"📡 [ALARM KURULDU] Kullanıcı: {user_id} -> Hisse: {clean_symbol} Hedef: {target_price}")
            return {"status": "success", "message": f"{clean_symbol} için {target_price} ₺ hedefine alarm kuruldu."}
        
        except Exception as e:
            print(f"🚨 Alarm veritabanı hatası: {e}")
            return {"status": "error", "message": "Alarm kurulurken sistem hatası oluştu."}