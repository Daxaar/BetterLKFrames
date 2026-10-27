# Changelog

## 0.2.4-dev — priority Apply blocker, awaiting owner acceptance

- Refs #11: Correct both native-placement clearing paths to respect the original client's movable/resizable precondition. Skip already-cleared placement; temporarily grant mobility only to clear stale placement when necessary, then restore it. No suppressed errors or permanent movement-flag changes.
- Add strict SetUserPlaced preconditions to the mock and fresh-login regressions for all settings tabs, later apply stages, profile/geometry persistence, reset, movement and combat deferral. Existing feature changes are carried forward without unrelated implementation.


## 0.2.3-dev — awaiting owner in-game acceptance

- Refs #4: Keep original shared account settings permanently selectable in the dropdown without copying over them.
- Refs #2, #4, #5: Extend the bright native button treatment to Frames and Profiles action buttons.
- Refs #5: Dismiss reset confirmation before applying layout work; Escape from unlock mode locks frames and reopens Frames settings on the following update.
- Refs #8: Add an unchecked, runtime-only Show test auras preview with isolated labelled player/target/focus samples and shared live rendering. Clean up on page/window exit, combat, disable and logout.
- Refs #9: Use the client's circular class-portrait atlas, preserving class coordinates and normal portrait restoration.
- Refs #10: Suppress resting Zzz/glow while enabled, retain the native player level and restore Blizzard resting display when disabled.
- Add popup/Escape lifecycle, default-profile preservation, preview isolation/cleanup and portrait/rest-badge regressions. In-game verification of this iteration remains pending.


## 0.2.2-dev — awaiting owner in-game acceptance

- Refs #1: Disable all aura feature checkboxes and the aura gap on fresh settings; preserve existing preferences.
- Refs #2: Keep navigation buttons bright with native hover/pushed art and selected-page highlighting.
- Refs #3: Prefer `/bf`, retain available compatibility aliases and report existing command conflicts.
- Refs #4: Add scoped profile selection/creation, automatic active-profile persistence and backwards-compatible account profile retention.
- Refs #5: Add confirmed active-layout reset to native positions, with locked state and preservation of other settings/profiles.
- Add read-only Actions validation and exact-commit development ZIP artifacts with commit/issue metadata and checksums.
- Lua 5.1 mocked regressions and packaging/privacy checks cover automated behavior; rendering, combat taint and actual client acceptance remain unverified.


## 0.2.1 — 2026-10-27

Rename active addon to BetterLKFrames: folder/TOC, globals, saved-variable names, widget identifiers, media paths, settings titles and `/blkf` / `/betterlkframes` commands. Move development to an independent addon workspace, independent of server tooling. Start fresh account/character settings; no legacy migration or command aliases. Preserve original archives/checksums. Pending dead-target duplicate text remains unfixed; no UI behaviour changes intended.

## 0.2.0 — 2026-10-26

Version numbering returns to pre-1.0 semantic versioning; historical 1.1.0 below was misnumbered and remains archived under that name.

- Fix added aura spirals being reset every quarter-second; update only on changed timing/identity or re-enable. Retain Blizzard's native low-duration fading. Exact reported video symptom not reproduced here; client confirmation pending.
- Align native cast timer vertically to the spell-name label and match its font, preserving cast data/colour behaviour.
- Blizzard dialog decoration for settings; dark button/checkbox/slider rims tied to window-theme brightness.
- Conservative dark rim copies for recognized Blizzard quest/spellbook/character/talent/map/bag/shared-window art. Preserve interiors, map tiles, icons and text; partial coverage and client validation required.
- Visible counted screen-centred movement grid, separate visibility/grid-snap toggles, centred snapping and adjustable spacing. Grid remains while unlocked.
- Power default 8 → 11 px without health-bar geometry changes. Keep custom heights other than old default 8.
- Independent optional per-character settings: copy, fresh addon defaults, native Blizzard preset, resume and return to account scope. Shared named profiles remain available.
- Small configurable target/focus root-aura-row downward offset, default 4 px, with combat deferral and no accumulating offsets.


## 1.1.0 — 2026-10-26

- Original antialiased rounded bar art with a vertical gradient and dark bevel. Refit large bars into the old name-strip area; optional class-coloured names above and native target name-background suppression.
- Dark individual action-button edges across main/extra/side/pet/stance bars, bag and menu buttons. Preserve icon colours and native proc/checked/cooldown feedback.
- Common dark player/target/focus buff/debuff edges; yellow player countdowns below icons; weapon enchant edges. Preserve native debuff/stealable and red/gold alert indicators.
- Movement snapping on release: matching edges/centres, adjacent edges, screen edges/centre and mirrored pairs. Optional fallback grid, live alignment guides and Shift bypass.
- Keep native cast-bar implementation unchanged from 0.1.0.
- Preserve positions/scales/profiles on upgrade. New gradient/class-name defaults adopted once. Independent appearance and snapping controls.
- Expanded Lua 5.1 mock regression coverage; actual client rendering and combat checks remain required.

## 0.1.0 — 2026-10-26

First client-test package: thick player/target/focus bars, class/reaction health colours, dark decoration, settings panel, profiles and frame movement, class names/portraits, text options, cast timers/party cast bars and native aura overlays. Original implementation targeting Interface 30300 and Lua 5.1. Automated mocked API validation; in-game validation pending.
