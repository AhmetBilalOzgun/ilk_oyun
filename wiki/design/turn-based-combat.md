---
type: design
title: "Turn-Based Savaş ve QTE"
created: 2026-09-10
updated: 2026-09-15
verified: 2026-09-15  # + adaptive ritim zorluğu (piano tiles hızı: kalıcı+oturum skill, Meta.rhythm_speed_scale/record_rhythm_result)
tags:
  - design
  - system
status: approved
domain: system
related:
  - "[[Rün Çizim Mekaniği]]"
  - "[[Kombo ve Palet]]"
  - "[[Zaaf Bonustur, Kapı Değil]]"
  - "[[Sessiz Başarısızlık Yok]]"
code_anchors:
  - repo: game
    symbol: TurnManager
    file: scripts/rpg/turn_manager.gd
  - repo: game
    symbol: MageForm
    file: scripts/rpg/mage_form.gd
  - repo: game
    symbol: InputEvaluator.evaluate
    file: scripts/rpg/input_evaluator.gd
  - repo: game
    symbol: InputSequence
    file: scripts/rpg/input_sequence.gd
  - repo: game
    symbol: RhythmMinigame
    file: scripts/rpg/rhythm_minigame.gd
  - repo: game
    symbol: TurnManager.submit_input_multiplier
    file: scripts/rpg/turn_manager.gd
  - repo: game
    symbol: Battle._on_tile_resolved
    file: scripts/battle.gd
  - repo: game
    symbol: Equipment
    file: scripts/rpg/equipment.gd
  - repo: game
    symbol: Skill
    file: scripts/rpg/skill.gd
  - repo: game
    symbol: Combatant
    file: scripts/rpg/combatant.gd
  - repo: game
    symbol: BattleDamage.compute
    file: scripts/rpg/battle_damage.gd
  - repo: game
    symbol: Battle._player_frames
    file: scripts/battle.gd
  - repo: game
    symbol: Battle._on_transformed
    file: scripts/battle.gd
  - repo: game
    symbol: Battle._spawn_spell_fx
    file: scripts/battle.gd
  - repo: game
    symbol: EnemyAI.choose_action
    file: scripts/rpg/enemy_ai.gd
  - repo: game
    symbol: RelicSet
    file: scripts/rpg/run/relic_set.gd
  - repo: game
    symbol: OrbBoardResult.score
    file: scripts/rpg/run/orb_board_result.gd
  - repo: game
    symbol: OrbBoard
    file: scripts/orb_board.gd
  - repo: game
    symbol: ChoiceGenerator.generate
    file: scripts/rpg/run/choice_generator.gd
  - repo: game
    symbol: RunContent
    file: scripts/rpg/run/run_content.gd
  - repo: game
    symbol: MetaProgress
    file: scripts/meta/meta_progress.gd
  - repo: game
    symbol: MetaProgress.rhythm_speed_scale
    file: scripts/meta/meta_progress.gd
  - repo: game
    symbol: MetaProgress.record_rhythm_result
    file: scripts/meta/meta_progress.gd
---

# Turn-Based Savaş ve QTE

> [!note] 2026-09-13 — Çizim/QTE KALDIRILDI
> Oyunun ekseni "hangi build'i kurup nasıl kullanırım"a kaydırıldı (kullanıcı).
> **Rün çizimi ve QTE tamamen kaldırıldı** ("çizime baybay"). Beceri menüden
> seçilince ANINDA çözülür (tap-to-cast). Aşağıdaki "QTE" terimleri tarihsel;
> döngü artık **BUILD → FIGHT → INTERACT (orb board) → MODIFY (kart) → POWER SPIKE**.

Oyun **turn-based parti RPG**'dir. An-be-an oyuncu becerisi geometri değil KARAR:
hangi kombinasyonu, hangi hedefe, ne zaman. Dexterity katmanı orb board'a taşındı.

## Tur akışı

1. **Sıra hesaplama** — canlı katılımcılar `speed`'e göre sıralanır (yüksek önce,
   stabil; ATB yok). `TurnManager._start_round`.
2. **Oyuncu sırası** — beceriler (normaller + açık birleşimler) menüde listelenir;
   oyuncu beceri + hedef seçer → `select_action` **anında** çözer (durum
   `SELECTING_ACTION → RESOLVING → NEXT_TURN`; QTE state yok).
3. **Düşman sırası** — `EnemyAI.choose_action`: en düşük canlı hedefe en yüksek
   `base_damage`'lı beceri (taban hasar, çarpan yok).

## İki ilke (kodda zorlanır — `BattleDamage.compute`)

