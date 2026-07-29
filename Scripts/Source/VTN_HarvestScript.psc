Scriptname VTN_HarvestScript extends Quest

; ==================================================================================================
; M3 - Bloc 2 : recolte automatique a distance (debloquee au niveau VTN_HarvestUnlockLevel).
; ==================================================================================================
; Mode "distance" : Velyn ne se DEPLACE PAS. On scanne autour d'elle et on active la ressource a
; distance. Choix de conception acte le 2026-07-19 : aucun pathing, donc aucune dependance au navmesh,
; donc beaucoup plus fiable. (Un mode "immersion" ou elle se deplace reellement reste une option future.)
;
; ---- Le point technique important : comment vider un filon "comme si le joueur l'avait mine" -------
; Verifie dans le script vanilla MineOreScript.psc : sa fonction giveOre() est au niveau global (pas
; enfermee dans un State), donc APPELABLE depuis l'exterieur. Elle fait deja tout le travail :
;     self.damageObject(50) / getLinkedRef().activate() / setDestroyed(true) / DepletedMessage.Show()
; -> quantite correcte, gemmes aleatoires incluses, son, visuel "vide", etat persistant.
; On ne reimplemente donc RIEN : on laisse le jeu faire, ce qui est bien plus robuste qu'un DLL.
;
; Seule subtilite : giveOre() donne le minerai AU JOUEUR (code en dur, ligne 211 du script vanilla).
; D'ou le drapeau _redirecting ci-dessous : pendant la recolte, VTN_PlayerAliasScript.OnItemAdded
; transfere immediatement a Velyn ce que le joueur vient de recevoir. Avantage decisif : cela gere
; automatiquement les GEMMES ALEATOIRES issues des listes de butin, qu'on ne pourrait pas predire.

Quest Property VTN_MainQuest Auto
GlobalVariable Property VTN_HasVelyn Auto
GlobalVariable Property VTN_IsWaiting Auto

; --- Reglages MCM (ecrits directement par MCM Helper, voir MCM\Config\VelynTheNetch\config.json) ---
GlobalVariable Property VTN_CfgHarvestEnabled Auto
GlobalVariable Property VTN_CfgHarvestRadius Auto
GlobalVariable Property VTN_CfgNotifyHarvest Auto
GlobalVariable Property VTN_CfgPickupEnabled Auto

; --- Bloc 3 (extension 2026-07-23) : filtres de recolte configurables, idee de Kevin ---------------
GlobalVariable Property VTN_CfgMinItemValue Auto
GlobalVariable Property VTN_CfgOreCooldownMinutes Auto
GlobalVariable Property VTN_CfgXPPerHarvest Auto
; Portee par categorie : 0 = utiliser la portee generale (VTN_CfgHarvestRadius / VTN_HarvestRadius).
GlobalVariable Property VTN_CfgRadiusFlora Auto
GlobalVariable Property VTN_CfgRadiusOre Auto
GlobalVariable Property VTN_CfgRadiusCritter Auto
GlobalVariable Property VTN_CfgRadiusItems Auto
; Ramassage au sol : trois interrupteurs distincts au lieu d'un seul VTN_CfgPickupEnabled global,
; pour pouvoir par ex. garder l'or/les ingredients mais couper les objets divers.
GlobalVariable Property VTN_CfgPickupGoldEnabled Auto
GlobalVariable Property VTN_CfgPickupMiscEnabled Auto
GlobalVariable Property VTN_CfgPickupIngredientsEnabled Auto
; Lieux "habites" : une case a cocher par type au lieu d'une liste figee dans le code.
GlobalVariable Property VTN_CfgBlockDwelling Auto
GlobalVariable Property VTN_CfgBlockPlayerHouse Auto
GlobalVariable Property VTN_CfgBlockStore Auto
GlobalVariable Property VTN_CfgBlockInn Auto
GlobalVariable Property VTN_CfgBlockStable Auto
GlobalVariable Property VTN_CfgBlockFarm Auto

; --- Filtres manuels par objet (extension 2026-07-23bis, idee de Kevin) : liste blanche/noire ------
; Stockage via PapyrusUtil (JsonUtil), PAS une dependance de tout le mod : reste inerte tant que le
; joueur n'a pas lie VTN_CfgFilterKey a une touche au MCM (voir VTN_MainQuestScript). A documenter dans
; le FOMOD comme necessitant PapyrusUtil pour cette fonctionnalite precise.
Message Property VTN_FilterMenu Auto
string Property VTN_FilterStoreName = "VelynTheNetch" Auto

; Rayon de scan. Volontairement modeste : Velyn "attrape" ce qui est a portee, elle ne rafle pas
; la moitie de la zone. Reglable au MCM.
float Property VTN_HarvestRadius = 400.0 Auto

; Types de formulaire (valeurs de l'enum FormType du moteur, verifiees dans les en-tetes CommonLibSSE) :
; 39 = FLOR (flore recoltable), 24 = ACTI (activateurs : les filons en font partie).
int Property VTN_FormTypeFlora = 39 Auto
int Property VTN_FormTypeActivator = 24 Auto
; 38 = TREE. Certaines plantes recoltables (buissons a baies, genevriers...) sont des TREE et non des
; FLOR : sans ce type, Velyn les ignorait completement.
int Property VTN_FormTypeTree = 38 Auto
; 36 = MSTT (statiques mobiles). Les critters (papillons, lucioles, abeilles) apparaissent selon les cas
; en ACTI ou en MSTT : on balaie les deux et on identifie par un cast vers Critter.
int Property VTN_FormTypeMovableStatic = 36 Auto
; 40 = FURN. Certains filons sont montes en mobilier (le joueur "s'y installe" pour miner).
int Property VTN_FormTypeFurniture = 40 Auto

; Mots-cles de lieu "habite". Resolus par EditorID via po3 -> aucun FormID code en dur, et degradation
; propre si un mot-cle n'existe pas (GetFormFromEditorID renvoie None, on l'ignore simplement).
; _inhabitedToggles est parallele a _inhabitedKeywords (meme index) : la globale MCM correspondante,
; pour que chaque type de lieu soit une case a cocher independante (Bloc 3, 2026-07-23).
Keyword[] _inhabitedKeywords
GlobalVariable[] _inhabitedToggles
bool _keywordsResolved = false

