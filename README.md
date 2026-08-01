# Velyn the Netch

Source code for **Velyn the Netch**, a Skyrim Special Edition mod adding a netch calf who travels with
you and carries your things.

- **Nexus page:** [Velyn The Netch](https://www.nexusmods.com/skyrimspecialedition/mods/186573)
- **Full description, requirements and permissions:** [docs/07-description-nexus-velyn.md](docs/07-description-nexus-velyn.md)

---

## What is in this repository

| Path | Contents |
|---|---|
| `Spriggit/` | The plugin, as human-readable YAML ([Spriggit](https://github.com/Mutagen-Modding/Spriggit) format). This is the real source of the `.esp`. |
| `Scripts/Source/` | Papyrus source (`.psc`) |
| `MCM/` | MCM Helper menu definition |
| `Interface/Translations/` | MCM text, English and French |
| `translations/fr/` | French in-game translation, DSD format |
| `docs/` | Translation guide and the full mod description |
| `build.ps1` | Builds the `.esp` from YAML, compiles the scripts, deploys to a test mod folder |
| `backup.ps1` | Local snapshot of sources before risky changes |

The compiled `.esp` is **not** committed: it is generated from `Spriggit/`.

---

## Building

**Requirements**
- [Spriggit CLI](https://github.com/Mutagen-Modding/Spriggit) and a .NET SDK
- Skyrim's Papyrus compiler (ships with the Creation Kit)
- Import paths for: vanilla scripts, powerofthree's Papyrus Extender, MCM Helper SDK, PapyrusUtil,
  and Piggyback's `Piggyback.psc`

Point the build at your own install with environment variables, no need to edit any file:

```powershell
$env:SKYRIM_SE_PATH    = "D:\Steam\steamapps\common\Skyrim Special Edition"
$env:MO2_INSTANCE_PATH = "C:\Users\<you>\AppData\Local\ModOrganizer\<instance>"
.\build.ps1
```

`build.ps1` does three things: turns `Spriggit/` YAML into `VelynTheNetch.esp`, compiles every `.psc`,
and copies the result into a Mod Organizer 2 mod folder for testing.

---

## Dependencies

**Required at runtime:** SKSE64, Address Library, SkyUI, MCM Helper, powerofthree's Papyrus Extender,
and the Dragonborn DLC.

**Optional:** [Piggyback](https://www.nexusmods.com/skyrimspecialedition/mods/186556) (carrying Velyn on your back), PapyrusUtil
(manual item filters), Dynamic String Distributor (translations).

Piggyback is treated as a genuinely optional dependency: `Piggyback.IsInstalled()` returns `false` when
the plugin is absent, and the corresponding menu entry is hidden rather than offered and broken.

---

## Notes for anyone reading the source

A few traps that cost real time during development, worth knowing if you mod Skyrim yourself:


- **Every `Property` declared in a `.psc` needs a matching fill in the quest YAML**, otherwise it is
  `None` at runtime and silently aborts the function that touches it. No compile error.
- **An actor's effective speed is proportional to its scale.** Velyn is at `Height 0.15`, so at the
  default `SpeedMult` she moves at roughly 9 units per second, which is invisible to the eye and looks
  exactly like being stuck.
- **A persistent reference remembers its position across sessions.** Once it has moved, changing its
  placement in the plugin has no effect; it has to be repositioned by script.
- **MCM Helper's `config.json` must not have a UTF-8 BOM**, its parser fails on it with a misleading
  "check JSON syntax" error. PowerShell's `Out-File -Encoding UTF8` adds one.
- **Never leave a stale compiled `.pex` of a component you moved elsewhere**, it wins by load order and
  hides the real one, producing "native function not found" errors that look like a DLL problem.

---

## Translations

Velyn ships in English and is fully translatable **without editing the plugin**. See
[docs/05-guide-traduction.md](docs/05-guide-traduction.md) for the two files involved and where they go.

Translations are welcome, no permission needed.

---

## Permissions

Velyn the Netch is licensed under **CC BY-NC 4.0** — see [LICENSE](LICENSE).

You may modify this mod, extend it, or build on it, provided you **credit Kroosstiich**, **link back to
the Nexus page**, make your mod **a dependency of Velyn** rather than a standalone copy of it, and keep
it **non-commercial** — Velyn and anything derived from it may not be sold, put behind a paywall, or
bundled into anything paid.

Re-uploading Velyn as-is elsewhere is not allowed, **except on translation sites** such as *La Confrérie
des Traducteurs*, as long as they link back.

Full terms: see [LICENSE](LICENSE), and the permissions section of
[docs/07-description-nexus-velyn.md](docs/07-description-nexus-velyn.md).

---

## Credits

- **Concept, design and direction:** Kroosstiich. Velyn is his idea: her character, her behaviour, and
  every design decision behind her.
- **AI assistance:** the mod was coded with the help of an AI assistant (Claude), which wrote the
  Papyrus scripts and plugin records to specification and helped track down bugs. The ideas, design and
  direction are Kroosstiich's.
- Bethesda, for the netch and for Revus Sarvani.