- **Fail-soft**: dead-turn yok. Beceri her zaman seçilebilir; birleşim şarj
  dolunca. Cast çarpanı (`skill.qte_bonus_multiplier`) her cast'te tam uygulanır —
  "ıska" kavramı kalktı (zorluk build/düşman/relic'ten gelir, motor cezasından değil).
- **Hasar asla sıfır**: `weakness_effects` → ×1.5, `resist_effects` → ×0.5 ama
  `max(1, ...)`. Zaaf bonustur, kapı değil.

Hasar: `base → (×cast_bonus, relic amp'leri dahil) → (×zaaf VEYA ×direnç) →
(×relic hook: frozen_amp/execute) → max(1)`. Döküm `DamageBreakdown`'da.

## Orb ekonomisi + fizik board (INTERACT) — 2026-09-13

Cup Heroes tarzı: **yenilen düşman başına 1 orb** (`RunState.orbs`). Combat orb
HARCAMAZ — orb sadece kart hak etmek için (kullanıcı kararı). CHOICE düğümünde
**fizik board** açılır (`scripts/orb_board.gd`, kod-kurulu Node2D):
DOKUN-BIRAK ile orb'lar üstten düşer, **SEYREK** peg alanından süzülür.

**Yeniden tasarım (2026-09-13/14, kullanıcı isteği — şans→strateji):** çarpanlar artık
NOKTA/slot değil **YATAY ÇARPAN ÇİZGİsi** (gate); NEGATİF/<1 çarpan YOK; peg 6 satır→**3**
(savrulma az). `_build_gates` her setup'ta **3 gate'i RASTGELE** kurar — çarpan havuzu
`[2,3,4,2,3,2]` shuffle edilir, x konumları `randf_range` ile jitter'lanır (her tur
farklı düzen). Bir çizgiden geçen orb PUAN değil **TOP SAYISI** çoğaltır (mult−1 klon:
x2→1, x3→2, x4→3; `_on_gate_hit`, klon aynı gate'i tekrar tetiklemez, `MAX_ORBS=90`
patlama koruması). Dipteki huni tüm orb'ları toplayıcıya yönlendirir; **puan = toplanan
orb × `ORB_VALUE`** (`OrbBoardResult.score` array-of-1.0 ile çağrılır). Pixel-font +
altın retro çerçeve (`PixelifySans-Bold`; 2026-09-14 `PixelOperator8-Bold`'dan geçildi — o font ğ/Ğ/İ/ş/Ş glyph'leri içermiyordu, Türkçe kırıktı).
Sonra kart ekranı (2026-09-14 yeniden düzen — "çok karışık" → sadeleşti): **tek yatay satır** —
SOL **CAN AL** (büyük kırmızı `+`, `HEAL_FIXED_COST=10` orb, party +`HEAL_FIXED_AMOUNT=25`;
`_on_heal_fixed` doğrudan `run_state.loadouts` iyileştirir + `skip_choice`) · ORTA **3 seçenek kutusu
yan yana** (`_choice_icon` + ad + `cost`; StyleBoxFlat kutu) · SAĞ **PAS** (`»»`, bedava). **reroll**
(15 puan) satır altında ikincil. `ChoiceGenerator` rün draftı + relic'i havuza karıştırır.

## Büyü öncesi RİTİM KOMBO minigame (Retro Gesture Tiles) — 2026-09-14 (revize)

Eski serbest kaydırma/basma yakalama **KALDIRILDI**; ardından tek-toplu-sonuç ritim
minigame'i de **KOMBO dövüşüne** çevrildi (kullanıcı: tatmin/dopamine). Beceri seçilince
`RhythmMinigame` (`scripts/rpg/rhythm_minigame.gd`, kod-kurulu Node2D) açılır: artık skill'in
sabit `input_sequence.steps`'i DEĞİL, **her cast'te RASTGELE** üretilen bir dizi kayar
(5 yön havuzu: `●`=TAP, `◀▶▲▼`=SWIPE). Tile çizgiye gelince oyuncu **DOĞRU JESTİ** yapar:

- **Yön yanlış VEYA ıska (pencere geçti) → KOMBO KIRILIR** — kalan tile'lar düşer, finisher
  kaybolur, minigame erken biter → doğal `NEXT_TURN` ile sıra rakibe geçer.
- Doğru yön + **±0.11s → PERFECT** ("MÜKEMMEL!" + `Input.vibrate_handheld(40)` haptik),
  **±0.26s → GOOD** ("HARİKA!").