float Property VTN_XPPerHarvest = 15.0 Auto

; Notification discrete de ce qu'elle recolte (desactivable au MCM au Bloc 3).
bool Property VTN_NotifyHarvest = true Auto

bool _redirecting = false
; Empeche de repeter l'avertissement "elle est pleine" a chaque scan (~toutes les 3 s) : on ne le dit
; qu'une fois par episode, et on le rearme quand elle a de nouveau de la place.
bool _warnedFull = false

; Delai avant qu'un MEME filon puisse etre re-exploite, en JOURS de jeu. Vise surtout les ressources
; inepuisables (carriere de pierre, certains filons qui se regenerent aussitot) : sans ce cooldown,
; Velyn re-minait le meme filon toutes les ~18 s, gaspillant de l'energie et spammant la notification.
; 1/96 de jour = 15 minutes de jeu = 4 exploitations par heure, comme demande par Kevin.
float Property VTN_OreCooldownDays = 0.0104166 Auto
; Anneau glissant (FormID + heure de jeu) des derniers filons exploites. Papyrus n'a pas de map native ;
; 16 emplacements suffisent largement (on ne mine qu'un ou deux filons a la fois).
Form[] _cooldownRefs
float[] _cooldownTimes
int _cooldownNext = 0

; Valeur en or minimale pour qu'un objet au sol vaille la peine d'etre ramasse. Ecarte le bric-a-brac
; (assiettes, gobelets, couverts...) que Velyn ramassait sans interet.
int Property VTN_MinItemValue = 5 Auto

; --------------------------------------------------------------------------------------------------

bool Function IsRedirecting()
    return _redirecting
EndFunction

; Notification localisable via record Message (voir VTN_MainQuestScript.Notify pour le detail).
Function Notify(string asEditorID)
    Message m = PO3_SKSEFunctions.GetFormFromEditorID(asEditorID) as Message
    if m
        m.Show()
    endif
EndFunction

; --------------------------------------------------------------------------------------------------
; Filtres manuels par objet (extension 2026-07-23bis) : liste blanche/noire via PapyrusUtil JsonUtil.
; --------------------------------------------------------------------------------------------------
; Idee de Kevin : pouvoir forcer l'autorisation ou l'interdiction d'un objet PRECIS, independamment des
; regles automatiques (type/valeur/mots-cles) - utile pour les mods de contenu (armures/potions
; ajoutees, par exemple) que ces regles ne couvrent pas bien. Stockage cote disque via
; JsonUtil.FormListAdd/Remove/Has (fichier data/skse/plugins/StorageUtilData/VelynTheNetch.json, deux
; listes "Whitelist"/"Blacklist" de Form) : persiste tout seul a la sauvegarde, aucun code de
; (de)serialisation a ecrire. Necessite PapyrusUtil installe - a noter comme dependance de CETTE
; fonctionnalite precise dans le FOMOD, pas du mod entier (le reste tourne sans).
bool Function IsBlacklisted(Form akItem)
    if !akItem
        return false
    endif
    return JsonUtil.FormListHas(VTN_FilterStoreName, "Blacklist", akItem)
EndFunction

bool Function IsWhitelisted(Form akItem)
    if !akItem
        return false
    endif
    return JsonUtil.FormListHas(VTN_FilterStoreName, "Whitelist", akItem)
EndFunction

; Appelee par VTN_MainQuestScript.OnKeyDown quand la touche de filtre (MCM, non liee par defaut) est
; pressee. Cible = ce que le joueur vise (Game.GetCurrentCrosshairRef, natif SKSE, deja une dependance
; du mod). Message.Show() est bloquant (meme pattern que VTN_VelynMenu), renvoie l'index du bouton.
Function HandleFilterKeyPress()
    ObjectReference target = Game.GetCurrentCrosshairRef()
    if !target || !target.GetBaseObject()
        Notify("VTN_MsgNothingTargeted")
        return
    endif
    Form base = target.GetBaseObject()
    Notify("VTN_MsgTargeting")

    int choice = VTN_FilterMenu.Show()
    if choice == 0
        JsonUtil.FormListRemove(VTN_FilterStoreName, "Blacklist", base)
        JsonUtil.FormListAdd(VTN_FilterStoreName, "Whitelist", base, false)
        Notify("VTN_MsgWhitelisted")
        Debug.TraceUser("VTN", "Filtre : " + base.GetName() + " ajoute a la liste blanche")
    elseif choice == 1
        JsonUtil.FormListRemove(VTN_FilterStoreName, "Whitelist", base)
        JsonUtil.FormListAdd(VTN_FilterStoreName, "Blacklist", base, false)
        Notify("VTN_MsgBlacklisted")
        Debug.TraceUser("VTN", "Filtre : " + base.GetName() + " ajoute a la liste noire")
    elseif choice == 2
        JsonUtil.FormListRemove(VTN_FilterStoreName, "Whitelist", base)
        JsonUtil.FormListRemove(VTN_FilterStoreName, "Blacklist", base)
        Notify("VTN_MsgFilterCleared")
        Debug.TraceUser("VTN", "Filtre : " + base.GetName() + " retire des deux listes")
    endif
    ; choice == 3 (Annuler) : rien a faire.
EndFunction

; Balayage dedie a la liste blanche (2026-07-23bis) : contrairement aux scans par type de formulaire
; ci-dessous, celui-ci recherche des objets PRECIS quel que soit leur type (armure, arme, potion...),
; via FindAllReferencesOfType(akRef, UN FORM, rayon) - accepte un Form unique aussi bien qu'une FormList,
; verifie dans PO3_SKSEFunctions.psc. C'est ce qui permet a la liste blanche d'aller au-dela des types
; deja scannes (FLOR/TREE/ACTI/MISC/INGR) : Kevin voulait pouvoir whitelister une armure ou une potion
; qu'aucune regle automatique ne ramasserait jamais.
bool Function HarvestWhitelistedItems(Actor akVelyn, VTN_ProgressionScript prog)
    int count = JsonUtil.FormListCount(VTN_FilterStoreName, "Whitelist")
    if count == 0
        return false
    endif
    ; Meme regle de bon sens que le ramassage libre : pas de "vol de circonstance" dans un lieu habite,
    ; meme pour un objet explicitement whiteliste. IsOffLimits (verifie plus bas) reste de toute facon
    ; non negociable : la liste blanche ne fait jamais voler le joueur.
    if IsInhabitedArea()
        return false
    endif

    int i = 0
    while i < count
        Form entry = JsonUtil.FormListGet(VTN_FilterStoreName, "Whitelist", i)
        if entry
            ObjectReference[] found = PO3_SKSEFunctions.FindAllReferencesOfType(akVelyn, entry, GetRadiusItems())
            if found && found.Length > 0
                int j = 0
                while j < found.Length
                    ObjectReference item = found[j]
                    if item && !item.IsDisabled() && !item.IsOffLimits() && !item.IsDeleted()
                        ; On agit d'abord, on ne facture qu'en cas de succes averé (2026-07-27). Avant,
                        ; l'energie et la notification partaient sans verification : sur une ressource
                        ; "en place" (nirnroot, plante), AddItem ne fait rien et Velyn brulait un point
                        ; par cycle sur un objet qui ne partirait jamais.
                        if TakeWhitelistedRef(akVelyn, item)
                            prog.SpendHarvestPoint()
                            prog.AddXP(GetXPPerHarvest())
                            if ShouldNotify()
                                Notify("VTN_MsgPickupWhitelist")
                            endif
                            Debug.TraceUser("VTN", "Ramassage liste blanche : " + entry.GetName())
                            return true
                        endif
                    endif
                    j += 1
                endwhile
            endif
        endif
        i += 1
    endwhile
    return false
EndFunction

; Prend une reference mise en liste blanche, QUEL QUE SOIT son type, et dit si ca a reellement marche.
; Deux mecaniques totalement differentes selon ce qu'est l'objet, d'ou l'aiguillage (2026-07-27) :
;   - une ressource "en place" (FLOR, TREE, ACTI, MSTT) se RECOLTE : on l'active, et la preuve de
;     reussite est qu'elle passe a l'etat recolte (flore) ou qu'elle disparait (nirnroot, insecte) ;
;   - un objet pose au sol se RAMASSE : AddItem deplace la reference elle-meme dans l'inventaire, et la
;     preuve est que le compte de cet objet a augmente chez Velyn.
; Sans cet aiguillage, AddItem etait appele sur une plante : aucun effet, aucune erreur, et le code
; notifiait + facturait quand meme. C'est exactement le bug du nirnroot remonte par Kevin.
bool Function TakeWhitelistedRef(Actor akVelyn, ObjectReference akItem)
    Form base = akItem.GetBaseObject()
    if !base
        return false
    endif
    int baseType = base.GetType()
    if baseType == VTN_FormTypeFlora || baseType == VTN_FormTypeTree || baseType == VTN_FormTypeActivator || baseType == VTN_FormTypeMovableStatic
        BeginRedirect()
        akItem.Activate(Game.GetPlayer())
        EndRedirect()
        return akItem.IsHarvested() || akItem.IsDisabled()
    endif
    int before = akVelyn.GetItemCount(base)
    akVelyn.AddItem(akItem, 1, true) ; true = silencieux
    return akVelyn.GetItemCount(base) > before
EndFunction

; --------------------------------------------------------------------------------------------------
; Zones habitees (2026-07-22, retour : "elle les pique dans les etables/marches, chez les gens")
; --------------------------------------------------------------------------------------------------
; IsOffLimits() ne suffisait pas : dans une ferme ou un marche, beaucoup de plantes n'ont AUCUN
; proprietaire declare - donc techniquement ce n'est pas du vol (Kevin l'avait constate), mais le
; comportement reste choquant. On ajoute donc une regle de bon sens : Velyn ne recolte pas dans un lieu
; habite. Les mots-cles sont resolus par EditorID via po3 -> aucun FormID code en dur, et si l'un
; d'eux n'existe pas, GetFormFromEditorID renvoie None et on l'ignore simplement.
Function ResolveKeywords()
    if _keywordsResolved
        return
    endif
    _keywordsResolved = true
    ; Regle affinee (2026-07-22, choix de Kevin) : elle PEUT recolter en ville, y compris dans les rues.
    ; On ne bloque que les endroits ou prendre quelque chose serait deplace meme sans etre du vol :
    ; interieur des maisons, boutiques, auberges, etables et fermes.
    ; Volontairement RETIRES de cette liste : LocTypeCity / LocTypeTown / LocTypeSettlement /
    ; LocTypeHabitation - ils bloquaient des villes entieres, y compris leurs rues et leurs abords.
    ; Les etals de marchands restent proteges par IsOffLimits() : leurs marchandises ont un proprietaire.
    ; LocTypePlayerHouse est ESSENTIEL et non redondant : dans sa propre maison, les objets que le joueur
    ; pose LUI APPARTIENNENT, donc IsOffLimits() est faux et la regle anti-vol ne les protege pas. Sans
    ; ce mot-cle, Velyn viderait le coffre-fort personnel du joueur - exactement ce que Kevin redoutait.
    _inhabitedKeywords = new Keyword[6]
    _inhabitedKeywords[0] = PO3_SKSEFunctions.GetFormFromEditorID("LocTypeDwelling") as Keyword
    _inhabitedKeywords[1] = PO3_SKSEFunctions.GetFormFromEditorID("LocTypePlayerHouse") as Keyword
    _inhabitedKeywords[2] = PO3_SKSEFunctions.GetFormFromEditorID("LocTypeStore") as Keyword
    _inhabitedKeywords[3] = PO3_SKSEFunctions.GetFormFromEditorID("LocTypeInn") as Keyword
    _inhabitedKeywords[4] = PO3_SKSEFunctions.GetFormFromEditorID("LocTypeStable") as Keyword
    _inhabitedKeywords[5] = PO3_SKSEFunctions.GetFormFromEditorID("LocTypeFarm") as Keyword

    _inhabitedToggles = new GlobalVariable[6]
    _inhabitedToggles[0] = VTN_CfgBlockDwelling
    _inhabitedToggles[1] = VTN_CfgBlockPlayerHouse
    _inhabitedToggles[2] = VTN_CfgBlockStore
    _inhabitedToggles[3] = VTN_CfgBlockInn
    _inhabitedToggles[4] = VTN_CfgBlockStable
    _inhabitedToggles[5] = VTN_CfgBlockFarm
