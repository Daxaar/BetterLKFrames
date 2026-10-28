# Feature coverage and backport boundaries

This is an iterative client-test release, not complete BetterBlizzFrames parity. “Implemented” means present in this package and covered where feasible by automated checks; all visual features still need in-game verification.

| Feature | Current development status / limits |
| --- | --- |
| Thicker health bars | Implemented: player/target/focus, configurable heights; secondary bars retain native height |
| Class health colours | Independent target switch; other units retain existing setting. Identified PCs only; NPC reaction/gradient fallback |
| Dark decoration | Implemented for named unit-frame/action-bar/minimap/cast-bar art; optional tooltip backdrop |
| Rounded gradient bars / names above | Implemented for large player/target/focus bars; independent toggles, flat fill optional |
| Individual button borders | Implemented for main/extra/side action bars, pet/stance buttons, bags and legacy menu buttons; icons stay untinted |
| Buff/debuff borders | Implemented for player/target/focus aura buttons and weapon enchant edges; native type/alert signals retained |
| Snap movement / guides | Implemented: edges, centres, mirrored pair, screen centre/edges, visible screen-centred counted grid, optional grid-centre snapping and Shift bypass; snapping on release |
| Standard window rims | Added: recognized native quest/spellbook/character/talent/map/bag rims and shared frame pieces; native Character/Spellbook atlas trim coordinates; partial decorative coverage, not every header/tab/window |
| Compact party presentation | Optional native secure party/pet restyling, portrait-free health/name/resource rectangles; pets and native debuff/hover-buff interactions retained; no raid restyling |
| Main player auras | Optional suppression of top-right spiral models, preserving timing data/text; thin dark outer trim respects aura-theme toggle and native dispel colours |
| Settings window decoration | Blizzard dialog border; button/checkbox/slider trim follows window dark-mode brightness |
| Frame scaling/moving | Implemented outside combat, saved positions, lock and restore; party group uses one solo-visible placement preview, applies on release and retains pet-aware chaining. One all-unit scale includes party frames |
| Class-coloured names | Implemented; optional |
| Class portraits | Implemented using client class atlas; optional |
| Flat bars, health/power labels | Implemented; health includes percentage, numeric values compact above 10k |
| Hide PvP icons / combat flash | Implemented for registered unit frames; does not hide every combat-related UI element |
| Cast timers and scale | Implemented for native player/pet/target/focus cast bars |
| Party cast bars | Implemented using locally visible legacy cast/channel data |
| Aura countdown / important border | Implemented on native player/target/focus aura buttons, with optional live visual-only samples |
| Aura expiry warning | Implemented; configurable 0–10 seconds, not pandemic semantics |
| Aura cooldown spirals | Adds missing spirals; preserves native spirals |
| Aura layout | Small configurable 0–12 px target/focus root-row offset; no custom filtering/sorting/resizing/reordering |
| Weapon-enchant / consolidated buff enhancement | Weapon enchant common edge only; native timers retained. Consolidated buff layouts not enhanced |
| Arena ID names, trinket tracking, DR tracking | Not implemented; Wrath-specific event tracking would need separate work |
| Combat icons, resting/name/level hiding, configurable element offsets | Not implemented; feasible extension with native-frame checks |
| Texture packs / fonts / shared-media integration | Not bundled; original procedural rounded gradient/flat art, legacy stock texture and stock font only |
| Profiles and settings UI | Implemented; account-wide settings with optional per-character overrides and fresh addon/Blizzard presets; named profile dropdown with account-wide and private per-character entries, persistent selection and safe legacy migration |
| Profile string import/export | Not implemented; SavedVariables file is the manual transfer mechanism |
| Modern absorb/heal prediction | No implementation; retail APIs do not exist here. Estimates would need additional combat-log/library logic and would have different accuracy |
| Retail Edit Mode / specialization / modern arena APIs | No direct backport; equivalent features would need new Wrath-specific implementations |
| Modern raid frames / nameplate overhaul | Outside this release's native unit-frame scope |

A promising next increment after client testing is configurable aura size/position/filtering and finer per-frame offsets. Actual client screenshots and combat results should guide that work rather than adding more unvalidated geometry.

0.2.0 corrects repeated custom cooldown restarts; a client check is still needed to confirm the reported extra flashing is resolved. Native low-duration aura fading is retained. Power height defaults to 11 px independently of the unchanged 22 px health height.