**Per-tile büyü (escalation):** tutturulan her tile bir "vuruş"tur — `battle._on_tile_resolved`
caster'dan hedefe bir **fireball** + yükselen hasar sayısı gösterir; ölçek tile index'iyle
büyür. **SON tile = FINISHER** (`FINISHER_WEIGHT=2.0`): daha büyük tile/kutu, `ult` pozu,
**en büyük hasar** (dopamine). Kombo uzunluğu run içinde uzar:
`battle._combo_length()` = `clampi(2 + int(node_index/2), 2, 6)`.

**Hasar sözleşmesi (motor saflığı korundu):** `RhythmMinigame` kombo başarısını tek
`combo_score∈[0,1]`'e indirger (`Σ ağırlık×kalite / Σağırlık`; PERFECT=1.0, GOOD=0.6, ıska=0).
`battle._on_rhythm_finished` bunu `mult = max(miss_multiplier, perfect_multiplier·combo_score)`
(fail-soft floor) yapıp **yeni** `TurnManager.submit_input_multiplier(mult, quality)`'e verir →
mevcut `_apply_action` (TEK olay: şarj/DoT/ölüm/battle-end/ultimate-şarj hepsi korunur). Motor
ritmi/jesti GÖRMEZ. Per-tile sayılar `PF·fraction` (PF = kombo başında `BattleDamage.compute`
ile "hepsi-PERFECT" nihai hasar); toplam ≈ motor `final_damage` (motor otorite). Aggregate FX
`_suppress_aggregate_fx` ile bastırılır (projectile/sayı zaten per-tile'da). Sinyaller:
`tile_resolved(index,total,result,is_finisher,fraction)` + `finished({combo_score,broke,tiles})`.
Eski enum `submit_input(result)` yolu enemy/no-input için korundu.
Temel tempo ~94 BPM (`BEAT_BASE=0.64`), `SPEED_BASE=480`, `_lead=0.72`.
**Wave hızlanması (2026-09-14):** `TurnManager.round_index` her turda (wave) +1; `battle._on_input_requested`
`wave_scale = 1 + waves_passed·0.12` (`RHYTHM_SPEEDUP_PER_WAVE`) hesaplar. Minigame `_speed=SPEED_BASE·k`,
`_beat=BEAT_BASE/k` (uzaysal aralık sabit, notalar hızlanır; tavan `SPEED_MAX_SCALE=2.2`). İlk wave 1.0x.
**Adaptive zorluk (2026-09-15, verified 2026-09-15):** oyun reflekse dayalı — 20 de 60 yaş da zevk alsın
diye piano tiles hızı oyuncunun gerçek oynayışına göre kendini ayarlar (adaptive olan TEK şey ritim hızı).
`speed_scale = wave_scale × Meta.rhythm_speed_scale()`. `MetaProgress` iki hız-skill'i tutar: `rhythm_skill`
KALICI global profil (kaydedilir, `RHYTHM_GLOBAL_GAIN=0.020`/cast — yavaş öğrenir) + `_rhythm_session`
OTURUM (RAM, kaydedilmez, `RHYTHM_SESSION_GAIN=0.080`/cast — hızlı tepki: kötü gün / eli başkasına verme).
Oturum ilk kullanımda kalıcıdan tohumlanır, uygulama kapanınca sıfırlanır. `rhythm_speed_scale()` = `%40
kalıcı + %60 oturum` (`RHYTHM_SESSION_WEIGHT=0.6`), `[RHYTHM_SKILL_MIN=0.6, MAX=1.6]` kırpılır.
`battle._on_rhythm_finished` → `Meta.record_rhythm_result(combo_score, broke)`: `err = score − 0.82`
(`RHYTHM_TARGET_SCORE`), kırılınca `err=min(err,−0.30)`; iki EMA'yı günceller + kaydeder (iyi→hızlan,
zorlandı→yavaşla, kolaylaşma agresif). `rhythm_minigame.setup` clamp tabanı `1.0`→`SPEED_MIN_SCALE=0.6`
(adaptive artık base ALTINA inip yeni/60 yaş için gerçekten yavaşlatabilir). Test: `test_meta_progress.gd`
`_test_rhythm_adaptive`.
Alev büyücüsü asset ihtiyaçları: `wiki/design/alev-buyucu-asset-prompt.md`.

## Relic kartları (MODIFY / POWER SPIKE) — 2026-09-13

Kural-değiştiren, **run boyu kalıcı** kartlar (`Relic` + `RelicSet`,
`ChoiceOption.RELIC`, `RunState.relics`). Savaş motoru hook noktalarında `RelicSet`'e
sorar (düz "+%10 hasar" YOK — hepsi kuralı değiştirir). Katalog (`RunContent.relic_catalog`):