EndFunction

bool Function IsInhabitedArea()
    ResolveKeywords()
    Location loc = Game.GetPlayer().GetCurrentLocation()
    if !loc
        return false ; hors de tout lieu declare (nature) : recolte autorisee
    endif
    int i = 0
    while i < _inhabitedKeywords.Length
        Keyword kw = _inhabitedKeywords[i]
        GlobalVariable toggle = _inhabitedToggles[i]
        ; Case decochee au MCM (Bloc 3) -> ce type de lieu n'est plus bloque, quel que soit le mod
        ; installe par le joueur. Repli sur "bloque" si la globale est absente pour une raison ou une
        ; autre (comportement d'origine, plus sur que d'ouvrir une faille par defaut).
        bool enabled = !toggle || toggle.GetValueInt() == 1
        if kw && enabled && loc.HasKeyword(kw)
            return true
        endif
        i += 1
    endwhile
    return false
EndFunction

; Rayon general effectif : celui du MCM s'il est defini, sinon le defaut du script.
float Function GetRadius()
    if VTN_CfgHarvestRadius && VTN_CfgHarvestRadius.GetValue() > 0.0
        return VTN_CfgHarvestRadius.GetValue()
    endif
    return VTN_HarvestRadius
EndFunction

; Rayon par categorie (Bloc 3, 2026-07-23) : chaque categorie peut avoir son propre rayon MCM ; tant
; que sa globale vaut 0 (defaut), elle retombe sur le rayon general ci-dessus. Cela evite d'imposer un
; reglage supplementaire a qui ne veut pas s'en soucier, tout en permettant de la finesse.
float Function GetRadiusFlora()
    if VTN_CfgRadiusFlora && VTN_CfgRadiusFlora.GetValue() > 0.0
        return VTN_CfgRadiusFlora.GetValue()
    endif
    return GetRadius()
