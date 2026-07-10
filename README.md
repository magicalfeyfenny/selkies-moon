# Selkie's Moon ~ until we meet again ~
Hello, this is Fenny. I'm doing a solo game development project for the ACM's Biggest Little Hackathon 2026

Since AI use is allowed if credited, my main goal with this project is to experiment with using agentic AI with GameMaker, since I haven't really gotten the opportunity to use them much and want to see what they can do in the game engine I'm most familiar with. 

## Download
Compiled binaries for the game are available at https://magicalfeyfenny.itch.io/selkies-moon  
Currently, there is a Mac (arm64) build and a Linux (amd64) build

## Gameplay
This is a 2D vertical scrolling shooter, similar to games like Touhou or Dodonpachi.

Controls:
Menus: 
- Up/Down/Left/Right navigates,
- X to go back,
- Z to select

Gameplay: 
- Up/Down/Left/Right moves,
- Z (tap) fires a volley of shots,
- Z (hold) swings a bullet cancelling sword,
- X uses a Bomb and cancels all bullets,
- C (hold) focuses movement and autofires the selected ship's focused shot pattern

You get 3 bombs and 3 lives.  
Bombs do not recover between lives.

The run now contains 10 stages. Each stage has a scrolling wave section, a boss encounter, and a stage-clear transition. Clearing stage 10 moves into the ending and then a credits sequence.

Playable ships:
- Sunrise / Moon: balanced wide shots, a long sword sweep, and a tighter focused shot.
- Sunset / Selkie: wider crescent shots, stronger focused lances, and a shorter crescent sword sweep using the former boss ship art.

Enemies are worth an amount of points based on the enemy type: 
- Turrets (flower bushes): 750
- Popcorn (bees): 500
- Commanders (mayflies): 1200
- Stage variants: value depends on type and stage
- Boss: 30000

Enemies can drop power-ups:
- P: increases shot power up to 5
- B: restores one bomb up to 6
- L: restores one life up to 6
- M: adds cancel meter
- $: bonus score

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

## Credits
GameMaker, IDE v2024.14.4.222, runtime v2024.14.4.268  
GPT 5.4 on Codex v26.406.31014  
Aseprite v1.3.16.1  

Libraries:
  - unit testing: GameMaker Testing Library, https://github.com/DAndrewBox/GM-Testing-Library

Additional asset sourcing:
  - No additional third-party assets were imported in the 10-stage/Selkie update. New enemy and power-up visuals are drawn procedurally in code using the existing palette/style.
