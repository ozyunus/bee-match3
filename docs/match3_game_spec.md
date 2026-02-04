# 🎮 Match-3 Oyun Projesi – Final İsterler v2.1 (Android)

**Amaç:** Oyunu özellikle veri üretmek için geliştirmek; elde edilen verilerle data science / analytics / ML çalışmaları yapmak.

---

## 🎯 1. Ürün Hedefi
* **Ana hedef:** Kullanıcı davranış verisi toplamak (oynanış, zorluk, bırakma noktaları)
* **İkincil hedef:** 5–80 yaş arası herkesin oynayabileceği, sade ve sevimli bir match-3 deneyimi
* **Monetizasyon:** İkincil / deneysel (veri toplama öncelikli)

---

## 👥 2. Hedef Kitle
* **Yaş aralığı:** 5 – 80
* **Teknik beklenti:**
   * Okuma gerektirmeyen oynanış
   * Tek parmakla kontrol
   * Karmaşık menü yok
* **Davranışsal hedef:**
   * İlk 10 saniyede oyunun anlaşılması
   * Fail durumunda yumuşak geri bildirim

---

## 🧩 3. Oyun Türü ve Teması
* **Tür:** Match-3 (Candy Crush benzeri)
* **Tema:**
   * Renkli
   * Sevimli hayvanlar (arı, tavşan, kedi, ördek, ayı)
   * Canlı animasyonlar
* **Ton:** Pozitif, stres yaratmayan

---

## 🐝 4. Açılış Deneyimi

### Idle Animasyon Ekranı
* **Görsel:** Uçan arı, hafif salınım hareketi
* **Süre:** Maks. 5–7 saniye
* **Kontrol:** Tap ile direkt oyuna geçiş
* **Analytics:**
  ```
  splash_screen_shown:
    - app_version
    - is_first_launch: true/false
  
  splash_screen_skipped:
    - time_shown_ms
    - was_tapped: true/false
  ```

### Onboarding
* **V1:** SCOPE DIŞI - Ayrı tool kullanılacak
* **Not:** Onboarding ile ilgili event'ler bu dokümanda YOK

---

## 🎮 5. Core Gameplay (V1)

### Grid & Hayvanlar
* **Grid boyutu:** 8×8 (sabit)
* **Hayvan türleri:** 5 (arı, tavşan, kedi, ördek, ayı)
* **Kontrol:** Swipe (up / down / left / right)

### Eşleşme Mekanikleri
* **3'lü eşleşme:** Normal patlama
* **4'lü eşleşme (L veya T şekli):**
  * **Striped Animal (Çizgili):** Yatay veya dikey tüm sırayı patlatır
  * Swap yönüne göre belirlenir (yatay swap → yatay striped)
* **5'li eşleşme (düz çizgi):**
  * **Rainbow Animal:** Tıklandığında aynı türdeki tüm hayvanları patlatır

### Power-up Kombinasyonları (V1'de YOK, V2 için hazırlık)
* Striped + Striped → Çarpı patlaması
* Rainbow + Striped → 3 sıra striped
* Rainbow + Rainbow → Tüm tahtayı temizle

---

## 🎯 6. Level Yapısı

### Level Sayısı ve Dağılımı
* **V1 toplam level:** 30
  * Level 1-10: Easy (hamle: 25-30)
  * Level 11-20: Medium (hamle: 20-25)
  * Level 21-30: Hard (hamle: 15-20)

### Level Hedefleri (Objective Types)
1. **Collect (Toplama):**
   * Örnek: "30 arı topla"
   * En az 1, en fazla 2 hayvan türü
   
2. **Break Blockers (Engel Kırma):**
   * **Box (Kutu):** 1 vuruşta kırılır
   * **Ice (Buz):** 2 vuruşta kırılır
   * Örnek: "15 kutu kır"

3. **Drop Ingredients (Obje İndirme):**
   * **Mekanik:** Özel obje (örn: fındık) her hamleden sonra 1 aşağı düşer
   * En alttaki çıkış noktasına ulaşmalı
   * Örnek: "3 fındığı aşağı indir"

### Level Metadata Formatı (JSON)
```json
{
  "level_id": 5,
  "difficulty_tag": "medium",
  "grid_size": "8x8",
  "moves_allowed": 22,
  "objectives": [
    {
      "type": "collect",
      "animal_type": "bee",
      "target_count": 30
    },
    {
      "type": "break_blockers",
      "blocker_type": "box",
      "target_count": 12
    }
  ],
  "initial_blockers": [
    {"x": 2, "y": 3, "type": "box"},
    {"x": 5, "y": 5, "type": "ice"}
  ]
}
```

