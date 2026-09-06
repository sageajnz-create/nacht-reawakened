# Codex original plan — Nacht Reawakened

Source: Codex session 2026-09-06 (before implementation). Sage asked for research + a dev plan first; Codex wrote this, then Sage approved and gave C:\Call Of Duty World At War.

---

Yes—this looks feasible. I recommend **“Nacht Reawakened”: the original bunker with modern Zombies progression, polished presentation, and its claustrophobic atmosphere intact.** The first milestone would prove it loads correctly in your WaW installation before building out the features.

I’ve completed the initial research. **Nothing has been installed or modified.**

**What the research established**

- WaW has an established modding toolchain: official Mod Tools through **1.4**, with the game patched to **1.7**. Community patches supplement the tools. [UGX installation guide](https://github.com/UGX-Mods/community-wiki/blob/main/Modding/World-at-War-Modtools/Resources-and-Links/Modtools-Installation-Guide.html)
- Modifying the existing Zombies maps is practical. **COD5-Remastered** provides source and build instructions for separate mods covering all four maps, including Nacht, using compiled `mod.ff` and `.iwd` packages. This is useful technical precedent; any code reuse would require checking its license. [Project source and build instructions](https://github.com/JBShady/COD5-Remastered)
- A full framework transplant is more complicated: UGX Standalone explicitly requires map source, recompilation, and compatible Der Riese scripts. We should therefore start with a focused mod of stock Nacht and verify asset loading before committing to a larger rebuild. [UGX framework requirements](https://github.com/UGX-Mods/community-wiki/blob/main/Modding/World-at-War-Modtools/UGX-Mod-Standalone/UGX-Mod-Standalone-v103-Manual-Installation.html)

**Proposed first release**

| Area | Planned upgrade |
|---|---|
| Progression | A power switch and short, clearly signposted objective to unlock Pack-a-Punch |
| Perks | Juggernog, Speed Cola, Quick Revive with limited solo self-revives, damage-enhancing Double Tap, and Stamin-Up |
| Weapons | Keep the WWII arsenal; add properly tuned upgraded variants, names, effects, and ammo capacities |
| Power-ups | Retain classic drops; make Max Ammo refill magazines too; add a balanced Bonus Points drop |
| Presentation | Clean perk icons, power-up timers, readable purchase prompts, restrained effects, and a custom loading screen |
| Quality of life | Optional zombie counter, adjustable FOV, clearer round transitions, and configurable difficulty |
| Map identity | Preserve the original room layout, barricades, mystery box, and oppressive bunker atmosphere |

My proposed balance is **classic point spending with a stronger late-game progression loop**. Armor, salvage, weapon rarity, elaborate bosses, and imported modern weapons would be later options; each substantially increases implementation and balancing work.

**Development plan**

1. **Verify your installation and prepare the tools.** Identify the game executable, version, language, existing mods, and available tools. Keep development sources in this project and back up anything the toolchain needs to change.

2. **Prove the stock-map approach.** Build a minimal mod that loads Nacht and adds one working interaction. Then test a perk machine and one Pack-a-Punch weapon, including models, sounds, collision, and asset limits. This establishes whether the planned stock-map package works or a custom-map build is necessary.

3. **Implement the gameplay systems.** Separate power, perks, upgrades, drops, and HUD into maintainable scripts. Make purchases and rewards authoritative on the host to avoid co-op duplication and desynchronization.

4. **Polish and balance.** Position machines without obstructing escape routes, tune prices and damage, and make the new interface visually consistent. Geometry changes or major lighting reconstruction would require a suitable editable map source.

5. **Test in-game.** Verify fresh launches, restarts, downs, revives, simultaneous purchases, weapon recovery, power-up stacking, and extended rounds. Target solo and 2–4-player co-op; multiplayer support remains unverified until tested with additional clients.

6. **Package for your installation.** Deliver the compiled mod, source, launch instructions, version notes, and uninstall steps. Target ordinary WaW first; decide whether an engine extension such as T4M is necessary after checking actual asset requirements.

The project folder is empty. I found WaW’s local application-data folder, but **didn’t locate the game in the standard Steam installation path**, so installation compatibility is still unverified.

**Do you approve this scope, and where is your WaW installed—specifically the folder containing `CoDWaW.exe`?** I’m pausing before implementation as you requested.