EndFunction

float Function GetRadiusOre()
    if VTN_CfgRadiusOre && VTN_CfgRadiusOre.GetValue() > 0.0
        return VTN_CfgRadiusOre.GetValue()
    endif
    return GetRadius()
EndFunction

float Function GetRadiusCritter()
    if VTN_CfgRadiusCritter && VTN_CfgRadiusCritter.GetValue() > 0.0
        return VTN_CfgRadiusCritter.GetValue()
    endif
    return GetRadius()
EndFunction

float Function GetRadiusItems()
    if VTN_CfgRadiusItems && VTN_CfgRadiusItems.GetValue() > 0.0
        return VTN_CfgRadiusItems.GetValue()
    endif
    return GetRadius()
EndFunction

; Valeur minimale effective : celle du MCM si definie (0 inclus - un joueur peut vouloir tout ramasser),
; sinon le defaut du script. Contrairement aux rayons, 0 est une valeur MCM valide ici, donc on ne peut
; pas s'en servir comme sentinelle "pas configure" -> on teste plutot que la globale existe.
int Function GetMinItemValue()
    if VTN_CfgMinItemValue
        return VTN_CfgMinItemValue.GetValue() as int
    endif
    return VTN_MinItemValue
EndFunction

; Cooldown effectif en JOURS de jeu : le MCM expose des minutes (plus lisible), converties ici.
float Function GetOreCooldownDays()
    if VTN_CfgOreCooldownMinutes && VTN_CfgOreCooldownMinutes.GetValue() > 0.0
        return VTN_CfgOreCooldownMinutes.GetValue() / 1440.0
    endif
    return VTN_OreCooldownDays
EndFunction

float Function GetXPPerHarvest()
    if VTN_CfgXPPerHarvest && VTN_CfgXPPerHarvest.GetValue() > 0.0
        return VTN_CfgXPPerHarvest.GetValue()
    endif
    return VTN_XPPerHarvest
