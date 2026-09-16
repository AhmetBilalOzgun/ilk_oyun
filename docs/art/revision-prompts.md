# 16 September 2026 visual revision — generation record

Method: built-in image_gen (no CLI/API fallback). Original normal fire wizard atlas is retained, unchanged. Generated PNGs preserve alpha and are copied into this repository; no project asset relies on the Codex cache.

## Wizard atlas prompt

Reference / edit target: assets/wizard/wizard_fire_sheet.png.

Edit target: this existing game animation sprite atlas. Create VARIANT. Preserve the cute friendly small wizard identity: soft face, white beard, floppy hat, simple chunky pixels; never scary, never dark. Preserve EXACT atlas structure, positions, frame bounding boxes, poses and all empty cells: 4 columns by 6 rows, each cell square, output 1024 by 1536. Each character must be wholly within its original cell with generous clear padding; no overlap. Keep all 6 animation rows: idle, cast, hurt, death, victory, ultimate. Keep the existing sequence and silhouette size. Change palette and add only the small readable distinguishing elements described. Simplify details toward tiny 16x16/24x24 pixel sprite aesthetics, hard square pixels, limited colors, no gradient, no antialiasing. True transparent background and transparent empty cells, no checkerboard, no labels, no text. This is a production sprite atlas, not a presentation.

Variants (VARIANT substitution; assets/wizard/forms/KEY.png):

- fire_crit: FIRE CRITICAL form: warm gold and coral robes, tiny golden four-point star on hat, star-shaped held spell
- fire_burn: FIRE BURN form: apricot and ember-red robes, tiny leaf-shaped flame at hat tip, three little floating orange embers
- fire_explosive: FIRE EXPLOSIVE form: tangerine and cream robes, rounded puffy hat, small round fire orb with a simple starburst
- plasma: PLASMA NORMAL form: lavender and turquoise robes, little cyan electric zigzag on hat, round mint plasma orb
- plasma_crit: PLASMA CRITICAL form: lilac and pale gold robes, gold four-point star brooch and hat badge, starry cyan held spell
- plasma_explosive: PLASMA EXPLOSIVE form: purple and pink robes, round puffy hat with cyan band, round plasma orb with pink starburst
- plasma_blind: PLASMA BLINDING form: cream and pastel teal robes, small sunny halo and golden sun hat badge, warm white glowing orb

## World prompt

Use case: stylized-concept. Production background image for a cute pixel-art mobile wizard game. Portrait 1024x1536. Scene: SCENE. Bright open-air daytime, peaceful playful welcoming mood, chunky simple retro 16x16 tile aesthetic with a limited pastel palette, hard clean square pixel edges, no detailed rendering, no gradients. Composition essential: upper 60 percent mostly clear sky and distant landscape, an unobstructed horizontal wide walkable bridge/path crosses the ENTIRE image at exactly 65 percent height, with its flat walking top at that height, lower third river and bridge supports/foreground. Leave the walkable bridge empty for game characters. No characters, no monsters, no UI, no text, no frame, no collage. Everything cheerful and easy to read, not spooky, not dark.

Scenes (assets/worlds/KEY.png):

- meadow: sunny green meadow, daisies, rolling hills, little wooden footbridge over a blue stream
- orchard: peach and cherry blossom orchard, pink treetops, pale blue sky, simple pale stone bridge over a brook
- coast: turquoise seaside, sandy dunes, puffy clouds, wooden boardwalk bridge, faraway tiny sailboat
- autumn: golden autumn grove, amber trees, warm clear sky, rustic timber bridge over a calm river
- snow: pastel snowy valley, friendly rounded snowy pines, powder blue sky, pale stone bridge with snowy edges

## Enemy transparency repair

One edit per original assets/enemies/{goblin,dragon,dev}.png; saved as *_clean.png. Source sprites had transparent holes through bodies. Prompt:

Repair this game sprite atlas: SUBJECT. The source has damaged transparency punching holes through bodies. Restore solid opaque bodies and a clear friendly simple pixel silhouette. Cute retro small pixel art matching a floppy-hat wizard, not scary or detailed. Preserve the exact original 4 columns x 4 rows grid, pose positions and empty cells, proportional frame occupancy, all sprites facing right. Output 1024x1024, 256x256 cells. Rows: four idle poses in row1; attacks in row2 existing cells; red-flash hurt in row3 first cell only; tumble and dissolve death in row4 existing cells. Characters must fit within each cell and have no seams, grid lines, text or labels. Every body and outline pixel fully opaque, ONLY outside sprite transparent. True alpha transparency, no painted black or white backdrop, no checkerboard. Do not add new elements or change which cells contain sprites.

Subjects: little green goblin with brown tunic and wooden club; little purple dragon with teal wing membranes; small stocky stone-grey ogre with purple shorts.

Actual enemy outputs were 1254×1254; AtlasTexture cell regions use 313.5×313.5 and render scaling preserves their prior game size. Wizard outputs are 1024×1536, with 256×256 cells. These are chunky pixel-style assets, not literal 16×16 source images. UI and gesture arrows are native Godot controls/polygons for scalable legibility.

## Review artifacts

Real renderer captures: output/visual-revision/{home,level_select,characters,battle,forms,rhythm-faint,rhythm-ready,rhythm-arrow,battle-world-0..4}.png. The repeatable scene is tests/visual_review.tscn, excluded from Android export with tests and review artifacts.

