---
type: meta
title: "Operation Log"
updated: 2026-09-06
---

# Operation Log

Append-only. **New entries go at the TOP.** Format:

```
## [YYYY-MM-DD] <type> | <short title>
- Files changed: list them
- What changed and why (1–3 bullets)
- Any decisions made (link [[Decision Name]] if significant)
```

Types: `fix`, `feature`, `refactor`, `disable`, `config`, `document`

---

## [2026-09-07] config | godot-mcp (editor control) eklendi
- Files changed: `.mcp.json`, `wiki/decisions/engine-godot.md`
- `godot` MCP (Coding-Solo/godot-mcp, npx @coding-solo/godot-mcp) projeye eklendi — Godot editörünü kontrol eder (sahne çalıştır, hata oku).
- GODOT_PATH = `/Users/ahmetbilalozgun/Downloads/Godot.app/Contents/MacOS/Godot` (Godot 4.7.2 stable). Restart gerektirir.
- NOT: Godot.app Downloads'ta — /Applications'a taşınırsa GODOT_PATH kırılır, güncellenmeli.

## [2026-09-07] config | Engine kararı Godot + godot-docs MCP eklendi
- Files changed: `.mcp.json`, `wiki/decisions/engine-godot.md`, `wiki/decisions/_index.md`, `wiki/overview.md`
- Oyun motoru Godot olarak karara bağlandı ([[Engine — Godot]]). Dil: GDScript.
- `godot-docs` MCP (npx @nuskey8/godot-docs-mcp) projeye eklendi — restart gerektirir.

## [2026-09-07] document | Rün Büyücüsü fikri onaylandı, tasarım notları işlendi
- Files changed: `wiki/overview.md`, `wiki/index.md`, `wiki/hot.md`, `wiki/design/**` (6 yeni sayfa + _index), `wiki/decisions/**` (4 yeni sayfa + _index), `wiki/deliverables/**` (Prototip M0 + _index), `wiki/entities/one-dollar-recognizer.md`
- Beyin fırtınası sonucu karara bağlanan oyun fikri (dikey 2D rün-çizme dalga savunması) tam olarak wiki'ye yazıldı: konsept, ekran düzeni, çizim mekaniği, kombo/palet, düşman tasarımı, juice, oturum yapısı.
- Onaylanan kararlar sayfalandı: [[Ekran Düzeni]], [[Loadout Kısıtı]], [[Sessiz Başarısızlık Yok]], [[Zaaf Bonustur, Kapı Değil]]. Açık konular ayrı işaretlendi (para kazanma, kombo penceresi, meta/retention → tahmin üretilmedi).
- Sonraki adım: [[Prototip M0]] (telefonda 4 rün + tek dalga + 2 düşman, 20 dk oyun testi).

## [2026-09-06] document | Wiki memory system scaffolded
- Files changed: `CLAUDE.md`, `wiki/**`, `_templates/**`, `.raw/**`
- Ported the LLM-wiki agent memory system (blank start): governing `CLAUDE.md`, index/hot/log/overview, domain `_index` pages, note templates.
- No game content yet — structure only.