### Fail Durumu
* **Hamle bittiğinde:**
  1. "Hamle Bitti" nazik ekran
  2. **Rewarded Ad teklifi:** "5 ekstra hamle için reklam izle?" (level başına 1 kez)
  3. Reklam izlenirse → +5 hamle, oyun devam
  4. İzlenmezse veya ikinci fail → Level Failed ekranı

---

## 🧠 7. Veri Odaklı Tasarım (KRİTİK)

### Temel İlkeler
* ✅ Az ama anlamlı event
* ✅ Tutarlı isimlendirme (snake_case)
* ✅ Tek analytics kaynağı (Firebase)
* ✅ Offline-first veri toplama

### Veri Gönderme Stratejisi
* **Anlık gönderim:** `session_start`, `level_start`
* **Batch gönderim:** `move_made` event'leri → Her level sonunda toplu gönder
* **Offline handling:**
  * Device'da maks. 100 event sakla (FIFO)
  * App açılışta bekleyen event'leri gönder
  * 48 saat sonra sil
* **Veri kaybı toleransı:** %5 kabul edilebilir

---

## 📊 8. Analytics & Veri Altyapısı

### ✅ V1 Kullanılacaklar
* **Firebase Analytics:** Event tracking
* **Firebase Crashlytics:** Crash + ANR reporting
* **Firebase Remote Config:** Level metadata (ileride A/B test için)
* **BigQuery:** Auto-export (günlük)

### ⛔ V1'de OLMAYACAK
* Amplitude
* PostHog
* Supabase
* Onboarding analytics (ayrı tool)

### BigQuery Yapısı
* **Auto-export:** `events_YYYYMMDD` tabloları
* **Partitioning:** Date-based (otomatik)
* **Retention:** 90 gün (maliyet optimizasyonu)
* **Custom views (örnek):**
  ```sql
  CREATE VIEW analytics.level_performance AS
  SELECT 
    level_id,
    COUNT(DISTINCT user_pseudo_id) as unique_players,
    AVG(moves_used) as avg_moves,
    SUM(CASE WHEN event_name = 'level_complete' THEN 1 ELSE 0 END) / 
    COUNT(*) as completion_rate
  FROM `events_*`
  WHERE event_name IN ('level_start', 'level_complete')
  GROUP BY level_id;
  ```

---

## 🧾 9. Event Listesi (V1 - Final)

### Session Events
```javascript
session_start:
  - app_version (string)
  - is_first_launch (boolean)
  - device_model (string)
  - os_version (string)

session_end:
  - session_duration_sec (int)
  - levels_played (int)
  - levels_completed (int)
  - ads_watched (int)
```

### Level Events
```javascript
level_start:
  - level_id (int)
  - difficulty_tag (string: "easy" | "medium" | "hard")
  - moves_allowed (int)
  - objective_types (array: ["collect", "break_blockers"])
  - retry_count (int) // Kaçıncı deneme

level_complete:
  - level_id (int)
  - moves_used (int)
  - moves_remaining (int)
  - time_spent_sec (int)
  - stars_earned (int: 1-3) // Performansa göre
  - power_ups_created (int)
  - power_ups_used (int)
  - retry_count (int)

level_fail:
  - level_id (int)
  - fail_reason (string: "out_of_moves" | "quit" | "timeout")
  - moves_used (int)
  - time_spent_sec (int)
  - objectives_progress (json: {"collect_bee": "20/30", "break_box": "12/15"})
  - retry_count (int)
```

### Gameplay Events
```javascript
move_made:
  - level_id (int)
  - move_index (int) // Kaçıncı hamle
  - move_time_ms (int) // Hamleler arası süre
  - swap_from (json: {"x": 2, "y": 3, "animal": "bee"})
  - swap_to (json: {"x": 2, "y": 4, "animal": "cat"})
  - is_valid (boolean)
  - match_type (string: "match_3" | "match_4_L" | "match_4_T" | "match_5")
  - animals_cleared (int)
  - animals_cleared_types (json: {"bee": 3, "cat": 2})
  - cascade_count (int) // Art arda patlamalar
  - blockers_destroyed (int)

power_up_created:
  - level_id (int)
  - move_index (int)
  - power_up_type (string: "striped_horizontal" | "striped_vertical" | "rainbow")
  - position (json: {"x": 4, "y": 5})
  - created_by (string: "match_4" | "match_5")

power_up_activated:
  - level_id (int)
  - move_index (int)
  - power_up_type (string)
  - animals_cleared (int)
  - blockers_destroyed (int)
  - combo_type (string: null | "striped_striped" | "rainbow_striped") // V2
```