| Relic | hook | etki |
|---|---|---|
| Yaban Ateşi | `burn_spread` | yakma komşu düşmanlara yayılır (`TurnManager._apply_action`) |
| Aşırı Yük | `post_storm_amp` | Shatter cast sonrası bir sonraki cast ×1.5 (`Combatant.pending_amp`) |
| Kalıcı Don | `frozen_amp` | sersem hedefe hasar ×2 (`BattleDamage`) |
| Kondansatör | `charge_gain_mult` | şarj ×1.5 hızlı dolar |
| Köz | `dot_amp` | DoT ×1.6 |
| Kan Bağı | `lifesteal` | verilen hasarın %25'i can (`Combatant.heal`) |
| İnfaz | `execute` | canı <%30 hedefe ×1.6 (`BattleDamage`) |
| Delici | `shatter_pierce` | Shatter direnci deler (`BattleDamage`) |

## Beceri modeli — normaller + birleşim matrisi (güncel 2026-09-13)

- **Normal beceri**: tuttuğun her rün bir normal cast verir (`Skill.rune_id`);
  seçilince anında çözülür, `qte_bonus_multiplier` cast çarpanı olarak uygulanır.
- **Birleşim (combo)**: `requires_charge = true`. **İki farklı element rünü** tutunca
  o çiftin birleşimi EMERGENT açılır (`RunLoadout.available_skills`); şarj dolunca
  menüde seçilebilir; seçilince anında büyük çarpan + durum etkisi, şarj sıfırlanır.
  **Artık çizim yok** — `rune_sequence` sadece hangi iki rünün gerektiğini işaretler.
- **TAM MATRİS** (6 çift, `RunContent.catalog`): ember+storm→Plazma(Burn dot),
  frost+storm→Buz Fırtınası(Freeze stun), gale+storm→Siklon(Push), ember+frost→
  Buhar(Shatter burst), ember+gale→Ateş Fırtınası(Burn dot), frost+gale→Kar
  Fırtınası(Freeze stun).
- **Keşif anı**: bir seçim yeni birleşim açınca `RunManager.combo_discovered` →
  "YENİ BİRLEŞİM" flash (dopamine). Mono büyücüyü farklı element draftına iter.

## Oyun içeriği: 3 mono büyücü + ortak katalizör (güncel 2026-09-12)

Oyun başında oyuncu **3 mono-element büyücüden** birini seçer (`RunContent.party`,
`Meta.selected_character`). İlk 3 bölüm **tek karakterle** oynanır ve kolaydır
(`RunContent.single_party`, `LEVEL_COUNT`=3, NÖTR düşmanlar, yumuşak ölçek 0.15/sv).

- **Kor** (Ateş) — ember; **Buz** (Frost) — frost; **Yel** (Rüzgar) — gale.
- Her büyücü element rünüyle başlar; seçimlerde **storm (yıldırım)** rününü draft
  edince kendi birleşimi EMERGENT açılır — **ortak katalizör** storm:
  ember+storm→**Plazma** (yakma), frost+storm→**Buz Fırtınası** (stun),
  gale+storm→**Siklon** (push). Mono büyücü doğal olarak yalnız kendi combosunu
  açar (element rünü tek kişide). `tempest`(frost+gale) kaldırıldı.

## Şarj barı + wave-arası decay (2026-09-12)

`Combatant.charge` / `charge_max` (varsayılan 100, `BattleConfig.charge_max`).
Hasar **verildiğinde ve alındığında** miktar kadar dolar (vurana + yiyene, DoT dahil).
`select_action` şarj dolu değilse birleşim becerisini reddeder (UI de sunmamalı).
Savaş **içinde** decay yoktur — şarj serbestçe birikir, birleşim kullanınca 0'lanır.

**Wave-arası decay (`WAVE_CHARGE_DECAY`=0.20, battle.gd):** şarj eskiden her savaşta
yeni `Combatant` ile **sıfırdan** başlıyordu (waveler arası taşınmıyordu). Artık HP
gibi (`RunLoadout.current_hp`) savaşlar arası `RunLoadout.charge`'da **taşınır**, ama
her savaş bitişinde **%20 düşer** (`RunLoadout.store_charge`, bileşik round, asla <0:
100→80→64...). battle.gd: savaş başında `cmb.charge = lo.charge`, kazanınca hayatta
kalan için `lo.store_charge(cmb.charge, 0.20)`; düşen üye şarjını sıfırlar. Amaç:
birleşimi istiflemek yerine **doğru wave'de patlatmak stratejik** — beklemenin bedeli var.

