# Guide de traduction — Velyn the Netch

Ce document sert à deux choses :
1. **Notes projet** (pour Kevin) : comment la localisation est structurée.
2. **Section "For Translators"** (prête à coller dans la description Nexus, en anglais) : ce qu'un
   traducteur d'une autre langue doit faire.

---

## Notes projet (FR)

Velyn est publié en **base anglaise**. Il y a **DEUX systèmes de localisation séparés**, à ne pas
confondre :

| Quoi | Où vit le texte | Comment on le traduit | Où s'installe la traduction |
|---|---|---|---|
| **Texte du jeu** (dialogues Revus, livre, menus de Velyn, 25 notifications) | Dans l'**ESP** (records) | **SSE-AT** ou **xTranslator** → export **DSD** | `SKSE\Plugins\DynamicStringDistributor\VelynTheNetch.esp\*.json` |
| **Menu MCM** (options, curseurs, aides) | Fichier `.txt` séparé | Copier/traduire le `.txt` | `Interface\Translations\VelynTheNetch_<LANGUE>.txt` |

- Le MCM **ne passe PAS par DSD** : c'est MCM Helper qui lit `Interface\Translations\VelynTheNetch_<LANGUE>.txt`
  (UTF-16 LE avec BOM). `_ENGLISH.txt` et `_FRENCH.txt` sont déjà fournis.
- La traduction **française** est faite par Kevin via SSE-AT (export DSD) + le `_FRENCH.txt` déjà présent.
- **Le FR est livré dans le FOMOD** (option de langue). Les **autres langues** sont des mods de traduction
  séparés que la communauté publie — d'où la section ci-dessous à mettre dans la description Nexus.

Le nom de plugin exact (pour le dossier DSD) : **`VelynTheNetch.esp`**.

---

## Section "For Translators" (à coller sur Nexus, EN)

> ### Translating Velyn the Netch
>
> Velyn ships in **English**. If you want to translate it to your language, there are **two separate
> files** to handle. You do **not** need to edit or redistribute the plugin (.esp) itself.
>
> **1. In-game text** (dialogue, the book, Velyn's menu, on-screen notifications)
> - This text lives in the plugin. Open `VelynTheNetch.esp` in **SSE Auto Translator (SSE-AT)** or
>   **xTranslator**, translate the strings, and **export as a DSD (Dynamic String Distributor) file**.
> - Install your file to:
>   `Data\SKSE\Plugins\DynamicStringDistributor\VelynTheNetch.esp\<yourname>.json`
> - Requires the user to have **Dynamic String Distributor** installed (already a soft requirement).
>
> **2. MCM menu text** (option labels, sliders, help text)
> - Copy `Data\Interface\Translations\VelynTheNetch_ENGLISH.txt` to
>   `Data\Interface\Translations\VelynTheNetch_<YOURLANGUAGE>.txt`
>   (e.g. `..._SPANISH.txt`, `..._GERMAN.txt` — the game picks it based on your language setting).
> - Translate the value after each tab. **Keep the `$VTN_...` keys and the tab characters unchanged.**
> - Save as **UTF-16 LE (with BOM)** — this is the format Skyrim requires for these files, otherwise the
>   text will not load.
>
> **Packaging** — zip both files with the folder structure above and upload as a translation mod. That's
> it: no ESP edits, no compatibility patch needed.
>
> Please do not use machine translation for the public release. Thanks for helping other players enjoy
> Velyn in their language!