### Monetization Events
```javascript
ad_opportunity:
  - placement (string: "level_fail_extra_moves" | "pre_level_boost")
  - level_id (int)
  - ad_available (boolean)

ad_impression:
  - placement (string)
  - level_id (int)
  - ad_provider (string: "admob" | "unity_ads")

ad_rewarded:
  - placement (string)
  - level_id (int)
  - reward_type (string: "extra_moves" | "continue")
  - reward_amount (int: 5) // Kaç hamle verildi

extra_moves_offered:
  - level_id (int)
  - moves_remaining (int: 0)
  - offer_count (int) // Kaçıncı teklif

extra_moves_response:
  - level_id (int)
  - action (string: "watched_ad" | "declined" | "no_ad")
  - moves_granted (int)
```

### Performance Events (Crashlytics Custom Keys)
```javascript
performance_issue:
  - level_id (int)
  - fps_avg (float)
  - memory_mb (int)
  - device_model (string)
  - issue_type (string: "low_fps" | "high_memory" | "anr")
```

---

## 🧪 10. Veri Bilimi Kullanım Alanları

### V1 Analizler (İlk 30 Gün)
1. **Level zorluk haritası:**
   * Completion rate, average moves, fail points
   * SQL: BigQuery views + Data Studio dashboard

2. **Drop-off analizi:**
   * Hangi level'da oyuncular bırakıyor?
   * Cohort retention (Day 1, 7, 30)

3. **Hamle performansı:**
   * Hangi hamleler en etkili? (cascade rate, power-up creation)
   * Invalid move oranları

### V2 Modelleme (30-90 Gün)
4. **Churn prediction:**
   * Son 3 session verisi → Bırakma riski tahmini
   * Features: avg_moves, level_fail_count, session_length

5. **Dynamic difficulty adjustment:**
   * Oyuncu skill seviyesine göre hedef ayarlama
   * ML model: Level completion probability

6. **A/B test infrastructure:**
   * Remote Config ile level tuning
   * Experiment groups: `control` vs `easier_moves`

### V3 Gelişmiş Analytics (90+ Gün)
7. **Segmentasyon:**
   * Casual players vs Hardcore players
   * Ad engagement patterns

8. **LTV prediction:**
   * Retention + ad watch frequency → 30-day LTV

---

## 🧱 11. Teknik Stack

### 🎮 Client
* **Framework:** Flutter 3.24+
* **Game engine:** Flame 1.18+
* **Platform:** Android only (minSdk: 21 / Android 5.0)
* **State management:** Riverpod
* **Local storage:** Hive (event queue için)

### ☁️ Backend
* **Analytics:** Firebase Analytics
* **Crash reporting:** Firebase Crashlytics
* **Remote config:** Firebase Remote Config
* **Data warehouse:** BigQuery (auto-export)

