# Brainrot Bunker - Collect & Defend!

A 3D brainrot collection game for Roblox, built for the make.fun
`roblox-brainrot-01` bounty. Every character, name and building in the game
is original; the genre is the collect-and-defend loop popularised by
Steal a Brainrot, taken somewhere of its own.

**Play it:** https://www.roblox.com/games/103423928064883

## How the game plays

1. Brainrots roll off the Meme Machine in the middle of the plaza and wait
   on eight runways, each wearing a floating label with its name, rarity and
   income per second.
2. Walk up and press **E** to buy one. It rides home on top of your head.
3. Drop it on a pedestal at your base (the glowing **PLACE HERE** post) and
   it starts paying you every second.
4. Climb the rarity ladder - Common, Rare, Epic, Legendary, Mythic,
   Brainrot God - across fifteen characters, from the humble Noodle Knight
   (1 dollar a second) to The Final Cucumber (500 a second). Lucky spawns
   roll Gold, Diamond or Rainbow mutations that multiply their income.
5. Defend the hoard: the Sneaky Goblin creeps out of his cave every minute
   or two and makes for any unlocked base. Lock your base for 60 seconds,
   or chase him down during his escape and he drops what he stole.
6. Long game: **Rebirth** trades your cash and everything placed for a
   permanent +1x income multiplier, and a **Lucky Rain** event doubles all
   income for 30 seconds every few minutes.

## Code layout

The place is a Rojo project. `src/server` maps to a `Server` script in
ServerScriptService whose module children each do one job:

| Module | Job |
| --- | --- |
| `Config` | Every tuning number, the 15-character cast, rarities, mutations |
| `PlayerData` | The only store of per-player state, plus leaderstats |
| `WorldBuilder` | Builds the plaza, machine, runways, bases, cave and decor at server start |
| `BrainrotFactory` | Assembles character and goblin models from plain Parts |
| `BaseManager` | Base assignment, owner signs, the 60-second lock and its walls |
| `EconomyService` | Buying, carrying, placing, selling and the 1-second income tick |
| `SpawnDirector` | Stocks the runways on a timer with rarity and mutation rolls |
| `ThiefService` | The goblin's raids, escapes and capture |
| `EventService` | Lucky Rain timing, multiplier and coin rain |
| `RebirthService` | Rebirth pricing and the permanent multiplier |
| `init.server` | Bootstrap: remotes, world build, player lifecycle |

`src/client/Hud.client.luau` is the only client script: the HUD panel, the
Lock and Rebirth buttons and the announcement banner. All money decisions
are made on the server.

## Building

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`,
`screenshots/` and `PLAY.json` into the output directory and writes the
`dossier.json` summary with the vendored make.fun library.

## License

MIT - see `LICENSE`.
