# Single File Formation Mod for Baldur's Gate 3

Makes your companions follow each other in a chain, so that the whole group walks in a single file behind the character you control.

The default triangle formation causes party members to bunch up and clip into each other when moving through tight spaces or while waiting to climb.

## Notes

- Intended for single-player only. In multiplayer, non-host players will not be able to control their characters.
- Party members who are in turn-based mode, in combat, in cutscene dialogue, in camp, downed, dead or ungrouped are automatically removed from the chain; otherwise, they are added.
- Does not affect attached followers; they retain their default behaviour.
- No particular order is enforced. The game naturally orders them by the time they join the party.
- Works fine with party sizes larger than 4.

## Risks

I've tested this mod with a new game and played through Act 1 without any problems. However, this mod has not been battle-tested by the general public.

At its core, this mod uses `Osi.Follow` and `Osi.StopFollow` to manage following. While these functions sound benign, they are  fragile and were observed to produce severe side effects when mismanaged, such as: preventing characters from moving freely or taking actions, stopping them from being downed or dying even after reaching 0 HP and muting voice lines during dialogue cutscenes. These effects can become baked into save files.

## Requirements

- [BG3 Script Extender](https://github.com/Norbyte/bg3se)

## Installation

1. Place `SingleFileFormation.pak` into your mods folder:
   - `C:\Users\[Your Name]\AppData\Local\Larian Studios\Baldur's Gate 3\Mods`
   - Or paste `%LocalAppData%\Larian Studios\Baldur's Gate 3\Mods` into the Windows Explorer address bar.
2. Enable the mod using the in-game mod manager.

## Uninstallation

1. Send your party to camp first before uninstalling. Otheriwse, your companions will be uncontrollable.
2. Delete `SingleFileFormation.pak` from your mods folder.