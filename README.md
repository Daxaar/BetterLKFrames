# BetterLKFrames

Project: https://github.com/Daxaar/BetterLKFrames

Blizzard unit-frame styling for the original **World of Warcraft 3.3.5a client, build 12340** (Interface 30300).

Version **0.2.8-dev** is a development build awaiting client acceptance. It provides larger rounded health bars, class colours, dark decoration, movement/alignment tools and legacy-compatible cast/aura enhancements. It is an original implementation inspired by BetterBlizzFrames feature ideas, not an official port or a copy of that project's code/artwork. No server module is required.

## Features

- Rounded gradient player/target/focus health and power bars; independent heights, textures, scale and text options. Defaults: 22 px health and 11 px power.
- Class-coloured player health/names, NPC reaction colours, optional circular class portraits and names above bars. The optional Hide resting Zzz indicator checkbox keeps the player level visible in rest areas; it starts unchecked and is saved per configuration.
- Dark unit-frame, action-button, minimap and aura borders. Optional conservative rim shading on recognized Blizzard windows and a themed settings dialog.
- Movable frames outside combat, screen-centred counted grid, edge/centre/mirrored alignment, optional grid snapping and Shift bypass.
- Native cast timers, party cast bars, aura countdowns, important/expiry borders and a small target/focus aura gap.
- Shared account settings, named profiles and independent character settings with fresh addon or native-Blizzard presets.

See [FEATURES.md](FEATURES.md) for implemented and deferred features. This does not provide full BetterBlizzFrames parity or replace a full unit-frame addon.

## Install

Install the development ZIP from the Actions artifact so that the client has:

```text
Interface/AddOns/BetterLKFrames/BetterLKFrames.toc
```

Enable **BetterLKFrames** at character selection and log in. Open settings using **`/bf`**, or the embedded settings in Interface → AddOns. Compatibility aliases `/blkf`, `/betterlkframes` and `/gf` are retained when unclaimed by another addon; conflicts are reported at login. Addons registering commands later may still conflict.

For a source checkout, use the package instructions in [CONTRIBUTING.md](CONTRIBUTING.md); do not copy developer dependencies or research folders into your client.

Disable any previous version under a different addon name before enabling BetterLKFrames. The addon uses `BetterLKFramesDB` and `BetterLKFramesCharDB` saved variables; it does not import GromitFrames saved settings.

## Movement and settings

`/bf unlock` shows green drag handles and the optional grid; `/bf lock` hides them. Default grid spacing is 32 UI units, with major lines and signed counts every four squares. Explicit alignment takes precedence over optional grid-centre snapping. Hold **Shift when releasing** to bypass snapping. Press **Esc** while unlocked to lock frames and return to the Frames settings page. Position/scale changes wait until combat ends. Resolution/UI-scale changes can require repositioning or `/reload`.

A single **Party group** placement handle appears even while solo. Drag its labelled preview and release to move all party frames together; real hidden frames are never forced visible. A deliberate group move replaces any old individual party-member placements and retains Blizzard’s pet-aware spacing. The existing **All unit-frame scale** control affects every supported unit frame, including party, player, target, focus and pet; it is not a party-only slider. Group position and scale follow the active profile.

**Use compact party frames** on Appearance replaces portrait-style party presentation with rectangular name/health/resource overlays on the same native secure buttons. The normal four other party members remain under Blizzard visibility control; the existing player frame is not duplicated. Party pets retain their native owner anchors and visibility, with subordinate identity/health bars. Your own pet retains its separate position by the player frame and uses compact styling while in a party. Native debuffs remain beside members, buffs remain available on hover, and cast bars remain beside them. Native pet-aware vertical spacing is retained rather than reproducing the reference image pixel for pixel. Combat defers layout toggles and group transitions; raid frames and settings are never restyled by compact mode. Turning compact mode off restores the previous party presentation.

**Colour target health bar by class** is independent of the class-colour setting for other units. Existing profiles inherit their former target-colour preference on upgrade. Turning it off uses the existing gradient/reaction/default path; NPCs, pets and unknown classes are never assigned guessed class colours.

