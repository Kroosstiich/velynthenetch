<!-- Public copy of the Nexus description (1.2.0). Source: output/DESCRIPTION-NEXUS-1.2.0.txt -->

# Velyn the Netch

**A netch calf, far too small to survive on her own, drifting at your side and carrying what your back cannot.**  
Velyn is not a follower: she does not fight, cannot die, and does not take your follower slot. She carries your things, keeps you company, and learns to gather what she finds along the road.

---

## Where to find her  
At Revus Sarvani's camp on Solstheim (the silt strider merchant, southwest of the Sun Stone), resting on a rock by his fire. Ask Revus about her, then ask again: he will let her go with you for 500 gold. No quest to start, it works on a save in progress.

## What she does

- **Carries your things.** Press **L** near her (rebindable) to open her menu: her inventory, wait here, come along, climb onto my back, and how she is doing.
- **Grows with you.** She learns by travelling loaded, up to level 20. Her capacity grows with her.
- **Gathers on her own** from level 5: plants, ore, insects and loose items. She never steals, stays out of homes and shops, and uses a little energy for each find, so she never strips a region bare.
- **Sheds netch jelly** every few days, more as she grows.
- **Rides on your back** with [Piggyback](https://www.nexusmods.com/skyrimspecialedition/mods/186556), and since 1.2.0 follows your moves and turns with a slight, natural delay.

Everything is adjustable in the MCM.

---

## Requirements

- Skyrim Special Edition + Dragonborn DLC
- SKSE64, Address Library for SKSE Plugins, SkyUI, MCM Helper, powerofthree's Papyrus Extender

**Optional**

- **Piggyback**: carry Velyn on your back. **1.2.0 or later** for the natural movement delay (1.2.1 recommended). Without it, that option simply does not appear.
- **PapyrusUtil**: bind a key in the MCM to tell Velyn to always take, or never touch, the item you are looking at.
- **Dynamic String Distributor**: for the French translation.
- Netch HD, for better textures.

## Languages  
English by default. **French is included**: tick Français in the installer.  
**Translators: you are welcome to translate Velyn into your language, no need to ask.** Nothing in the plugin needs editing, the guide is on [GitHub](https://github.com/Kroosstiich/velynthenetch). Tell me when it is out and I will link it here.

---

## FAQ  
**Is it free?** Yes. All my mods are free, always.  
**Does she conflict with NFF, AFT or my followers?** No. She is not registered as a follower anywhere, you can travel with her and a follower at the same time.  
**Can she die, or give away my stealth?** No. She is invulnerable, enemies ignore her, and she becomes undetectable when you crouch.  
**She gathers nothing.** She starts at level 5, needs harvest energy (it comes back over time), never takes owned items and avoids homes, shops, inns, stables and farms.  
**Can I uninstall mid-playthrough?** Empty her inventory first. As with any scripted mod, a save made before installing is the safest way back.

**Console (debug):** `set VTN_DebugAcquire to 1` gets her for free, `set VTN_DebugAddXP to 500` gives her experience.

**Found a bug?** Tell me what you did just before it happened, your Velyn and Piggyback versions, and attach *Papyrus.0.log* and *User\VTN.0.log* (Documents\My Games\Skyrim Special Edition\Logs\Script). Logs need `bEnableLogging=1` and `bEnableTrace=1` in the [Papyrus] section of Skyrim.ini.

**Looking for help:** a volunteer sound designer for Velyn's small sounds, and French or English speaking testers. Message me here on Nexus.

---

## Permissions and credits  
You may modify Velyn or build on it if you credit me (Kroosstii) with a link to this page, keep it non-commercial, and make your mod a patch or add-on that requires Velyn, not a standalone copy. No re-uploads, except translation sites that link back here. License: CC BY-NC 4.0 (details on GitHub).

- **Concept, design and direction:** Kroosstii.
- **AI assistance:** made with the help of two AI assistants, **Claude (Anthropic)** and **OpenAI Codex**, which wrote the Papyrus scripts and plugin records to my specifications and helped debug them. The ideas, design decisions and in-game testing are mine. I say it openly so you know how what you install was made.
- SKSE64 team, meh321 (Address Library), SkyUI team, Exit-9B (MCM Helper), powerofthree (Papyrus Extender), exiledviper and meh321 (PapyrusUtil), Sasnikol (Dynamic String Distributor), chilloucik (Netch HD).
- Bethesda, for the netch and for Revus Sarvani.

If you like her, an endorsement helps a lot. Thank you!

---

# Velyn the Netch (Français)

**Un bébé netch, bien trop petit pour survivre seul, qui dérive à vos côtés et porte ce que votre dos ne peut plus porter.**  
Velyn n'est pas un compagnon au sens du jeu : elle ne se bat pas, ne peut pas mourir et n'occupe pas votre place de compagnon. Elle porte vos affaires, vous tient compagnie et apprend à récolter ce qu'elle trouve en chemin.

---

## Où la trouver  
Au campement de Revus Sarvani, sur Solstheim (le marchand au silt strider, au sud-ouest de la Pierre du Soleil), posée sur un rocher près de son feu. Interrogez Revus à son sujet, puis reparlez-lui : il vous la confiera pour 500 pièces d'or. Aucune quête à lancer, cela fonctionne sur une partie en cours.

## Ce qu'elle fait

- **Elle porte vos affaires.** Appuyez sur **L** près d'elle (touche modifiable) pour ouvrir son menu : son inventaire, attends ici, viens, monte sur mon dos, et comment elle va.
- **Elle grandit avec vous.** Elle apprend en voyageant chargée, jusqu'au niveau 20, et sa capacité augmente avec elle.
- **Elle récolte seule** à partir du niveau 5 : plantes, minerai, insectes et objets au sol. Elle ne vole jamais, n'entre ni dans les maisons ni dans les boutiques, et dépense un peu d'énergie à chaque trouvaille, pour ne jamais vider une région.
- **Elle produit de la gelée de netch** tous les quelques jours, davantage en grandissant.
- **Elle voyage sur votre dos** avec [Piggyback](https://www.nexusmods.com/skyrimspecialedition/mods/186556) et, depuis la 1.2.0, suit vos mouvements et vos rotations avec un léger décalage naturel.

Tout est réglable dans le MCM.

---

## Prérequis

- Skyrim Special Edition + DLC Dragonborn
- SKSE64, Address Library for SKSE Plugins, SkyUI, MCM Helper, powerofthree's Papyrus Extender

**Facultatifs**

- **Piggyback** : pour porter Velyn sur votre dos. **Version 1.2.0 ou plus récente** pour le délai de mouvement naturel (1.2.1 recommandée). Sans lui, cette option n'apparaît tout simplement pas.
- **PapyrusUtil** : assignez une touche dans le MCM pour dire à Velyn de toujours prendre, ou de ne jamais toucher, l'objet que vous visez.
- **Dynamic String Distributor** : pour la traduction française.
- Netch HD, pour de meilleures textures.

## Langues  
Anglais par défaut. **Le français est inclus** : cochez Français dans l'installateur.  
**Traducteurs : vous pouvez traduire Velyn dans votre langue, sans avoir à demander.** Rien n'est à modifier dans le plugin, le guide est sur [GitHub](https://github.com/Kroosstiich/velynthenetch). Prévenez-moi quand c'est en ligne et j'ajouterai le lien ici.

---

## FAQ  
**Est-ce gratuit ?** Oui. Tous mes mods sont gratuits, et le resteront.  
**Entre-t-elle en conflit avec NFF, AFT ou mes compagnons ?** Non. Elle n'est enregistrée comme compagnon nulle part, vous pouvez voyager avec elle et un compagnon en même temps.  
**Peut-elle mourir, ou trahir ma discrétion ?** Non. Elle est invulnérable, les ennemis l'ignorent et elle devient indétectable quand vous vous accroupissez.  
**Elle ne récolte rien.** Elle commence au niveau 5, a besoin d'énergie de récolte (qui revient avec le temps), ne prend jamais ce qui appartient à quelqu'un et évite les maisons, boutiques, auberges, étables et fermes.  
**Puis-je la désinstaller en cours de partie ?** Videz d'abord son inventaire. Comme pour tout mod à scripts, une sauvegarde faite avant l'installation reste le retour le plus sûr.

**Console (débogage) :** `set VTN_DebugAcquire to 1` vous la donne gratuitement, `set VTN_DebugAddXP to 500` lui donne de l'expérience.

**Un bug ?** Dites-moi ce que vous faisiez juste avant, vos versions de Velyn et de Piggyback, et joignez *Papyrus.0.log* et *User\VTN.0.log* (Documents\My Games\Skyrim Special Edition\Logs\Script). Les logs nécessitent `bEnableLogging=1` et `bEnableTrace=1` dans la section [Papyrus] de Skyrim.ini.

**Appel à l'aide :** je cherche un sound designer bénévole pour les petits bruits de Velyn, et des testeurs francophones ou anglophones. Écrivez-moi ici sur Nexus.

---

## Permissions et crédits  
Vous pouvez modifier Velyn ou construire dessus si vous me créditez (Kroosstii) avec un lien vers cette page, restez non commercial, et faites de votre mod un correctif ou une extension qui nécessite Velyn, pas une copie autonome. Pas de réupload, sauf sur les sites de traduction qui renvoient ici. Licence : CC BY-NC 4.0 (détails sur GitHub).

- **Concept, design et direction :** Kroosstii.
- **Assistance IA :** réalisé avec l'aide de deux IA, **Claude (Anthropic)** et **OpenAI Codex**, qui ont écrit les scripts Papyrus et les records du plugin selon mes indications et m'ont aidé à les déboguer. Les idées, les choix de conception et les tests en jeu sont les miens. Je le dis ouvertement pour que vous sachiez comment a été fait ce que vous installez.
- L'équipe de SKSE64, meh321 (Address Library), l'équipe de SkyUI, Exit-9B (MCM Helper), powerofthree (Papyrus Extender), exiledviper et meh321 (PapyrusUtil), Sasnikol (Dynamic String Distributor), chilloucik (Netch HD).
- Bethesda, pour le netch et pour Revus Sarvani.

Si elle vous plaît, un endorsement aide beaucoup. Merci !
