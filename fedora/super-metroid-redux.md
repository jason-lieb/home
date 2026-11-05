# Super Metroid Redux on Fedora

Setup for playing **Super Metroid Redux v1.5** with widescreen and extra QoL
patches on Fedora using RetroArch and the `bsnes-hd beta` core.

Redux is a total overhaul, not a small patch. It already includes Project Base
movement, Control Freak controls, GBA-style physics, the Zero Mission/Fusion
map and HUD, faster transitions, recharge stations, and MSU-1 support. Do not
stack Project Base, Control Freak, or GBA Style on top.

## Recommended mods

| Mod | Purpose | Recommendation |
| --- | --- | --- |
| Super Metroid Redux v1.5 | Base QoL overhaul | Required |
| Redux Widescreen Patch v0.3.07 | True 16:9 | Strongly recommended |
| Save Stations Refill Everything | Refills energy and all ammo at save stations | Yes |
| Store Shinespark v1.01 | Lets you store a shinespark between rooms | Yes, if you use shinespark |
| No Boss Tiles on Map | Removes boss-room spoilers from the map | Optional |
| No Colored Doors on Map | Declutters the map | Optional |
| Redesigned Samus / Dual Suit | Cosmetic sprite improvements | Optional |
| Skip Ceres | Skips the intro | Only on replays |
| Vanilla Button Mapping | Restores original controls | Only if Redux's default controls feel wrong |

### Avoid or use with care

- **Spazer Plasma Mix** — known graphical issues; not worth it for a normal run.
- **Original Sand Physics / Original Underwater Walljump** — removes Redux's
  more permissive movement; anti-QoL.
- **Original Elevator Speed / Vanilla Beam Cooldowns / Classic Booster** —
  reverts Redux speed improvements.
- **Heavy Physics** — Redux is already heavier than vanilla; only use if you
  want an even more GBA-like feel.
- **Display the entire blue map** — reveals every secret room from the start;
  spoils exploration.

## 1. Install RetroArch

```bash
flatpak install flathub org.libretro.RetroArch
```

Open RetroArch and install the core:

**Online Updater → Core Downloader → `bsnes-hd beta`**

## 2. Get the Redux patches

```bash
git clone https://github.com/ShadowOne333/Super-Metroid-Redux
```

Relevant files and folders:

```
patches/Super-Metroid-Redux.bps
patches/optional/
patches/optional/Widescreen/
patches/optional/Widescreen/Bonus patches/
```

## 3. ROM requirements

Use your own legally dumped, headerless **Super Metroid (Japan, USA)** ROM.

- File size: 3,145,728 bytes
- CRC32: `D63ED5F8`
- SHA-1: `DA957F0D63D14CB441D215462904C4FA8519C613`

Redux v1.5 after the main patch has CRC32 `72FF6507`.

Work on a copy and keep the vanilla ROM untouched.

## 4. Apply patches in order

Use [RomPatcher.js](https://www.marcrobledo.com/RomPatcher.js/) or
[Flips](https://github.com/Alcaro/Flips/releases) to apply IPS/BPS patches.

1. **Main Redux patch**

   `patches/Super-Metroid-Redux.bps`

2. **Optional patches**

   Apply the ones you chose from `patches/optional/`.

3. **Widescreen patch**

   Apply the IPS version last:

   `patches/optional/Widescreen/Super Metroid Redux v1.5 - WPv0.3.07.ips`

   Use the IPS rather than the BPS when you have applied optional patches,
   because the BPS is tied to the exact unmodified Redux ROM checksum.

4. **Widescreen bonus patches**

   After widescreen, apply any you want from
   `patches/optional/Widescreen/Bonus patches/`:

   - `Store Shinespark v1.01.ips`
   - `Display the entire blue map.ips` (not recommended)

If the widescreen IPS fails after optional patches, test it on a clean Redux
v1.5 ROM first, then add optional patches one at a time.

## 5. Keep the BSO settings file

Copy the widescreen `.bso` next to the final ROM and rename it to match the
ROM's base name:

```
Super Metroid Redux WS.sfc
Super Metroid Redux WS.bso
```

The `.bso` enables widescreen, unsafe sprite rendering, 16:9, 200% CPU
overclock, and 1x HD Mode 7.

## 6. Launch

Place the files in a directory RetroArch can access, for example:

```bash
mkdir -p ~/Documents/snes
```

Open the ROM with the **bsnes-hd beta** core.

If widescreen does not activate, set these in
**Quick Menu → Core Options**:

- Widescreen Mode: `all`
- Widescreen Sprites: `unsafe`
- Aspect Ratio: `16:9`
- Overclock CPU: `200%`
- HD Mode 7 Scale: `1x`
- Pixel Aspect Correction: `off`

Start a fresh save. Do not reuse a vanilla Super Metroid SRAM.

## More than Redux

You cannot stack another total-conversion QoL hack on top of Redux. For a
different experience, use a separate hack:

- **Ancient Chozo** — new area plus QoL changes.
- **Ascent** — full-length high-quality hack.
- **Super Metroid Recomp** — native app with individually toggleable QoL
  mods; not compatible with Redux and currently beta.

## Troubleshooting

- **Black screen or crash on load** — confirm the ROM is headerless and has
  CRC32 `D63ED5F8` before patching.
- **Patch will not apply** — confirm you are using the correct base ROM and
  apply patches in the order above.
- **No widescreen** — confirm the `.bso` base name matches the ROM exactly and
  that the `bsnes-hd beta` core is selected, not `bsnes` or `snes9x`.
- **Wrong controls** — try the `Vanilla Button Mapping.ips` optional patch.
