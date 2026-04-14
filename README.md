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
- C (hold) autofires the volley of shots that Z (tap) fires

You get 3 bombs and 3 lives.  
Bombs do not recover between lives.

Enemies are worth an amount of points based on the enemy type: 
- Turrets (flower bushes): 750
- Popcorn (bees): 500
- Commaanders (mayflies): 1200
- Boss: 30000

When you cancel a bullet, it turns into a medal that vacuums towards the player.  
When the medal is collected, it increases your points by 100 and gives you 1 "cancel meter" point.  
When the "cancel meter" fills up, it activates Berserk mode.  
On Berserk activation and ending, all bullets are cancelled.  
While in Berserk mode, your sword swings faster and wider, and you can only use the sword.  
Berserk drains on its own over time.  

Generally the best scoring strategy is to use bombs when a lot of bullets are on screen, and use your sword to break down the bullets in front of you. If you can keep mayflies alive, they are by far the most bullet dense, but also dangerous because they currently break a "shmup golden rule" and have curving bullets that move obscenely fast.

## Build
Download GameMaker from https://gamemaker.io/en/download and install it.  
Open the .yyp file and run by pressing F5 or clicking the play button in the top toolbar.

## Credits
GameMaker, IDE v2024.14.4.222, runtime v2024.14.4.268  
GPT 5.4 on Codex v26.406.31014  
Aseprite v1.3.16.1  

Libraries:
  - unit testing: GameMaker Testing Library, https://github.com/DAndrewBox/GM-Testing-Library