EndFunction

bool Function ShouldNotify()
    if VTN_CfgNotifyHarvest
        return VTN_CfgNotifyHarvest.GetValueInt() == 1
    endif
    return VTN_NotifyHarvest
EndFunction

; Appelee periodiquement par VTN_VelynAliasScript. Recolte AU PLUS UNE ressource par passage : cela
; etale la depense d'energie, evite un pic de charge script, et rend le comportement lisible.
Function TryHarvest(Actor akVelyn)
    if VTN_CfgHarvestEnabled && VTN_CfgHarvestEnabled.GetValueInt() == 0
        return ; recolte desactivee au MCM
    endif
    if !akVelyn || VTN_HasVelyn.GetValueInt() != 1 || VTN_IsWaiting.GetValueInt() == 1
        return
    endif
    ; NB : la regle "lieu habite" ne s'applique PLUS ici (2026-07-23). Elle bloquait le terrain du
    ; manoir du joueur (classe Hearthfire habitation), donc son propre filon de corindon. Les ressources
    ; (filons, flore, insectes) ne sont desormais gatees que par la PROPRIETE (IsOffLimits). La regle
    ; "lieu habite" ne concerne que le RAMASSAGE au sol (PickUpNearestItem) : c'est la qu'il faut eviter
    ; de vider les etageres d'une maison ou les etals d'une echoppe.
    VTN_ProgressionScript prog = VTN_MainQuest as VTN_ProgressionScript
    if !prog || !prog.IsHarvestUnlocked()
        return
    endif

    ; Inutile de scanner si elle n'a plus d'energie ou si elle est deja pleine : on economise le scan,
    ; qui est la partie couteuse.
    if prog.VTN_Energy.GetValue() < 1.0
        return
    endif
    if akVelyn.GetTotalItemWeight() >= prog.GetCapacity()
        if !_warnedFull
            _warnedFull = true
            Notify("VTN_MsgTooLaden")
        endif
        return
    endif
    _warnedFull = false

    ; ORDRE IMPORTANT (2026-07-22) : les filons D'ABORD. Une seule ressource est traitee par passage ;
    ; auparavant la flore passait en premier et, comme elle attrapait n'importe quoi (des bourses !),
    ; elle monopolisait chaque cycle et le code des filons n'etait JAMAIS atteint. C'est la vraie raison
    ; pour laquelle le filon de corindon semblait ignore.
    if HarvestNearestOreVein(akVelyn, prog)
        return
    endif
    if HarvestNearestFlora(akVelyn, prog)
        return
    endif
    if HarvestNearestCritter(akVelyn, prog)
        return
    endif
    if PickUpNearestItem(akVelyn, prog)
        return
    endif
    HarvestWhitelistedItems(akVelyn, prog)
EndFunction

; --------------------------------------------------------------------------------------------------
; Ramassage des objets libres au sol (2026-07-22, demande de Kevin)
; --------------------------------------------------------------------------------------------------
; Regle unique et stricte : elle ne prend QUE ce qui n'appartient a personne (IsOffLimits). Les zones
; interdites (maisons, boutiques, auberges, etables, fermes) sont deja ecartees en amont par TryHarvest.
; Types ramasses : 32 = MISC (septims, bourses, lingots, gemmes) et 30 = INGR (ingredients au sol).
; Volontairement PAS d'armes ni d'armures : ce sont des "objets", pas des ressources.
; AddItem sur une reference du monde deplace cet objet precis dans son inventaire - inutile de passer
; par le joueur, donc aucune redirection ici.
bool Function PickUpNearestItem(Actor akVelyn, VTN_ProgressionScript prog)
    if VTN_CfgPickupEnabled && VTN_CfgPickupEnabled.GetValueInt() == 0
        return false
    endif
    ; Le ramassage d'objets libres, LUI, respecte les lieux habites : on ne vide pas les etageres d'une
    ; maison (y compris celle du joueur, ou il RANGE ses affaires), ni les etals d'une echoppe/auberge.
    if IsInhabitedArea()
        return false
    endif
    if PickUpOfType(akVelyn, prog, 32)
        return true
    endif
    return PickUpOfType(akVelyn, prog, 30)
EndFunction

; Est-ce LA piece d'or vanilla ? Cas particulier : faible valeur unitaire (1), mais toujours desirable,
; et pilote par son propre interrupteur MCM (VTN_CfgPickupGoldEnabled) plutot que par le seuil de valeur.
bool Function IsGoldItem(Form akItem)
    Form gold = PO3_SKSEFunctions.GetFormFromEditorID("Gold001")
    return gold && akItem == gold
EndFunction

; Interrupteur applicable a CET item, selon sa categorie (Bloc 3, 2026-07-23) : l'or, les ingredients et
; le reste des objets MISC (bourses, lingots, gemmes...) sont desormais trois cases independantes plutot
; qu'un seul VTN_CfgPickupEnabled global, pour pouvoir par ex. garder l'or mais couper les babioles.
bool Function IsCategoryEnabled(Form akItem, int aiFormType)
    if aiFormType == 30 ; INGR
        return !VTN_CfgPickupIngredientsEnabled || VTN_CfgPickupIngredientsEnabled.GetValueInt() == 1
    endif
    if IsGoldItem(akItem)
        return !VTN_CfgPickupGoldEnabled || VTN_CfgPickupGoldEnabled.GetValueInt() == 1
    endif
    return !VTN_CfgPickupMiscEnabled || VTN_CfgPickupMiscEnabled.GetValueInt() == 1
EndFunction