## Seviye Eğrisi — 20 bölüm (2026-09-12)

`RunContent.LEVEL_COUNT`=**20**. Her bölüm hâlâ `[BATTLE,CHOICE]×2 → BOSS →
REWARD`. **İlk 3 bölüm tutorial DEĞİŞMEDİ** (nötr, tek yumuşak ölçek 1+0.15i,
byte-özdeş). i>=3 içerik veri-tablosundan (`_LEVELS`) kurulur.

**İki ayrı ölçek** (savaşlar uzar ama oyuncu tek-vuruşta ölmez):
- `hp_scale(i>=3)` = 1.30 + 0.18·(i−2) — dik → boss **DPS-check** → POWER upgrade + combo.
- `dmg_scale(i>=3)` = 1.30 + 0.12·(i−2) — yumuşak → CAN upgrade + heal.

**Zaaf temaları (mono büyücü ADİL).** Oyuncu tek element taşır (Kor=Burn,
Buz=Freeze, Yel=Push) + herkesin draft ettiği storm=Shatter. Draftla her element
rünü açılabildiği için her tema adil; **zaaf bonus, kapı değil** (direnç yarılar,
min 1). Tema HANGİ aracın en iyi olduğunu söyler:

| Tema | weakness | resist | İtki |
|---|---|---|---|
| `none` | — | — | nötr |
| `storm` | Shatter | — | storm draft + shatterwave (+combo açılır) |
| `elem` | Burn/Freeze/Push | — | kendi elementin (normal+combo) |
| `ward` | — | Shatter | drafte yaslanma, kendi elementine dön |
| `aegis` | Shatter | Burn/Freeze/Push | storm/shatterwave ŞART (combo element-etiketi taşıdığı için o da yarılanır) |

**Tier'ler** (`_LEVELS` yorumları): T1 (4-6) zaaf tanıtımı (storm→elem); T2 (7-10)
combo ekonomisi + kalabalık→hayatta kalma (ward/aegis + tanky boss); T3 (11-15)
karışık tehdit (bruiser/hız, ward/aegis dönüşümlü, L15 savaş-başına farklı tema);
T4 (16-20) ustalık (büyük setler, aegis boss'lar), **L20 capstone Boşluk Devi**
(aegis, ~785hp/53dmg).

Arketipler (`_ARCH`): grunt/runner/archer/brute/wraith/warden/mauler. Boss'lar
(`_BOSS_ARCH`): drake/warlord/golemking/frostcrone/stormlord/voidtitan. Düşman
saldırıları taban hasar (QTE yok); saldırı `effect` etiketi oyuncuya **inert**
(oyuncu Combatant'ın weakness/resist'i tanımsız) — zorluk yalnız HP/hasar/sayı/
tema üzerinden.

## Durum sistemi (birleşim kimliği)

Sıra **başında** işlenir (`TurnManager._begin_turn`), önce yakma sonra stun:

- **Yakma / DoT** (`Skill.dot_fraction`): hedef bir sonraki turu başında son hasarın
  bu oranını (Plazma %40) bir kez daha yer; şarjı da doldurur. Sinyal `dot_applied`.
- **Stun** (`Skill.applies_stun`): hedef bir sonraki turunu atlar. Sinyal `stun_skipped`.

## Veri modelleri

`Character`, `Skill`, `Enemy`, `Combatant` (`scripts/rpg/`). `Enemy`'ye MVP'de
`skills` eklendi (`EnemyAI` saldırı listesi gerektiriyor; düşman QTE yapmaz).
`Skill` birleşim alanları: `requires_charge`, `rune_sequence`, `dot_fraction`,
`applies_stun`.

## Kombo/füzyon motoru SİLİNDİ (2026-09-10)

Eski gerçek-zamanlı kombo/füzyon motoru **tamamen kaldırıldı** (dosyalar silindi,
`deprecated/` dahil): `main.gd`, `main.tscn`, `combo_resolver`, `damage_rules`,
`resolved_spell`, `debug_overlay` + kombo test suite'leri. `RuneDB` sadeleşti
(`runes` + `shape_to_rune`); füzyon/timeScale/pencere/overdrive alanları gitti.
`TurnManager` füzyon iskeleti (`recent_effects`) ve `BattleConfig.enable_elemental_reactions`
silindi. Korunan: `RuneDB`, `IRuneRecognizer`, `FakeRecognizer`, `RecognizerAdapter`,
`RuneTrail`.
