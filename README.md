# BetterLKFrames

Project: https://github.com/Daxaar/BetterLKFrames

Blizzard unit-frame styling for the original **World of Warcraft 3.3.5a client, build 12340** (Interface 30300).

Version **0.2.1** is an early client-test release. It provides larger rounded health bars, class colours, dark decoration, movement/alignment tools and legacy-compatible cast/aura enhancements. It is an original implementation inspired by BetterBlizzFrames feature ideas, not an official port or a copy of that project's code/artwork. No server module is required.

## Features

- Rounded gradient player/target/focus health and power bars; independent heights, textures, scale and text options. Defaults: 22 px health and 11 px power.
- Class-coloured player health/names, NPC reaction colours, optional class portraits and names above bars.
- Dark unit-frame, action-button, minimap and aura borders. Optional conservative rim shading on recognized Blizzard windows and a themed settings dialog.
- Movable frames outside combat, screen-centred counted grid, edge/centre/mirrored alignment, optional grid snapping and Shift bypass.
- Native cast timers, party cast bars, aura countdowns, important/expiry borders and a small target/focus aura gap.
- Shared account settings, named profiles and independent character settings with fresh addon or native-Blizzard presets.

See [FEATURES.md](FEATURES.md) for implemented and deferred features. This does not provide full BetterBlizzFrames parity or replace a full unit-frame addon.

## Install

Install a packaged release so that the client has:

```text
Interface/AddOns/BetterLKFrames/BetterLKFrames.toc
```

Enable **BetterLKFrames** at character selection and log in. Open settings using **`/blkf`** or **`/betterlkframes`**, or the launcher in Interface → AddOns.

For a source checkout, use the package instructions in [CONTRIBUTING.md](CONTRIBUTING.md); do not copy developer dependencies or research folders into your client.

Disable any previous version under a different addon name before enabling BetterLKFrames. This is a clean rename with fresh `BetterLKFramesDB` and `BetterLKFramesCharDB` saved variables; no legacy settings importer or old command aliases are included.

## Movement and settings

`/blkf unlock` shows green drag handles and the optional grid; `/blkf lock` hides them. Default grid spacing is 32 UI units, with major lines and signed counts every four squares. Explicit alignment takes precedence over optional grid-centre snapping. Hold **Shift when releasing** to bypass snapping. Position/scale changes wait until combat ends. Resolution/UI-scale changes can require repositioning or `/reload`.

Appearance controls include decoration brightness, independent dark themes, class/name options and bar geometry. Casts / auras includes cast scale, expiry-warning seconds and a 0–12 px target/focus root-aura-row gap. Existing native cooldown spirals remain unchanged; the spiral option controls only added spirals.

Under Profiles / help, choose shared account settings, copy settings to this character, start fresh addon defaults, start with native Blizzard appearance, or resume that character's saved settings. Replacing a local character preset affects only that character; named profiles remain a shared library. Account reset clears named profiles, while character reset preserves them.

| Command | Action |
| --- | --- |
| `/blkf` | Settings |
| `/blkf on`, `/blkf off` | Enable / restore native appearance in the active settings scope |
| `/blkf unlock`, `/blkf lock` | Move / lock frames |
| `/blkf profile save NAME`, `/blkf profile load NAME` | Shared named settings/layout snapshots |
| `/blkf character account`, `copy`, `defaults`, `blizzard`, `resume` | Select character/account settings scope |
| `/blkf aura SPELLID` | Toggle an important-aura gold border |
| `/blkf reset` | Reset the active scope; not required to install an update |

## Limits and known issues

- **Pending:** dead targets can show overlapping duplicate “Dead” text. Version 0.2.1 only renames/relocates the addon; it does not fix that report.
- Automated Lua 5.1 mocked-API tests pass, but cannot verify actual client rendering, combat taint or every vehicle/focus/arena transition. The renamed build still needs an in-game loading/settings check.
- Window rim theming covers recognized narrow decorative texture regions only. It preserves parchment, map tiles, icons and text; some headers/tabs/custom frames remain unchanged or need visual refinement.
- The custom cooldown restart defect was corrected in 0.2.0: unchanged auras no longer call SetCooldown every quarter-second. Confirm the reported extra flashing is resolved in your client. Native low-duration buff fading is preserved.
- Cast bars use only information exposed by the legacy client. Aura expiry borders are not retail pandemic indicators; important-aura name fallback can cover multiple spell ranks.
- Other unit-frame/skin/cooldown addons can conflict. Custom replacement unit frames and consolidated-buff layouts are not comprehensively supported.

## Client verification

Initially disable other frame/skin addons and enable Lua errors with `/console scriptErrors 1`.

Check player/target/focus bars at full/partial/zero health, power types, dead targets, portraits and labels; casts/channels and party casts; long/permanent/expiring/refreshed auras and debuff clearance; dark-theme restoration and window readability; grid/snapping/Shift bypass; profile scope/reload persistence; normal click menus and combat layout deferral. Then check groups, pets, vehicles, arena/boss frames and other UI scales as available. Report exact Lua errors, client build, conflicting addons and screenshots when useful.

## Remove

Use `/blkf off` outside combat, disable the addon, then close WoW before deleting only its addon folder. Optional settings removal is limited to BetterLKFrames.lua and its .bak in the relevant account/character SavedVariables folders. Preserve other addons' data.

[License](LICENSE) · [Changelog](CHANGELOG.md) · [Development](CONTRIBUTING.md) · [Provenance](PROVENANCE.md)
