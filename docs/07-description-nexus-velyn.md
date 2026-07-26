# Description Nexus, Velyn the Netch

Anglais d'abord, puis français. À relire et ajuster librement.
Les `[LIENS ICI]` et `[DISCORD ICI]` sont à remplacer quand ce sera en ligne.

---
---

# ENGLISH

## Velyn the Netch

A netch calf, far too small to survive on her own, drifting patiently at your side and carrying what
your back cannot.

Velyn travels with you, but she is **not a follower**. She does not fight, she cannot die, and she does
not take up your follower slot. She carries your things, she keeps you company, and as she grows she
learns to gather what she finds along the road.

---

## Where to find her

Velyn lives at **Revus Sarvani's camp on Solstheim**, the silt strider merchant, southwest of the Sun
Stone and northwest of Tel Mithryn. You will see her resting on a rock beside his fire.

Ask Revus about the young netch in his camp. He will tell you how he came to have her. Ask again and he
will offer to let her go with you, **for 500 gold**. He will also hand you his notes on keeping netches,
a short book worth reading.

You need the **Dragonborn** DLC. There is no quest to start and nothing to activate: just go and talk to
him.

---

## How she works

**Press `L`** (rebindable in the MCM) near Velyn to open her menu:

| Option | What it does |
|---|---|
| **See what she's carrying** | Opens her inventory, like a chest that follows you |
| **Wait here** | She settles in place and stays until you come back for her |
| **Come along** | She resumes following you |
| **Climb onto my back / Climb down** | She rides on your back (needs Piggyback, see below) |
| **How are you?** | Shows her level, her load, her experience and her harvest energy |

**Carrying.** Velyn starts with a capacity of 100 and gains 10 per level, up to level 20. Overfill her
and she will refuse politely, and hand the item back.

**Growing.** She gains experience by actually working: the further you walk with her loaded, the more she
learns. Standing still earns her nothing, and neither does fast travel. Everything is adjustable in the
MCM if the pace does not suit you.

**Gathering.** From **level 5**, Velyn gathers on her own: plants, ore veins, insects, and loose items on
the ground. She reaches out to what is nearby without wandering off, so there is no pathing to go wrong.

She has rules, and they matter:
- **She never steals.** Anything with an owner is left alone, always.
- **She stays out of homes, shops, inns, stables and farms** when picking up loose items, even yours.
- **Each resource costs one energy point**, which regenerates slowly over time, so she gathers steadily
  rather than stripping a region bare.
- A vein she has just worked goes on cooldown, so infinite quarries cannot be farmed.

Every one of these rules can be tuned or turned off in the MCM: what she picks up, how far she reaches,
which places are off limits, how fast she learns.

---

## Requirements