; Ecarte le bric-a-brac (2026-07-22, retour "elle ramasse des objets divers sans interet").
; Deux filtres complementaires : le mot-cle vanilla VendorItemClutter marque explicitement la vaisselle
; et les babioles ; le seuil de valeur (reglable au MCM, Bloc 3) attrape le reste. L'or echappe au
; seuil : une seule piece vaut 1, mais c'est evidemment a prendre.
bool Function IsWorthTaking(Form akItem)
    if !akItem
        return false
    endif
    ; Filtre manuel (extension 2026-07-23bis) : la liste noire l'emporte sur tout, la liste blanche
    ; court-circuite les regles automatiques qui suivent (type/valeur/mots-cles).
    if IsBlacklisted(akItem)
        return false
    endif
    if IsWhitelisted(akItem)
        return true
    endif
    if akItem as MiscObject && akItem.GetName() != "" && akItem.GetGoldValue() <= 0
        return false ; objets sans valeur ni nom exploitable
    endif

    Keyword clutter = PO3_SKSEFunctions.GetFormFromEditorID("VendorItemClutter") as Keyword
    if clutter && akItem.HasKeyword(clutter)
        return false
    endif

    if IsGoldItem(akItem)
        return true
    endif

    return akItem.GetGoldValue() >= GetMinItemValue()
EndFunction

bool Function PickUpOfType(Actor akVelyn, VTN_ProgressionScript prog, int aiFormType)
    ObjectReference[] found = PO3_SKSEFunctions.FindAllReferencesOfFormType(akVelyn, aiFormType, GetRadiusItems())
    if !found || found.Length == 0
        return false
    endif

    int i = 0
    while i < found.Length
        ObjectReference item = found[i]
        ; Un objet liste blanche outrepasse aussi l'interrupteur de categorie (or/ingredients/divers) :
        ; c'est le sens meme d'un forcage explicite. IsWorthTaking() gere blacklist/whitelist/valeur.
        Form itemBase = item.GetBaseObject()
        bool categoryOk = itemBase && (IsWhitelisted(itemBase) || IsCategoryEnabled(itemBase, aiFormType))
        if item && !item.IsDisabled() && !item.IsOffLimits() && itemBase && !item.IsDeleted() && categoryOk && IsWorthTaking(itemBase)
            ; Meme regle que les ressources : pas de succes, pas de cout (2026-07-27). Les types scannes
            ; ici sont toujours des objets transportables, donc l'echec est rare, mais on ne veut plus
            ; d'une notification qui annonce un ramassage qui n'a pas eu lieu.
            int before = akVelyn.GetItemCount(itemBase)
            akVelyn.AddItem(item, 1, true) ; true = silencieux
            if akVelyn.GetItemCount(itemBase) > before
                prog.SpendHarvestPoint()
                prog.AddXP(GetXPPerHarvest())
                if ShouldNotify()
                    Notify("VTN_MsgPickup")
                endif
                Debug.TraceUser("VTN", "Ramassage : " + itemBase.GetName())
                return true
            endif
        endif
        i += 1
    endwhile
    return false
EndFunction

; --------------------------------------------------------------------------------------------------
; Insectes : papillons, lucioles, abeilles (demande de Kevin, 2026-07-22)
; --------------------------------------------------------------------------------------------------
; Tous heritent du script vanilla "Critter" (verifie dans Data\Scripts\Source : Critter.psc, dont
; derivent critterMoth, critterDragonFly...). Un simple cast suffit donc a les identifier, sans avoir a
; reconnaitre des noms au cas par cas. Ils apparaissent tantot en ACTI, tantot en MSTT -> on balaie les
; deux types.
bool Function HarvestNearestCritter(Actor akVelyn, VTN_ProgressionScript prog)
    if HarvestCrittersOfType(akVelyn, prog, VTN_FormTypeActivator)
        return true
    endif
    return HarvestCrittersOfType(akVelyn, prog, VTN_FormTypeMovableStatic)
EndFunction

bool Function HarvestCrittersOfType(Actor akVelyn, VTN_ProgressionScript prog, int aiFormType)
    ObjectReference[] found = PO3_SKSEFunctions.FindAllReferencesOfFormType(akVelyn, aiFormType, GetRadiusCritter())
    if !found || found.Length == 0
        return false
    endif

    int i = 0
    while i < found.Length
        ObjectReference bug = found[i]
        Critter bugScript = bug as Critter ; ne pas nommer cette variable "critter" : Papyrus est
                                           ; insensible a la casse et la confondrait avec le TYPE Critter
        if bugScript && !bug.IsDisabled() && !bug.IsOffLimits() && !IsBlacklisted(bug.GetBaseObject())
            ; Meme principe que pour la flore : on active d'abord, on ne facture qu'en cas de succes.
            ; Un insecte attrape est desactive par le jeu -> c'est notre preuve de reussite.
            BeginRedirect()
            bug.Activate(Game.GetPlayer())
            EndRedirect()

            if bug.IsDisabled()
                prog.SpendHarvestPoint()
                prog.AddXP(GetXPPerHarvest())
                if ShouldNotify()
                    Notify("VTN_MsgCritter")
                endif
                Debug.TraceUser("VTN", "Recolte insecte : " + bug)
                return true
            endif
        endif
        i += 1
    endwhile
    return false
EndFunction

