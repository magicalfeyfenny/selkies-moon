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
- C or controller X autofires using the current focus state.
- Shift or controller LB/L1 focuses movement and changes to the focused shot pattern.
- Escape, P, or controller Start opens the dedicated pause menu.

The pause menu can resume play, change display settings, or quit the current attempt to the main menu. During practice, it also exposes live tuning and a restart-segment command.

### Practice and dynamic rank

Practice Select on the main menu can launch any stage as a full stage, waves-only segment, or boss-only segment. Before starting, you can choose the ship and directly set shot power, rank, lives, bombs, cancel meter, and whether rank changes dynamically. Practice attempts are not written to score or clear records, and completed segments return to Practice Select with the setup retained.

Rank is the 0-50 dynamic-difficulty value shown in the gameplay HUD. A normal run starts at 0 and changes with performance. Higher rank increases enemy-wave frequency, enemy firing frequency, and enemy-bullet speed; it does not alter enemy health, player damage, or boss phase count. Practice can either lock rank to a chosen value or leave dynamic rank enabled for testing.

You get 3 bombs and 3 lives.  
Bombs do not recover between lives.

The run contains five consolidated stages. Each stage has a scrolling wave section, a boss encounter, and a stage-clear transition. Clearing stage 5 moves into the ending and then a credits sequence.

Playable ships:
- Sunset / Moon: balanced wide shots, a long sword sweep, and a tighter focused shot.
- Sunrise / Selkie: wider crescent shots, stronger focused lances, and a shorter crescent sword sweep using the former boss ship art.

Enemies are worth an amount of points based on the enemy type: 
- Turrets (flower bushes): 750
- Popcorn (bees): 500
- Commanders (mayflies): 1200
- Stage variants: value depends on type and stage
- Boss: 30000

Enemies can drop two distinct pickup classes:
- $ score pickups appear on a steady defeat cadence and are always bonus points.
- Defeats charge a hidden, stage-scaled resource cadence that creates one resource-only pickup, with a per-stage cap so resources remain valuable.
- P: increases shot power up to 5
- B: restores one bomb up to 6
- L: restores one life up to 6
- M: adds cancel meter

When you cancel a bullet, it turns into a medal that vacuums towards the player.  
When the medal is collected, it increases your points by 100 and gives you 1 "cancel meter" point.  
When the "cancel meter" fills up, it activates Berserk mode.  
On Berserk activation and ending, all bullets are cancelled.  
While in Berserk mode, your sword swings faster and wider, and you can only use the sword.  
Berserk drains on its own over time.

The title menu also includes a CG Gallery and Music Room for browsing existing art and previewing the stage music.

Generally the best scoring strategy is to use bombs when a lot of bullets are on screen, focus when you need precise movement, and use your sword to break down the bullets in front of you.

## Build
Download GameMaker from https://gamemaker.io/en/download and install it.  
Open the .yyp file and run by pressing F5 or clicking the play button in the top toolbar.

## Documentation

- [Project state](docs/PROJECT_STATE.md): compact current capabilities, validated facts, and known gaps.
- [Architecture and task routing](docs/ARCHITECTURE.md): runtime ownership and the smallest source scope for each task.
- [Development guide](docs/DEVELOPMENT.md): project layout, conventions, and the common change workflow.
- [Gameplay systems](docs/GAMEPLAY_SYSTEMS.md): input, stage flow, rank, weapons, enemies, bosses, pickups, pause, and story flow.
- [Data formats](docs/DATA_FORMATS.md): story JSON, persistence schemas, boss phase descriptors, and practice requests.
- [Validation](docs/VALIDATION.md): governance checks, GMTL, CI, visual QA, and YYC.
- [Asset pipelines](docs/ASSET_PIPELINES.md): generated art, 3D, portrait, and audio ownership.

All project-owned GML functions also carry `/// @func` API comments beside their implementation.

Boss encounters demonstrate their complete seed set, then complete variant sets, and finish with a unique non-repeated signature attack. See [Gameplay systems](docs/GAMEPLAY_SYSTEMS.md#bosses) for the current encounter progression.

### Tests

Run the complete GMTL suite from the repository root:

~~~zsh
GMTL_TEST_ATTEMPTS=8 ./tools/run_gmtl_tests.zsh
~~~

The retry count accounts for intermittent GameMaker asset-compiler crashes. A valid run must reach the complete GMTL summary with every test passing.

## Credits
GameMaker, IDE v2024.14.4.222, runtime v2024.14.4.268  
GPT 5.4 on Codex v26.406.31014  
Aseprite v1.3.16.1  

Libraries:
  - unit testing: GameMaker Testing Library, https://github.com/DAndrewBox/GM-Testing-Library

Additional asset sourcing:
  - No additional third-party assets were imported in the 10-stage/Selkie update. New enemy and power-up visuals are drawn procedurally in code using the existing palette/style.