**Required**
- Skyrim Special Edition + **Dragonborn DLC**
- [SKSE64](https://skse.silverlock.org/)
- [Address Library for SKSE Plugins](https://www.nexusmods.com/skyrimspecialedition/mods/32444)
- [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604)
- [MCM Helper](https://www.nexusmods.com/skyrimspecialedition/mods/53000)
- [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854)

**Optional**

**Piggyback** [LIENS ICI] lets Velyn **ride on your back** instead of following you on the ground. It is
a separate plugin, install it only if that appeals to you. Without it, the **Climb onto my back** entry
simply does not appear in her menu and Velyn follows you normally. Nothing else changes.

**[PapyrusUtil](https://www.nexusmods.com/skyrimspecialedition/mods/13048)** lets you set **your own
gathering rules**. With it installed, you can bind a key in the MCM, look at any item, and tell Velyn to
**always** take that item or **never** touch it. This is useful for items added by other mods, which her
automatic rules do not know about. Without PapyrusUtil the feature stays inactive, and no key is bound
by default.

**[Dynamic String Distributor](https://www.nexusmods.com/skyrimspecialedition/mods/107676)**, for the
French translation.

**Compatibility.** Velyn is not a follower and is not registered with any follower framework, so she does
not conflict with NFF, AFT or similar. She adds nothing to the world except herself, and edits nothing
that other mods touch.

---

## FAQ

**Is this mod free?**
Yes. **All my mods are 100% free**, always. No paid version, no early access, no locked content,
nothing behind a donation. If you paid for this, you were scammed.

**Can I translate it into my language?**
**Yes, please do**, and you do not need to ask. Everything is translatable without touching the plugin,
see the translators guide at the end of this page. Tell me when it is out and I will link it here.

**I found a mistake in the English or the French text.**
Tell me, or fix it yourself, both are fine. English is not my first language and the French was written
alongside it, so mistakes are entirely possible. Corrections are genuinely welcome, not a bother.

**Can I add Velyn to a playthrough already in progress?**
Yes. There is nothing to start, no quest to trigger. Install, load your save, and go see Revus.

**Does she take my follower slot? Will she break NFF or AFT?**
No. Velyn is not a follower and is not registered with any follower framework. You can travel with her
and a normal follower at the same time.

**Can she die? Can enemies attack her?**
No. She is essential, invulnerable, and enemies ignore her. She does not fight and she will never pull
aggro onto you.

**Does she ruin my stealth?**
No. She does not affect your detection, and when you crouch she becomes undetectable entirely, so she
cannot give you away.

**She is not gathering anything.**
Check, in order: she gathers **from level 5**, she needs **harvest energy** (it regenerates over time),
she **never takes owned items**, and she avoids **homes, shops, inns, stables and farms** for loose
items. All of this is visible and adjustable in the MCM.

**Why does she not move at all in Revus's camp?**
That is intended. Before you buy her, she stays put where Revus keeps her.

**Do I have to install Piggyback?**
No. It only adds the option to carry her on your back. Without it, that menu entry does not appear and
everything else works exactly the same.

**Can I uninstall mid-playthrough?**
Take your belongings out of her inventory first, otherwise they are lost with her. Beyond that, the
usual advice for any script-based mod applies: removing it mid-save is never completely clean. A save
made before installing is always the safest route.

**Will she get more abilities later?**
Maybe. A talent system was designed and then set aside, I would rather build something with real
trade-offs than a plain list of bonuses. No promises, no date.

---

## Console commands (debug)

```
set VTN_DebugAcquire to 1     ; get her without paying
set VTN_DebugAddXP to 500     ; give her experience
```

To start over: `set VTN_HasVelyn to 0` then `set VTN_HasAskedAboutNetch to 0`.

---

## Reporting a bug

If something goes wrong, the more of this you can give me, the faster it gets fixed. A one-line report
without logs is very hard to act on.

```
**What happened:**


**What you expected instead:**


**How to reproduce it** (step by step, from a known point such as a save or a coc):
1.
2.
3.

**Does it happen every time?** (always / sometimes / once)

**Mod version:**
**Language installed:** (English / French)
**Piggyback installed?** (yes / no, and which version)
**PapyrusUtil installed?** (yes / no)
**Mod manager:** (MO2 / Vortex / manual)
**New save or existing save?**

**Papyrus log** (attach the file, or paste the lines mentioning VTN_):
Documents\My Games\Skyrim Special Edition\Logs\Script\Papyrus.0.log

**Velyn's own log** (attach if present):
Documents\My Games\Skyrim Special Edition\Logs\Script\User\VTN.0.log

**Screenshot or short video, if the problem is visual:**
```

To enable logs, put this in the `[Papyrus]` section of your `Skyrim.ini`:
```
bEnableLogging=1
bEnableTrace=1
```

---

## Looking for a sound designer

Velyn makes no sound yet, and she should.

I am looking for **a volunteer sound designer** to create the sounds of her small everyday actions:
picking a plant, working ore loose, catching an insect, settling down to wait, climbing onto your back,
and whatever small noises a content netch calf might make.

This is **unpaid**, but you will be **fully credited** on this page, and you keep credit for your work.
If that interests you, message me here on Nexus.

## Looking for testers

I am also looking for **French and English speaking testers** for my future mods. If you enjoy hunting
bugs and giving honest feedback, you are very welcome. A Discord will be set up for this: [DISCORD ICI]

---

## If you enjoy my mods

If you like what I make, please **endorse and vote**. It genuinely means a lot to me to see the
community enjoy what I build and actually use it.

---

## Permissions and credits

**You may modify this mod, extend it, or build on it**, on three conditions:

1. **Credit me** (Kroosstii) and **link back to this mod page**.
2. Your mod must be **a dependency of mine**, an add-on or a patch, not a standalone copy of Velyn.
3. Do not re-upload Velyn as-is elsewhere, **except on translation sites** such as *La Confrérie des
   Traducteurs*, as long as they **link back to this page**.

Translations into other languages are **welcome and encouraged**, no need to ask. See the guide below.

**Credits**

- **Concept, design and direction:** Kroosstii. **Velyn is my idea**, her character, how she behaves,
  what she does and does not do, and every design decision behind her.
- **AI assistance:** the mod was **coded with the help of an AI assistant (Claude)**, which wrote the
  Papyrus scripts and plugin records to my specifications, and helped track down bugs. **The ideas,
  the design and the direction are mine**, the AI implemented and debugged them. I state this openly
  because I think you deserve to know how what you install was made.
- **Bethesda Game Studios**, for Skyrim, for the netch, and for Revus Sarvani and his camp.

**The mods this one is built on.** Velyn would not exist without them, and their authors deserve the
credit:

| Mod | Author | What it does for Velyn |
|---|---|---|
| [SKSE64](https://skse.silverlock.org/) | the SKSE team | Everything below depends on it |
| [Address Library for SKSE Plugins](https://www.nexusmods.com/skyrimspecialedition/mods/32444) | meh321 | Lets SKSE plugins survive game updates |
| [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604) | SkyUI Team | The interface the MCM menu lives in |
| [MCM Helper](https://www.nexusmods.com/skyrimspecialedition/mods/53000) | Exit-9B | Velyn's whole settings menu |
| [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854) | powerofthree | The scanning and utility functions her gathering relies on |
| [PapyrusUtil](https://www.nexusmods.com/skyrimspecialedition/mods/13048) | exiledviper, meh321 | Stores your manual item filters (optional) |
| [Dynamic String Distributor](https://www.nexusmods.com/skyrimspecialedition/mods/107676) | Sasnikol | Applies translations without touching the plugin |
| **Piggyback** [LIENS ICI] | Kroosstii | Carrying her on your back (optional, made for this mod) |

**Recommended, not required**

- [Netch HD](https://www.nexusmods.com/skyrimspecialedition/mods/154585) by **chilloucik**, a high
  resolution netch retexture. Velyn uses the vanilla netch model, so this makes her look considerably
  better with nothing to configure. Install it and she picks it up automatically.

---

## For translators

Velyn ships in English. There are **two separate files** to translate, and you never need to edit or
redistribute the plugin itself.

**1. In-game text** (dialogue, book, menu, notifications)
Open `VelynTheNetch.esp` in **SSE Auto Translator** or **xTranslator**, translate, and export as a
**DSD file**. Install it to:
```
Data\SKSE\Plugins\DynamicStringDistributor\VelynTheNetch.esp\<yourname>.json
```

**2. MCM menu**
Copy `Data\Interface\Translations\VelynTheNetch_ENGLISH.txt` to
`VelynTheNetch_<YOURLANGUAGE>.txt`, translate the text after each tab, and **keep the `$VTN_...` keys
and the tabs unchanged**. Save as **UTF-16 LE with BOM**, this is the format Skyrim requires here, or
the text will not load.

Zip both with that folder structure and upload it as a translation. Please do not use machine
translation for a public release.

---
---

# FRANÇAIS

## Velyn le netch

Un bébé netch, bien trop petit pour survivre seul, qui dérive patiemment à vos côtés et porte ce que
votre dos ne peut plus.

Velyn voyage avec vous, mais **ce n'est pas un compagnon au sens du jeu**. Elle ne se bat pas, elle ne
peut pas mourir, et elle n'occupe pas votre emplacement de compagnon. Elle porte vos affaires, elle vous
tient compagnie, et à mesure qu'elle grandit, elle apprend à récolter ce qu'elle trouve en chemin.

---

## Où la trouver

Velyn vit au **campement de Revus Sarvani, sur Solstheim**, le marchand au silt strider, au sud-ouest de
la Pierre du Soleil et au nord-ouest de Tel Mithryn. Vous la verrez posée sur un rocher près de son feu.

Interrogez Revus sur le jeune netch de son camp. Il vous racontera comment il en est venu à l'avoir.
Reparlez-lui et il vous proposera de la laisser partir avec vous, **pour 500 pièces d'or**. Il vous
remettra aussi ses notes sur l'élevage des netchs, un petit livre qui vaut la lecture.

Le DLC **Dragonborn** est nécessaire. Il n'y a aucune quête à lancer ni rien à activer : allez simplement
lui parler.

---

## Comment elle fonctionne

**Appuyez sur `L`** (touche modifiable dans le MCM) près de Velyn pour ouvrir son menu :

| Option | Effet |
|---|---|
| **Voir son inventaire** | Ouvre son inventaire, comme un coffre qui vous suit |
| **Attends ici** | Elle se pose et reste sur place jusqu'à votre retour |
| **Viens, on y va** | Elle reprend son suivi |
| **Monte sur mon dos / Descends** | Elle voyage sur votre dos (nécessite Piggyback, voir plus bas) |
| **Comment vas-tu ?** | Affiche son niveau, sa charge, son expérience et son énergie de récolte |

**Le portage.** Velyn commence avec une capacité de 100 et gagne 10 par niveau, jusqu'au niveau 20.
Surchargez-la et elle refusera poliment, en vous rendant l'objet.

**Sa croissance.** Elle gagne de l'expérience en travaillant réellement : plus vous marchez avec elle
chargée, plus elle apprend. Rester immobile ne lui rapporte rien, le voyage rapide non plus. Tout est
réglable dans le MCM si le rythme ne vous convient pas.

**La récolte.** À partir du **niveau 5**, Velyn récolte d'elle-même : plantes, filons, insectes, et objets
qui traînent au sol. Elle attrape ce qui est à sa portée sans s'éloigner, il n'y a donc aucun
déplacement susceptible de mal tourner.

Elle a des règles, et elles comptent :
- **Elle ne vole jamais.** Tout ce qui appartient à quelqu'un est laissé tranquille, sans exception.
- **Elle s'abstient dans les maisons, boutiques, auberges, étables et fermes** pour le ramassage au sol,
  y compris chez vous.
- **Chaque ressource coûte un point d'énergie**, qui se régénère lentement, elle récolte donc
  régulièrement plutôt que de raser une région.
- Un filon qu'elle vient d'exploiter passe en délai d'attente, impossible de farmer une carrière infinie.

Chacune de ces règles peut être ajustée ou désactivée dans le MCM : ce qu'elle ramasse, sa portée, les
lieux interdits, sa vitesse d'apprentissage.

---

## 🇫🇷 Traduction française

**La traduction française est incluse dans l'installateur.** Il suffit de cocher **Français** au dernier
écran du FOMOD. Elle couvre les dialogues, le livre, les menus, les notifications et le menu MCM.

---

## Prérequis

**Obligatoires**
- Skyrim Special Edition + **DLC Dragonborn**
- [SKSE64](https://skse.silverlock.org/)
- [Address Library for SKSE Plugins](https://www.nexusmods.com/skyrimspecialedition/mods/32444)
- [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604)
- [MCM Helper](https://www.nexusmods.com/skyrimspecialedition/mods/53000)
- [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854)

**Optionnels**

**Piggyback** [LIENS ICI] permet à Velyn de voyager **sur votre dos** au lieu de vous suivre au sol.
C'est un plugin séparé, à installer seulement si l'idée vous plaît. Sans lui, l'entrée
**Monte sur mon dos** n'apparaît tout simplement pas dans son menu et Velyn vous suit normalement. Rien
d'autre ne change.

**[PapyrusUtil](https://www.nexusmods.com/skyrimspecialedition/mods/13048)** permet de définir **vos
propres règles de récolte**. Avec ce mod installé, vous pouvez assigner une touche dans le MCM, viser
n'importe quel objet, et dire à Velyn de le prendre **toujours** ou de ne **jamais** y toucher. C'est
utile pour les objets ajoutés par d'autres mods, que ses règles automatiques ne connaissent pas. Sans
PapyrusUtil, la fonction reste simplement inactive et aucune touche n'est assignée par défaut.

**[Dynamic String Distributor](https://www.nexusmods.com/skyrimspecialedition/mods/107676)**, pour la
traduction française.

**Compatibilité.** Velyn n'est pas un compagnon au sens du jeu et n'est enregistrée dans aucun
gestionnaire de compagnons, elle n'entre donc pas en conflit avec NFF, AFT ou équivalents. Elle n'ajoute
rien au monde à part elle-même, et ne modifie rien que d'autres mods touchent.

---

## FAQ

**Ce mod est-il gratuit ?**
Oui. **Tous mes mods sont 100 % gratuits**, et le resteront. Pas de version payante, pas d'accès
anticipé, pas de contenu réservé, rien derrière un don. Si vous avez payé pour l'avoir, on vous a
arnaqué.

**Puis-je le traduire dans ma langue ?**
**Oui, avec plaisir**, et sans avoir à demander. Tout est traduisible sans toucher au plugin, voir le
guide pour traducteurs à la fin de cette page (section anglaise). Prévenez-moi quand c'est en ligne et
je mettrai le lien ici.

**J'ai trouvé une faute dans le texte anglais ou français.**
Dites-le-moi, ou corrigez-la vous-même, les deux me vont. L'anglais n'est pas ma langue maternelle et le
français a été écrit en parallèle, des erreurs sont tout à fait possibles. Les corrections sont
sincèrement bienvenues, ça ne me dérange pas du tout.

**Puis-je ajouter Velyn à une partie déjà commencée ?**
Oui. Il n'y a rien à démarrer, aucune quête à déclencher. Installez, chargez votre partie, et allez voir
Revus.

**Prend-elle ma place de compagnon ? Va-t-elle casser NFF ou AFT ?**
Non. Velyn n'est pas un compagnon au sens du jeu et n'est enregistrée dans aucun gestionnaire. Vous
pouvez voyager avec elle et un compagnon classique en même temps.

**Peut-elle mourir ? Les ennemis peuvent-ils l'attaquer ?**
Non. Elle est essentielle, invulnérable, et les ennemis l'ignorent. Elle ne se bat pas et n'attirera
jamais l'agression sur vous.

**Est-ce qu'elle gâche ma discrétion ?**
Non. Elle n'influence pas votre détection, et dès que vous vous accroupissez elle devient totalement
indétectable, elle ne peut donc pas vous trahir.

**Elle ne récolte rien.**
Vérifiez, dans l'ordre : elle récolte **à partir du niveau 5**, il lui faut de l'**énergie de récolte**
(qui se régénère avec le temps), elle **ne prend jamais ce qui appartient à quelqu'un**, et elle évite
les **maisons, boutiques, auberges, étables et fermes** pour les objets au sol. Tout cela est visible et
réglable dans le MCM.

**Pourquoi ne bouge-t-elle pas du tout dans le camp de Revus ?**
C'est voulu. Avant que vous ne l'achetiez, elle reste sagement là où Revus la garde.

**Suis-je obligé d'installer Piggyback ?**
Non. Il ajoute seulement la possibilité de la porter sur votre dos. Sans lui, cette entrée de menu
n'apparaît pas et tout le reste fonctionne exactement pareil.

**Puis-je désinstaller en cours de partie ?**
Récupérez d'abord vos affaires dans son inventaire, sinon elles partent avec elle. Au-delà de ça, le
conseil habituel pour tout mod à scripts s'applique : retirer un mod en cours de sauvegarde n'est jamais
totalement propre. Une sauvegarde faite avant l'installation reste la solution la plus sûre.

**Aura-t-elle d'autres capacités plus tard ?**
Peut-être. Un système de talents a été conçu puis mis de côté, je préfère construire quelque chose avec
de vrais compromis plutôt qu'une simple liste de bonus. Aucune promesse, aucune date.

---

## Commandes console (debug)

```
set VTN_DebugAcquire to 1     ; l'obtenir sans payer
set VTN_DebugAddXP to 500     ; lui donner de l'experience
```

Pour tout recommencer : `set VTN_HasVelyn to 0` puis `set VTN_HasAskedAboutNetch to 0`.

---

## Signaler un bug

Si quelque chose ne va pas, plus vous m'en donnez, plus vite c'est corrigé. Un rapport d'une ligne sans
log est très difficile à traiter.

```
**Ce qui s'est passé :**


**Ce que vous attendiez à la place :**


**Comment le reproduire** (étape par étape, depuis un point connu : une sauvegarde, un coc) :
1.
2.
3.

**Est-ce systématique ?** (toujours / parfois / une seule fois)

**Version du mod :**
**Langue installée :** (English / Français)
**Piggyback installé ?** (oui / non, et quelle version)
**PapyrusUtil installé ?** (oui / non)
**Gestionnaire de mods :** (MO2 / Vortex / manuel)
**Nouvelle partie ou sauvegarde existante ?**

**Log Papyrus** (joignez le fichier, ou collez les lignes mentionnant VTN_) :
Documents\My Games\Skyrim Special Edition\Logs\Script\Papyrus.0.log

**Log propre à Velyn** (joignez-le s'il existe) :
Documents\My Games\Skyrim Special Edition\Logs\Script\User\VTN.0.log

**Capture d'écran ou courte vidéo, si le problème est visuel :**
```

Pour activer les logs, ajoutez ceci dans la section `[Papyrus]` de votre `Skyrim.ini` :
```
bEnableLogging=1
bEnableTrace=1
```

---

## Je cherche un sound designer

Velyn ne fait encore aucun bruit, et elle le mériterait.

Je cherche **un sound designer bénévole** pour créer les sons de ses petites actions du quotidien :
cueillir une plante, extraire du minerai, attraper un insecte, se poser pour attendre, grimper sur votre
dos, et tous les petits bruits que peut faire un bébé netch content.

C'est **bénévole**, mais vous serez **intégralement crédité** sur cette page, et vous gardez le crédit de
votre travail. Si ça vous intéresse, écrivez-moi ici sur Nexus.

## Je cherche des testeurs

Je cherche aussi des **testeurs francophones et anglophones** pour mes futurs mods. Si vous aimez
traquer les bugs et donner un retour honnête, vous êtes les bienvenus. Un Discord sera mis en place pour
ça : [DISCORD ICI]

---

## Si vous aimez mes mods

Si ce que je fais vous plaît, pensez à **endorser et à voter**. Ça compte énormément pour moi de voir la
communauté apprécier ce que je construis et s'en servir vraiment.

---

## Permissions et crédits

**Vous pouvez modifier ce mod, l'étendre ou construire dessus**, à trois conditions :

1. **Me créditer** (Kroosstii) et **mettre un lien vers cette page**.
2. Votre mod doit avoir **une dépendance vers le mien**, un add-on ou un patch, pas une copie autonome
   de Velyn.
3. Ne pas réuploader Velyn telle quelle ailleurs, **sauf sur les sites de traduction** comme *La
   Confrérie des Traducteurs*, tant qu'ils **mettent un lien vers cette page**.

Les traductions dans d'autres langues sont **les bienvenues et encouragées**, sans avoir à demander.
Voir le guide plus haut (section anglaise).

**Crédits**

- **Concept, design et direction :** Kroosstii. **Velyn est mon idée**, son caractère, son comportement,
  ce qu'elle fait et ne fait pas, et chaque décision de design derrière elle.
- **Assistance IA :** le mod a été **codé avec l'aide d'une IA (Claude)**, qui a écrit les scripts
  Papyrus et les records du plugin selon mes indications, et m'a aidé à traquer les bugs. **Les idées,
  le design et la direction sont de moi**, l'IA les a implémentés et débogués. Je le dis ouvertement
  parce que je pense que vous méritez de savoir comment ce que vous installez a été fait.
- **Bethesda Game Studios**, pour Skyrim, pour le netch, et pour Revus Sarvani et son campement.

**Les mods sur lesquels celui-ci repose.** Velyn n'existerait pas sans eux, et leurs auteurs méritent
d'être cités :

| Mod | Auteur | Ce qu'il apporte à Velyn |
|---|---|---|
| [SKSE64](https://skse.silverlock.org/) | l'équipe SKSE | Tout ce qui suit en dépend |
| [Address Library for SKSE Plugins](https://www.nexusmods.com/skyrimspecialedition/mods/32444) | meh321 | Permet aux plugins SKSE de survivre aux mises à jour du jeu |
| [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604) | SkyUI Team | L'interface dans laquelle vit le menu MCM |
| [MCM Helper](https://www.nexusmods.com/skyrimspecialedition/mods/53000) | Exit-9B | Tout le menu de réglages de Velyn |
| [powerofthree's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854) | powerofthree | Les fonctions de scan sur lesquelles repose sa récolte |
| [PapyrusUtil](https://www.nexusmods.com/skyrimspecialedition/mods/13048) | exiledviper, meh321 | Stocke vos filtres d'objets manuels (optionnel) |
| [Dynamic String Distributor](https://www.nexusmods.com/skyrimspecialedition/mods/107676) | Sasnikol | Applique les traductions sans toucher au plugin |
| **Piggyback** [LIENS ICI] | Kroosstii | Le portage sur le dos (optionnel, créé pour ce mod) |

**Recommandé, pas obligatoire**

- [Netch HD](https://www.nexusmods.com/skyrimspecialedition/mods/154585) par **chilloucik**, une
  retexture haute résolution des netchs. Velyn utilise le modèle vanilla du netch, ce mod la rend donc
  nettement plus belle sans rien avoir à configurer. Installez-le et elle en profite automatiquement.