; --------------------------------------------------------------------------------------------------
; Flore
; --------------------------------------------------------------------------------------------------
; Beaucoup de plantes recoltables sont en realite de type TREE et non FLOR (verifie en jeu : chardon =
; TreeFloraThistle01, lys des cimes = TreeFloraMountainFlower01, tous "TREE(Tree)"). On DOIT donc scanner
; les deux. Le balayage TREE avait ete retire car il ramenait des bourses ("Recolte flore : Bourse") ;
; la vraie parade n'etait pas de renoncer aux TREE mais de FILTRER par type d'objet de base (voir
; HarvestFromType) : une bourse est un MISC, elle est desormais rejetee, alors que les plantes TREE
; passent.
bool Function HarvestNearestFlora(Actor akVelyn, VTN_ProgressionScript prog)
    if HarvestFromType(akVelyn, prog, VTN_FormTypeFlora)
        return true
    endif
    if HarvestFromType(akVelyn, prog, VTN_FormTypeTree)
        return true
    endif
    return HarvestNearestNirnroot(akVelyn, prog)
EndFunction

; --------------------------------------------------------------------------------------------------
; Nirnroots (2026-07-27, bug remonte par Kevin : "j'ai la notif mais elle ne ramasse pas le nirnroot")
; --------------------------------------------------------------------------------------------------
; Le nirnroot et le nirnroot cramoisi ne sont NI FLOR NI TREE : ce sont des ACTI (24). Verifie dans
; Skyrim.esm -> TreeFloraNirnroot01 et TreeFloraNirnrootRed01 sont bien des records ACTI. Bethesda les a
; faits ainsi parce qu'ils brillent et bourdonnent en boucle : a la recolte, le script vanilla masque la
; plante et fait apparaitre une version "vide" a la place, au lieu de passer par le mecanisme Flora.
; Deux consequences pour nous :
;   - le scan flore (FLOR/TREE) ne les voit tout simplement pas ;
;   - IsHarvested() ne passera JAMAIS a true dessus, ce n'est pas une Flora.
; Les deux variantes partagent le meme script (verifie dans le VMAD des deux records) -> un seul cast
; les identifie toutes les deux, sans aucun FormID en dur. Meme pattern eprouve que "as Critter" pour
; les insectes et "as MineOreScript" pour les filons.
; Preuve de reussite : NirnrootACTIVATORScript.onActivate() donne l'ingredient a l'acteur declencheur
; (d'ou la redirection, comme pour la flore) puis fait self.DisableNoWait() -> IsDisabled() est donc
; notre test, exactement comme pour un insecte attrape. Le script vanilla passe en plus dans l'etat
; "AlreadyHarvested" : une seconde activation ne peut pas dupliquer l'ingredient.
bool Function HarvestNearestNirnroot(Actor akVelyn, VTN_ProgressionScript prog)
    ObjectReference[] found = PO3_SKSEFunctions.FindAllReferencesOfFormType(akVelyn, VTN_FormTypeActivator, GetRadiusFlora())
    if !found || found.Length == 0
        return false
    endif

    int i = 0
    while i < found.Length
        ObjectReference plant = found[i]
        NirnrootACTIVATORScript nirn = plant as NirnrootACTIVATORScript
        if nirn && !plant.IsDisabled() && !plant.IsOffLimits() && !IsBlacklisted(plant.GetBaseObject())
            ; Meme regle que partout ailleurs : on agit d'abord, on ne facture qu'en cas de succes.
            BeginRedirect()
            plant.Activate(Game.GetPlayer())
            EndRedirect()

            if plant.IsDisabled()
                prog.SpendHarvestPoint()
                prog.AddXP(GetXPPerHarvest())
                if ShouldNotify()
                    Notify("VTN_MsgHarvestFlora")
                endif
                Debug.TraceUser("VTN", "Recolte nirnroot : " + plant.GetBaseObject().GetName())
                return true
            endif
        endif
        i += 1
    endwhile
    return false
EndFunction

bool Function HarvestFromType(Actor akVelyn, VTN_ProgressionScript prog, int aiFormType)
    ObjectReference[] found = PO3_SKSEFunctions.FindAllReferencesOfFormType(akVelyn, aiFormType, GetRadiusFlora())
    if !found || found.Length == 0
        return false
    endif

    int i = 0
    while i < found.Length
        ObjectReference plant = found[i]
        ; IsOffLimits ecarte tout ce qui appartient a quelqu'un : sans ce test, Velyn ferait du joueur
        ; un voleur dans les fermes et les camps. Non negociable.
        ; IsHarvested ecarte ce qui a DEJA ete cueilli - sinon elle "recolterait" du vide en boucle.
        ; Filtre STRICT par type d'objet de base : on n'accepte QUE de la vraie flore, FLOR (39) ou
        ; TREE (38). Une bourse (MISC, 32) ou tout autre bric-a-brac ramene par erreur par le scan est
        ; ainsi rejete d'office, avant meme d'etre active - c'est ce qui empeche le retour du bug
        ; "Recolte flore : Bourse", tout en laissant passer les plantes de type TREE.
        Form plantBase = plant.GetBaseObject()
        int plantType = 0
        if plantBase
            plantType = plantBase.GetType()
        endif
        ; Liste blanche (2026-07-23bis) : autorise un type de plante hors FLOR/TREE (rare, mais permet
        ; de forcer un cas particulier ajoute par un autre mod). Liste noire : bloque une plante precise
        ; meme si son type est normalement recoltable.
        if (plantType == VTN_FormTypeFlora || plantType == VTN_FormTypeTree || IsWhitelisted(plantBase)) && !plant.IsDisabled() && !plant.IsOffLimits() && !plant.IsHarvested() && !IsBlacklisted(plantBase)
            ; L'energie n'est PAS depensee d'avance : beaucoup de TREE ne sont pas recoltables (sapins,
            ; decor...) et il n'existe aucun moyen de le savoir a l'avance depuis Papyrus. On active, puis
            ; on verifie via IsHarvested() que quelque chose a reellement ete pris. Pas de succes, pas de
            ; cout : elle ne gaspille donc jamais un point sur un arbre decoratif.
            BeginRedirect()
            plant.Activate(Game.GetPlayer())
            EndRedirect()

            if plant.IsHarvested()
                prog.SpendHarvestPoint()
                prog.AddXP(GetXPPerHarvest())
                if ShouldNotify()
                    Notify("VTN_MsgHarvestFlora")
                endif
                Debug.TraceUser("VTN", "Recolte flore : " + plant.GetBaseObject().GetName())
                return true
            endif
        endif
        i += 1
    endwhile
    return false