### 📦 Dependencies (pubspec.yaml)
```yaml
dependencies:
  flame: ^1.18.0
  firebase_analytics: ^11.3.3
  firebase_crashlytics: ^4.1.3
  firebase_remote_config: ^5.1.3
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

---

## 🔐 12. Kullanıcı Kimliği & Etik

### Veri Toplama Politikası
* ✅ **Firebase Anonymous User ID:** Otomatik oluşturulan UUID
* ✅ **Device bilgileri:** Model, OS version (anonim)
* ❌ **Kişisel veri:** İsim, email, telefon YOK
* ❌ **Lokasyon:** GPS, IP-based location YOK
* ❌ **Sosyal:** Chat, profil, friend YOK

### KVKK / GDPR Compliance
* **V1:** Türkiye dışında yayınlanmayacak → KVKK yeterli
* **Kullanıcı onayı:** İlk açılışta basit bilgilendirme ekranı
  * "Bu oyun, oyun deneyimini geliştirmek için anonim kullanım verileri toplar."
  * [Kabul Et] butonu (zorunlu değil, sadece bilgilendirme)
* **Veri saklama:** 90 gün sonra BigQuery'den silinir
* **Veri silme talebi:** V2'de eklenecek (app içi "Verilerimi Sil" butonu)

---

## 🚀 13. V1 Scope Özeti

### ✅ VAR
* Android only (minSdk 21)
* 30 level (10 easy, 10 medium, 10 hard)
* Idle giriş animasyonu (5-7 sn, skip edilebilir)
* 5 hayvan türü
* 2 power-up tipi (striped, rainbow)
* 3 objective tipi (collect, break_blockers, drop_ingredients)
* Rewarded ad (level fail'de, level başına 1 kez)
* Firebase Analytics + Crashlytics + BigQuery
* Offline event queue (max 100)

### ❌ YOK
* Login / hesap sistemi
* Leaderboard / PvP
* Event sistemi / daily missions
* Cloud save / cross-device sync
* In-app purchase
* **Onboarding (ayrı tool kullanılacak)**
* Power-up kombinasyonları (V2'de)
* Çoklu dil desteği (sadece görsel)

---

## 🧠 14. Yol Haritası

### 🟢 V1 – Veri Toplama (0-3 Ay)
**Hedef:** İlk 1000 oyuncu, 10,000+ level completion

**Milestone'lar:**
- [ ] Week 1: Flame engine prototype (grid + swap)
- [ ] Week 2: Match mekanikleri + power-up'lar
- [ ] Week 3: 10 level tasarımı + Firebase entegrasyonu
- [ ] Week 4: 30 level tamamlama + ad entegrasyonu
- [ ] Week 5: Beta test (50 kişi)
- [ ] Week 6: Google Play internal test
- [ ] Week 7-8: Soft launch (Türkiye)
- [ ] Week 9-12: Veri toplama + BigQuery dashboard

**Çıktılar:**
* Level completion rates (CSV export)
* Drop-off analysis (Data Studio dashboard)
* Top fail points (SQL query)

---

### 🟡 V2 – Modelleme & Optimizasyon (3-6 Ay)
**Hedef:** 5000+ oyuncu, ML model v1

**Yeni özellikler:**
- [ ] Power-up kombinasyonları
- [ ] Dynamic difficulty (ML-based)
- [ ] A/B test infrastructure (Remote Config)
- [ ] 30 ek level (toplam 60)

**Analizler:**
* Churn prediction model (sklearn / PyTorch)
* Retention cohort analysis
* Level difficulty tuning (otomatik)

---

### 🔵 V3 – Gelişmiş Analitik & Ölçekleme (6-12 Ay)
**Hedef:** 50,000+ oyuncu, multi-platform

**Yeni özellikler:**
- [ ] iOS version
- [ ] Daily missions
- [ ] Leaderboard (anonymous)
- [ ] Event sistemi (seasonal)

**Analytics araçları:**
- [ ] Amplitude (funnel analysis)
- [ ] PostHog (session replay)
- [ ] Supabase (custom dashboards)

**ML modelleri:**
* LTV prediction
* Ad engagement optimization
* Personalized level recommendations

---

## 📋 Geliştirme Kontrol Listesi

### Pre-Development
- [ ] Firebase projesi oluştur (Android app)
- [ ] BigQuery dataset oluştur + auto-export aktif et
- [ ] Level metadata JSON schema'sını finalize et
- [ ] Event naming convention dokümantasyonu
- [ ] Git repo setup (main, dev, feature branches)

### Sprint 1-2: Core Mekanikler
- [ ] Flame engine setup
- [ ] Grid rendering (8x8)
- [ ] Swap mekanikleri
- [ ] Match-3 detection algoritması
- [ ] Cascade logic
- [ ] Hayvan animasyonları (sprite sheets)

### Sprint 3-4: Power-ups & Objectives
- [ ] Striped animal logic
- [ ] Rainbow animal logic
- [ ] Blocker (box, ice) mekanikleri
- [ ] Ingredient drop mekanikleri
- [ ] Objective tracking UI

### Sprint 5-6: Analytics & Polish
- [ ] Firebase Analytics entegrasyonu
- [ ] Event logging (tüm event'ler)
- [ ] Offline event queue (Hive)
- [ ] Crashlytics entegrasyonu
- [ ] Rewarded ad entegrasyonu (AdMob)
- [ ] Idle animasyon ekranı
- [ ] Level failed/complete ekranları

### Sprint 7: Test & Launch
- [ ] 30 level tasarımı (JSON)
- [ ] Internal testing (10 kişi, 1 hafta)
- [ ] Bug fixes
- [ ] Google Play Console setup
- [ ] Internal test track yayını
- [ ] BigQuery dashboard (Data Studio)

---

## 🎯 Başarı Metrikleri (V1)

### Teknik Metrikler
* **Crash-free rate:** > 99.5%
* **ANR rate:** < 0.1%
* **Event delivery rate:** > 95%
* **Avg session length:** > 5 dk

### Oyun Metrikleri
* **D1 retention:** > 40%
* **D7 retention:** > 20%
* **Avg levels per session:** > 3
* **Level completion rate (genel):** > 60%

### Veri Kalitesi
* **Missing events:** < 5%
* **Outlier moves:** < 1% (örn: 100+ move bir level'da)
* **BigQuery query success:** > 99%

---

## 🔥 Altın Kurallar

1. **Bu oyun bir ürün değil, bir veri üretim makinesi.**
2. **Her feature kararı "bu veri üretir mi?" sorusuyla alınır.**
3. **Event schema değişikliği = major version bump.**
4. **Analytics altyapısı olmadan feature yayınlanmaz.**
5. **BigQuery maliyeti haftalık kontrol edilir.**

---

**Hazırlayan:** Claude  
**Revizyon:** v2.1 (Onboarding removed)  
**Tarih:** 15 Ocak 2026