Appearance controls include decoration brightness, independent dark themes, class/name options and bar geometry. Casts / auras includes cast scale, expiry-warning seconds and a 0–12 px target/focus root-aura-row gap. On fresh settings, aura timers, added spirals, expiry warnings and dark aura borders are unchecked, and the gap is zero. Existing saved aura preferences remain unchanged. **Hide main player aura spirals** is checked by default and suppresses models only on top-right player buffs/debuffs; target/focus spirals retain their separate settings. Timing data and sibling duration/countdown text remain available. Uncheck it to restore previous model opacity. **Dark buff/debuff borders** adds thin dark outer trim to these main auras without covering native debuff-type colours or icon artwork. **Show test auras** temporarily displays labelled player/target/focus samples with live timer, spiral, border and gap controls. Target/focus samples use the native aura layout on separate scratch frames, respecting row ordering, scale and gap. Player samples mirror vacant native slots where their positions are available. Occupied real icons are not covered. If usable player slots are unavailable, only one clearly labelled player fallback appears in settings; that fallback demonstrates appearance, not native positioning. Numeric counters sit inside icons for real and test auras. Preview is unchecked on each session and ends when changing page, closing settings, entering combat, logging out or disabling the addon. No real aura is added or altered. If OmniCC is loaded, BetterLKFrames suppresses its own aura numbers and shows a warning below Show test auras. The Aura time remaining checkbox then represents your saved preference, which is preserved. OmniCC coverage depends on its settings and available cooldown widgets; we do not force added spirals on. Cast timers are unaffected.

The dropdown always includes **Default (account-wide)** so you can return to the original shared configuration without overwriting it. Under Profiles / help, use the dropdown to select account-wide profiles or this character's own profiles. Character entries have a character-name prefix and scope label; other characters' private entries are excluded. New profiles copy current settings and offer account or character scope. Successful creation clears the name field; failed creation keeps the input for correction. Existing named profiles remain account-wide without losing their settings. Selecting a named profile makes subsequent edits persistent in that profile, including frame movement; the selection survives reload/relog. Existing inactive names cannot be overwritten accidentally.

The Profiles page provides confirmed Reset Profile, Copy From and Delete a Profile actions. Reset affects the selected configuration without deleting other profiles; Default cannot be deleted. Deleting an active profile returns to Default. Previous unnamed character settings remain selectable. Legacy slash commands remain supported.

On Frames, **Reset frames** asks for confirmation, restores all movable unit-frame positions in the active configuration, and leaves frames locked. Other settings (including scale) and other profiles are preserved. It is unavailable in combat. Optional frames follow the reset when discovered later. Other frame addons may override positions; boss/arena/vehicle transitions still require client testing.

| Command | Action |
| --- | --- |
| `/bf` | Settings |
| `/bf on`, `/bf off` | Enable / restore native appearance in the active settings scope |
| `/bf unlock`, `/bf lock` | Move / lock frames |
| `/bf profile save NAME`, `/bf profile load NAME` | Create/select account-wide named profiles |
| `/bf character account`, `copy`, `defaults`, `blizzard`, `resume` | Select character/account settings scope |
| `/bf aura SPELLID` | Toggle an important-aura gold border |
| `/bf reset` | Reset the active scope; not required to install an update |

## Limits and known issues

- **Pending:** dead targets can show overlapping duplicate “Dead” text. This development build does not address that report.
- The current changes for #1, #4, #8, #10 and #13 await owner in-game acceptance. Earlier #2, #3, #5, #9 and #11 passed owner testing; no merge or stable release is implied. See [development testing](DEVELOPMENT.md) in the source repository for decisions, build details and a focused checklist.
- Automated Lua 5.1 mocked-API tests pass, but cannot verify actual client rendering, combat taint or every vehicle/focus/arena transition. This development build still needs an in-game loading/settings check.
- Window rim theming covers recognized narrow decorative texture regions only. It preserves parchment, map tiles, icons and text; some headers/tabs/custom frames remain unchanged or need visual refinement.
- The custom cooldown restart defect was corrected in 0.2.0: unchanged auras no longer call SetCooldown every quarter-second. Confirm the reported extra flashing is resolved in your client. Native low-duration buff fading is preserved.
- Cast bars use only information exposed by the legacy client. Aura expiry borders are not retail pandemic indicators; important-aura name fallback can cover multiple spell ranks.
- Other unit-frame/skin/cooldown addons can conflict. Custom replacement unit frames and consolidated-buff layouts are not comprehensively supported.

## Client verification

Initially disable other frame/skin addons and enable Lua errors with `/console scriptErrors 1`.

Check player/target/focus bars at full/partial/zero health, power types, dead targets, portraits and labels; casts/channels and party casts; long/permanent/expiring/refreshed auras and debuff clearance; dark-theme restoration and window readability; grid/snapping/Shift bypass; profile scope/reload persistence; normal click menus and combat layout deferral. Then check groups, pets, vehicles, arena/boss frames and other UI scales as available. Report exact Lua errors, client build, conflicting addons and screenshots when useful.

## Remove

Use `/bf off` outside combat, disable the addon, then close WoW before deleting only its addon folder. Optional settings removal is limited to BetterLKFrames.lua and its .bak in the relevant account/character SavedVariables folders. Preserve other addons' data.

[License](LICENSE) · [Changelog](CHANGELOG.md) · [Development](CONTRIBUTING.md) · [Provenance](PROVENANCE.md)
