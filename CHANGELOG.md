# Changelog

All notable changes to Velyn the Netch are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
[Semantic Versioning](https://semver.org/).

## [1.1.1] - 2026-09-11

### Fixed

- **Solstheim water level regression.** The `DLC2SolstheimWorld` override (`000800:Dragonborn.esm`)
  retained its identity but omitted world settings during an earlier cleanup. The generated override
  therefore lacked the vanilla water defaults; omitted fields were not automatically inherited.
  - Forwarded Dragonborn's water and LOD water types, LOD water height (`256`), and default land/water
    heights (`-4590` / `256`).
  - Restored the associated location, climate, cloud model, map camera settings, bounds, music and
    distant terrain texture settings.
  - Restored `DLC2StriderDock01` (`00EEEE:Dragonborn.esm`) water height to the vanilla `FLT_MAX`
    sentinel (`3.4028235E+38`) and restored its six region links. Velyn's placed reference is unchanged.
- The missing water fields were confirmed in both the 1.0.0 and 1.1.0 release archives; this was not
  introduced by a newly added Skyrim runtime dependency.

### Validation and packaging

- Binary comparison against `Dragonborn.esm` confirms that the checked water, region and map fields
  match the master. Record identities and unrelated record payloads are unchanged from 1.1.0.
- The Nexus FOMOD updates only the ESP and installer version metadata. Compiled scripts, translations
  and other packaged files are unchanged. No new master or dependency was added.
- These are source/binary checks, not a claim of a completed in-game before/after comparison.

### Documentation

- Updated README release information and AI credits: original assistance by Claude (Anthropic),
  current maintenance assistance by Codex (OpenAI), with Kroosstiich retaining creative direction.
- Thanks to **TheDragonsDanced** for reporting the water issue.

## [1.1.0] - 2026-07-29

### Added

- **Netch jelly production.** Velyn now produces netch jelly on her own, scaled to her level:
  `1 + level / 5`, so one unit from level 1 to 4, up to five at level 20. The jelly goes straight into
  her inventory, so no new menu entry and no new `Message` record were needed.
  - Implemented as `VTN_ProgressionScript.UpdateJelly(Actor)`, driven from the existing player alias
    tick right after `UpdateEnergy()`.
  - Timing is based on **elapsed in-game time** (`Utility.GetCurrentGameTime()`), not on tick counts, so
    sleeping, waiting and the player's timescale are all handled for free, and the call frequency has no
    influence on the result.
  - The ingredient is resolved by EditorID (`PO3_SKSEFunctions.GetFormFromEditorID("DLC02NetchJelly")`),
    so **no hardcoded FormID and no additional master**. If Dragonborn is missing, production is skipped
    without arming the clock, so it resumes by itself if the problem is fixed.
  - Guard rails: the first pass only arms the clock (so updating the mod does not hand out a free
    batch); a negative elapsed time, meaning an older save was loaded, resynchronises without producing;
    and if Velyn is at capacity **the clock is deliberately not advanced**, so the jelly is pending
    rather than silently lost.
  - New records: `VTN_CfgJellyDays` (`GlobalFloat 000862`, default 3) and `VTN_MsgJelly`
    (`Message 000863`). Both script property fills were added to the quest YAML and verified in the
    rebuilt ESP.
  - New MCM slider on the Harvesting page, 0 to 14 days, where **0 disables production**. Note that 0 is
    a legitimate value here, so the script does not fall back to its default when the global reads 0.
    This is the opposite of `GetRideOffset`, where 0 is a valid offset and only a missing global
    triggers the fallback.
- **Translation files for eleven languages.** Only French is actually translated; the other ten are
  English fallbacks, which keeps raw `$VTN_...` keys from showing up in the MCM.

### Fixed

- **Nirnroots are now harvested.** Both ordinary and crimson nirnroots are `ACTI` records, not `FLOR` or
  `TREE` like every other harvestable plant, because vanilla implements them as scripted activators that
  swap themselves for an empty version. Two consequences: the flora scan never saw them, and
  `IsHarvested()` can never return true on them.
  - New `HarvestNearestNirnroot()` pass scans activators and identifies them with
    `plant as NirnrootACTIVATORScript`, the same cast-based approach already used for critters
    (`as Critter`) and ore veins (`as MineOreScript`), so **no hardcoded FormID**. Both variants share
    that script, so one cast covers them.
  - Success is proven by `IsDisabled()`, since the vanilla script calls `self.DisableNoWait()` after
    giving the ingredient to the triggering actor.
- **The whitelist no longer charges for actions that did nothing.** `HarvestWhitelistedItems()` called
  `AddItem` on any whitelisted reference and then notified and spent a harvest point without checking
  the result. On an in-place resource such as a nirnroot, `AddItem` does nothing at all, so Velyn burned
  a point per cycle on something that would never move. New `TakeWhitelistedRef()` routes by base type:
  `FLOR`/`TREE`/`ACTI`/`MSTT` are **harvested** (activate, then prove success with
  `IsHarvested() || IsDisabled()`), everything else is **picked up** (`AddItem`, then prove success with
  a rising `GetItemCount()`). A failed attempt no longer aborts the loop either.
- **`PickUpOfType()`** now applies the same rule: act first, charge only on proven success.
- **Velyn no longer sinks through the floor after dismounting.** `Piggyback.Detach` returns immediately
  while the exit transition still runs for about 0.9 seconds, during which the plugin keeps positioning
  her every frame. Clearing `SetDontMove` before the end left two systems moving the same actor.
  Both the dismount and the wait paths now wait for the transition to finish first.

### Changed

- Carry position sliders reordered to X, Y, Z in `config.json`. They were Y, Z, X, so the middle slider
  changed height when players expected it to change the side offset.

### Notes

- **Piggyback 1.1.0 or later is recommended** for anyone using the carry feature. It fixes the carried
  creature pushing the host sideways, the teleport-like behaviour on fast turns, and offsets not scaling
  to the host's build. Piggyback remains an optional dependency: Velyn works fully without it, minus
  carrying.

## [1.0.0] - 2026-07-26

Initial public release.

- Velyn, a netch calf bought from Revus Sarvani on Solstheim, who follows the player, can be told to
  wait, and carries items with a level-based weight capacity.
- Automatic harvesting of flora, ore veins, critters and loose items, with a harvest-energy economy that
  regenerates over in-game time.
- Progression system: experience from carrying and harvesting, twenty levels, capacity and energy
  scaling with level.
- Optional carrying on the player's back through Piggyback.
- MCM configuration covering features, harvesting, filters with whitelist and blacklist, and carry
  position.
- In-game guide book written by Revus Sarvani.