EndFunction

; --------------------------------------------------------------------------------------------------
; Filons de minerai
; --------------------------------------------------------------------------------------------------
; Les filons ne sont pas tous du meme type de formulaire selon les mines et les mods. On balaie donc
; plusieurs types et on identifie par le cast vers MineOreScript, qui reste le test fiable.
bool Function HarvestNearestOreVein(Actor akVelyn, VTN_ProgressionScript prog)
    if HarvestOreOfType(akVelyn, prog, VTN_FormTypeActivator)
        return true
    endif
    if HarvestOreOfType(akVelyn, prog, VTN_FormTypeMovableStatic)
        return true
    endif
    return HarvestOreOfType(akVelyn, prog, VTN_FormTypeFurniture)
EndFunction

bool Function HarvestOreOfType(Actor akVelyn, VTN_ProgressionScript prog, int aiFormType)
    ObjectReference[] found = PO3_SKSEFunctions.FindAllReferencesOfFormType(akVelyn, aiFormType, GetRadiusOre())
    if !found || found.Length == 0
        return false
    endif

    ; Diagnostic (2026-07-22, retour "certains filons comme le corindon ne sont pas ramasses").
    ; On trace pourquoi un filon detecte est ecarte, plutot que de supposer. A retirer une fois regle.
    int candidates = 0
    int skippedOffLimits = 0
    int skippedDisabled = 0

    int i = 0
    while i < found.Length
        ObjectReference vein = found[i]
        ; Un activateur n'est un filon que s'il porte MineOreScript : le cast est le test le plus fiable
        ; (bien plus que de tenter de reconnaitre des noms ou des mots-cles).
        MineOreScript ore = vein as MineOreScript
        if ore
            candidates += 1
        endif
        if ore && vein.IsDisabled()
            skippedDisabled += 1
        elseif ore && vein.IsOffLimits()
            skippedOffLimits += 1
        endif

        ; Deux garde-fous contre le spam constate en jeu :
        ;   - IsHarvested() ecarte un filon deja vide qui ne s'est pas encore reforme ;
        ;   - IsOnCooldown() ecarte un filon exploite recemment - c'est LUI qui dompte les ressources
        ;     inepuisables (carriere) qui, elles, ne passent jamais a l'etat "recolte".
        if ore && !vein.IsDisabled() && !vein.IsOffLimits() && !vein.IsHarvested() && !IsOnCooldown(vein) && !IsBlacklisted(vein.GetBaseObject())
            BeginRedirect()
            int guard = 0
            while ore.ResourceCountCurrent != 0 && guard < 10
                ore.giveOre()
                guard += 1
            endwhile
            EndRedirect()

            ; Une exploitation reelle a eu lieu (le filon a livre son minerai, epuisable ou non) : on la
            ; facture une fois et on pose le cooldown. 1 point d'energie = 1 exploitation, quelle que soit
            ; la quantite. La carriere est ainsi limitee a 4x/heure de jeu, sans plus jamais de boucle.
            RecordCooldown(vein)
            prog.SpendHarvestPoint()
            prog.AddXP(GetXPPerHarvest())
            if ShouldNotify()
                Notify("VTN_MsgHarvestOre")
            endif
            Debug.TraceUser("VTN", "Recolte filon : " + vein)
            return true
        endif
        i += 1
    endwhile

    if candidates > 0
        Debug.TraceUser("VTN", "[diag filons] type=" + aiFormType + " refs=" + found.Length + " filons=" + candidates + " ecartes(propriete)=" + skippedOffLimits + " ecartes(desactive)=" + skippedDisabled + " -> aucun recolte")
    endif
    return false
EndFunction

; --------------------------------------------------------------------------------------------------
; Redirection des objets vers Velyn
; --------------------------------------------------------------------------------------------------
; --- Cooldown par filon (anneau glissant) ---------------------------------------------------------
bool Function IsOnCooldown(ObjectReference akRef)
    if !_cooldownRefs
        return false
    endif
    float now = Utility.GetCurrentGameTime()
    float cooldownDays = GetOreCooldownDays()
    int i = 0
    while i < _cooldownRefs.Length
        if _cooldownRefs[i] == akRef && (now - _cooldownTimes[i]) < cooldownDays
            return true
        endif
        i += 1
    endwhile
    return false
EndFunction

Function RecordCooldown(ObjectReference akRef)
    if !_cooldownRefs
        _cooldownRefs = new Form[16]
        _cooldownTimes = new Float[16]
    endif
    _cooldownRefs[_cooldownNext] = akRef
    _cooldownTimes[_cooldownNext] = Utility.GetCurrentGameTime()
    _cooldownNext += 1
    if _cooldownNext >= 16
        _cooldownNext = 0
    endif
EndFunction

Function BeginRedirect()
    _redirecting = true
EndFunction

Function EndRedirect()
    ; Court delai avant de refermer la fenetre : OnItemAdded n'est pas forcement traite dans la meme
    ; frame que l'ajout, et on ne veut pas laisser filer un objet dans l'inventaire du joueur.
    Utility.Wait(0.5)
    _redirecting = false
EndFunction
