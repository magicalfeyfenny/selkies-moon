# Selkie's Moon ~ until we meet again ~
Hello, this is Fenny. I'm doing a solo game development project for the ACM's Biggest Little Hackathon 2026

Since AI use is allowed if credited, my main goal with this project is to experiment with using agentic AI with GameMaker, since I haven't really gotten the opportunity to use them much and want to see what they can do in the game engine I'm most familiar with. 

## Download
Compiled binaries for the game are available at https://magicalfeyfenny.itch.io/selkies-moon  
Currently, there is a Mac (arm64) build and a Linux (amd64) build

## Gameplay
This is a 2D vertical scrolling shooter, similar to games like Touhou or Dodonpachi.

### Controls

Keyboard and controller can be used at the same time. Connected controllers are detected automatically.

Menus:
- Arrow keys or the D-pad/left stick navigate.
- Z or controller A confirms.
- X or controller B goes back.

Gameplay:
- Arrow keys or the D-pad/left stick move.
- Z or controller A fires a volley when tapped and swings the bullet-cancelling sword when held.
- X or controller B uses a bomb and cancels all bullets.
- C or controller X focuses movement and autofires the selected ship's focused shot pattern.
- Escape, P, or controller Start opens the dedicated pause menu.

The pause menu can resume play, change display settings, or quit the current attempt to the main menu. During practice, it also exposes live tuning and a restart-segment command.

### Practice and dynamic rank

Practice Select on the main menu can launch any stage as a full stage, waves-only segment, or boss-only segment. Before starting, you can choose the ship and directly set shot power, rank, lives, bombs, Berserk meter, and whether rank changes dynamically. Practice attempts are not written to score or clear records, and completed segments return to Practice Select with the setup retained.

Rank is the 0-50 dynamic-difficulty value shown in the gameplay HUD. A normal run starts at 0 and rises with sustained combat, ordinary shootdowns, boss defeats, and Berserk activation; bombing, dying, and continuing lower it. Higher rank increases enemy-wave frequency, enemy firing frequency, and enemy-bullet speed; it does not alter enemy health, player damage, or boss phase count. Practice can either lock rank to a chosen value or leave dynamic rank enabled for testing.

You get 3 bombs and 3 lives.  
Bombs do not recover between lives.

The run contains five themed stages. Each stage has a scrolling wave section, a character boss encounter, and a stage-clear transition. Stage 3 culminates in Mira and Aisha's coordinated finale; stage 5 selects the route-opposing heroine and then moves into the ending and credits.

Playable ships:
- Sunset / Moon: balanced wide shots, a long sword sweep, and a tighter focused shot.
- Sunrise / Selkie: wider crescent shots, stronger focused lances, and a shorter crescent sword sweep using the former boss ship art.

Enemies are worth an amount of points based on the enemy type:
- Stage variants: value depends on type and stage
- Boss: 30000

Enemies can drop two distinct pickup classes:
- Score diamonds appear on a steady defeat cadence and add 5,000 points.
- Ringed resource pickups are awarded sparsely within a per-stage cap.
- P: raises shot power toward 5.
- B: restores one bomb up to 6.
- L: restores one life up to 6.
- M: adds 240 Berserk meter.

When you cancel a bullet, it turns into a medal that vacuums towards the player.  
Collected medals add eight Berserk meter; close-range attacks and sustained fire also build it. At 1,000 meter, Berserk activates automatically, cancels every enemy bullet, and briefly protects the player. While active, every attack becomes a larger, faster route-specific sweep: Selkie uses chakrams and Moon uses a rose whip. Berserk drains over time without a second screen cancel when it ends.

The title menu also includes a CG Gallery and Music Room for browsing existing art and previewing the stage music.

Generally the best scoring strategy is to use bombs when a lot of bullets are on screen, focus when you need precise movement, and use your sword to break down the bullets in front of you.

## Build
Install Git LFS before cloning, or run `git lfs install` followed by
`git lfs pull` in an existing checkout so asset pointers are hydrated.
Download GameMaker from https://gamemaker.io/en/download and install it.  
Open the .yyp file and run by pressing F5 or clicking the play button in the top toolbar.

## Documentation

- [Architecture](docs/ARCHITECTURE.md): runtime ownership, modules, object inheritance, and extension rules.
- [Development guide](docs/DEVELOPMENT.md): project layout, conventions, tests, visual QA, and repository/asset validation.
- [Asset pipeline](docs/ASSET_PIPELINE.md): canonical BLEND, KRA, and Logic sources plus runtime and interchange derivatives.
- [Git LFS migration](docs/LFS_MIGRATION.md): rewritten asset-history scope, preserved jam release, and collaborator recovery.
- [Branch and release policy](docs/BRANCH_AND_RELEASE_POLICY.md): `main`/`dev` roles, pull-request flow, release promotion, hotfixes, and exceptional history rewrites.
- [Agent review policy](docs/AGENT_REVIEW_POLICY.md): risk-scaled fresh-context review, machine-readable attestations, and merge/release authority boundaries.
- [Gameplay systems](docs/GAMEPLAY_SYSTEMS.md): input, stage flow, rank, weapons, enemies, bosses, pickups, pause, and story flow.
- [Data formats](docs/DATA_FORMATS.md): story JSON, persistence schemas, boss phase descriptors, and practice requests.
- [AI-assisted development post-mortem](docs/AI_ASSISTED_DEVELOPMENT_POSTMORTEM.md): project lessons, large-game best practices, and reusable prompt templates.

Project-owned public GML helpers carry `/// @func` API comments beside their implementation where practical.

Boss encounters demonstrate their motif-specific seeds and finish with a unique non-repeated signature attack. See [Gameplay systems](docs/GAMEPLAY_SYSTEMS.md#bosses) for the 3/5/3+3+shared/7/15-phase progression.

### Tests

Run the complete GMTL suite from the repository root:

~~~zsh
GMTL_TEST_ATTEMPTS=8 ./tools/run_gmtl_tests.zsh
~~~

The retry count accounts for intermittent GameMaker asset-compiler crashes. A valid run must reach the complete GMTL summary with every test passing.

## Credits

- GameMaker, IDE v2024.14.4.222 or compatible newer; current tests use LTS 2026
- GPT 5.4 on Codex v26.406.31014
- Krita v5.3.1.1
- Aseprite v1.3.16.1 (legacy/reference work)

Libraries:
  - unit testing: GameMaker Testing Library, https://github.com/DAndrewBox/GM-Testing-Library

Additional asset sourcing:
  - Not Jam pixel fonts by Not Jam, released under CC0; licence copies are preserved under `art/font_sources/`.
  - `spr_text_arrow` is an exact eight-frame migration from `thpj3`, with source attribution in its KRA manifest.
  - The formal [asset pipeline](docs/ASSET_PIPELINE.md) makes `.blend`, `.kra`, and Logic `.logicx` projects the sole 3D, raster, and audio masters respectively; derived OBJ/MTL, PNG, WAV, OGG, and VBUFF files never become competing masters.
