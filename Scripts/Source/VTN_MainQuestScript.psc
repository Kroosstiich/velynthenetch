Scriptname VTN_MainQuestScript extends Quest

GlobalVariable Property VTN_HasVelyn Auto
GlobalVariable Property VTN_IsWaiting Auto
Message Property VTN_VelynMenu Auto ; menu MessageBox (record 000824) - remplace le menu de dialogue
                                    ; in-world, impossible sur un netch (race creature, pas de VoiceType).
Message Property VTN_VelynMenuNoRide Auto ; variante SANS l'option "Monte sur mon dos" (record 000861),
                                          ; affichee quand Piggyback n'est pas installe / portage desactive.
float Property VTN_MenuRange = 600.0 Auto ; distance max pour ouvrir son menu (a ajuster au ressenti)

; Reglages du rig "sur le dos" (Piggyback). Noeud vanilla -> aucune dependance a XPMSSE.
; Le noeud ne sert que de POINT D'ORIGINE ; l'offset est exprime dans le repere du cap du joueur :
;   X = droite (negatif = gauche), Y = avant (negatif = DERRIERE), Z = haut (negatif = plus bas).
; Reglage 2026-07-22 : Spine2 est a hauteur de poitrine et la 1re valeur la placait au-dessus de la
; tete -> on descend nettement (Z) pour viser le bas du dos / hauteur des genoux, et on recule (Y).
; Ces 3 valeurs sont exposees en proprietes : c'est ce que le FOMOD proposera de configurer.
; --- Reglages MCM (globales ecrites directement par MCM Helper) ---
GlobalVariable Property VTN_CfgRideEnabled Auto
GlobalVariable Property VTN_CfgRideOffsetX Auto
GlobalVariable Property VTN_CfgRideOffsetY Auto
GlobalVariable Property VTN_CfgRideOffsetZ Auto
GlobalVariable Property VTN_CfgInventoryKey Auto
; Touche de filtre manuel (Bloc 3 extension, 2026-07-23bis) : liste blanche/noire d'objets via
; PapyrusUtil. Contrairement a la touche inventaire, PAS de defaut : 0 = non liee, la fonctionnalite
; reste inerte tant que le joueur ne l'a pas explicitement assignee au MCM (fonctionnalite optionnelle,
; requiert PapyrusUtil - a documenter dans le FOMOD).
GlobalVariable Property VTN_CfgFilterKey Auto

string Property VTN_RideNode = "NPC Spine2 [Spn2]" Auto
float Property VTN_RideOffsetX = 18.0 Auto   ; decale vers la DROITE ("comme si elle est derriere la main")
float Property VTN_RideOffsetY = -60.0 Auto  ; derriere le joueur (-22 "trop colle", puis -45 encore trop proche)
float Property VTN_RideOffsetZ = -90.0 Auto  ; etait -55 -> la placait au niveau du ventre. Le modele du
                                             ; netch s'etend vers le HAUT depuis son origine, donc il faut
                                             ; descendre l'origine bien plus bas pour que le corps VISIBLE
                                             ; se retrouve a hauteur des genoux.
int Property VTN_InventoryKey = 38 Auto ; L = DXScanCode 38 (0x26). ATTENTION : 76 (0x4C) = Numpad 5,
                                        ; PAS L - erreur de la valeur precedente, cause reelle du "L ne
                                        ; fonctionne pas" (2026-07-22, verifie sur la table DIK officielle).

Event OnInit()
    SetStage(10)
    ; Log d'activite dedie au mod (2026-07-20, demande de Kevin : pouvoir comprendre apres coup sans
    ; avoir a guetter une notification a l'ecran au bon moment). Debug.OpenUserLog/TraceUser sont des
    ; fonctions natives (verifiees dans Data\Scripts\Source\Debug.psc, aucun plugin necessaire) qui
    ; ecrivent dans un fichier separe du log Papyrus general - Documents\My Games\Skyrim Special
    ; Edition\Logs\Script\User\VTN.log. OpenUserLog "echoue si deja ouvert" (bool de retour ignore
    ; volontairement, pas une erreur si deja ouvert par VTN_PlayerAliasScript). Necessite
    ; bEnableLogging=1 (et idealement bEnableTrace=1) dans le [Papyrus] de l'ini du jeu, sinon aucune
    ; des deux fonctions n'ecrit quoi que ce soit, silencieusement.
    Debug.OpenUserLog("VTN")
    Debug.TraceUser("VTN", "VTN_MainQuestScript.OnInit")
    RegisterInventoryKey()
    RegisterFilterKey()
EndEvent

; Extrait dans sa propre fonction (2026-07-20, retour "la touche L ne fonctionne toujours pas") pour
; pouvoir etre rappelee depuis VTN_PlayerAliasScript.OnPlayerLoadGame() en plus d'OnInit. Cause
; probable : OnInit() d'un Quest ne s'execute qu'une seule fois pour de bon sur une sauvegarde donnee
; (jamais rejoue apres une simple recompilation du script) - Kevin teste sur une save continue depuis
; le debut du projet (reset via "set VTN_HasVelyn to 0" en console, jamais de nouvelle partie), donc
; RegisterForKey a tres probablement tourne une seule fois, potentiellement avant meme que la bonne
; valeur (76) ne soit en place. UnregisterForKey avant de reenregistrer pour eviter tout risque de
; double-inscription (comportement de reappel non documente dans Form.psc, prudence par defaut).
; Valeur du MCM si la globale existe, sinon le defaut du script. Une globale a 0 est ici une valeur
; legitime (offset nul), donc on teste l'existence de la globale, pas sa valeur.
float Function GetRideOffset(GlobalVariable akConfig, float afFallback)
    if akConfig
        return akConfig.GetValue()
    endif
    return afFallback
EndFunction

; Touche effectivement enregistree, pour detecter un rebind fait au MCM en cours de partie.
int _registeredKey = -1

; Relit la touche configuree et la reenregistre si elle a change. Appelee au chargement et
; periodiquement depuis VTN_PlayerAliasScript : c'est ce qui rend le rebind MCM effectif a chaud,
; sans script MCM dedie.
Function RefreshInventoryKeyIfChanged()
    int wanted = VTN_InventoryKey
    if VTN_CfgInventoryKey && VTN_CfgInventoryKey.GetValueInt() > 0
        wanted = VTN_CfgInventoryKey.GetValueInt()
    endif
    if wanted != _registeredKey
        RegisterInventoryKey()
    endif
EndFunction

Function RegisterInventoryKey()
    ; Reassigne la valeur en dur a chaque appel (2026-07-22) : sur une save existante (cas de Kevin,
    ; save continue depuis le debut du projet), la valeur de la propriete a ete figee a l'ancienne
    ; valeur erronee 76 (= Numpad 5) dans le co-save et n'est PAS mise a jour par le simple changement
    ; de l'ESP. On desenregistre aussi l'ancien code au cas ou il traine encore une inscription 76.
    UnregisterForKey(76)
    if _registeredKey > 0
        UnregisterForKey(_registeredKey) ; libere l'ancienne touche apres un rebind MCM
    endif

    ; La touche vient desormais du MCM (globale VTN_CfgInventoryKey, defaut 38 = L). On garde le
    ; defaut du script en repli si la globale est absente.
    VTN_InventoryKey = 38
    if VTN_CfgInventoryKey && VTN_CfgInventoryKey.GetValueInt() > 0
        VTN_InventoryKey = VTN_CfgInventoryKey.GetValueInt()
    endif

    Debug.TraceUser("VTN", "Touche inventaire (re)enregistree, code=" + VTN_InventoryKey)
    UnregisterForKey(VTN_InventoryKey)
    RegisterForKey(VTN_InventoryKey)
    _registeredKey = VTN_InventoryKey
EndFunction

; Touche effectivement enregistree pour le filtre manuel, -1 = aucune (fonctionnalite non liee/inerte).
int _registeredFilterKey = -1

Function RefreshFilterKeyIfChanged()
    int wanted = 0
    if VTN_CfgFilterKey
        wanted = VTN_CfgFilterKey.GetValueInt()
    endif
    if wanted != _registeredFilterKey
        RegisterFilterKey()
    endif
EndFunction

; Contrairement a RegisterInventoryKey, aucun defaut en dur : tant que VTN_CfgFilterKey vaut 0 (valeur
; par defaut de la globale), aucune touche n'est enregistree et la fonctionnalite reste totalement
; inerte - c'est le comportement voulu pour une option facultative qui necessite PapyrusUtil.
Function RegisterFilterKey()
    if _registeredFilterKey > 0
        UnregisterForKey(_registeredFilterKey)
        _registeredFilterKey = -1
    endif
    int wanted = 0
    if VTN_CfgFilterKey
        wanted = VTN_CfgFilterKey.GetValueInt()
    endif
    if wanted > 0
        Debug.TraceUser("VTN", "Touche filtre (re)enregistree, code=" + wanted)
        RegisterForKey(wanted)
        _registeredFilterKey = wanted
    endif
EndFunction

Function AcquireVelyn(int aiMode)
    if VTN_HasVelyn.GetValueInt() == 1
        Notify("VTN_MsgAlreadyHave")
        return
    endif

    Actor velynActor = GetVelynActor()
    if !velynActor
        Debug.TraceUser("VTN", "AcquireVelyn(mode=" + aiMode + ") : alias Velyn introuvable, abandon")
        return
    endif

    velynActor.SetGhost(true)
    ; Leve le gel de "decor" applique avant l'achat (elle etait figee sur son rocher au campement de
    ; Revus - voir VTN_VelynAliasScript). Sans ca elle resterait immobile une fois acquise.
    velynActor.SetDontMove(false)
    velynActor.SetActorValue("SpeedMult", 250.0)
    ; CarryWeight natif du moteur (distinct de VTN_MaxCarryWeight, notre plafond a nous, verifie
    ; dans OnItemAdded) : sans ca, l'UI de transfert grise tout objet avec du poids des que le
    ; CarryWeight natif (tres bas par defaut pour une creature) est depasse, AVANT meme qu'OnItemAdded
    ; ait la moindre chance de s'executer. Mis tres haut pour que seul VTN_MaxCarryWeight fasse foi.
    velynActor.SetActorValue("CarryWeight", 5000.0)
    velynActor.EvaluatePackage()

    VTN_HasVelyn.SetValueInt(1)
    Notify("VTN_MsgJoined")
    Debug.TraceUser("VTN", "AcquireVelyn(mode=" + aiMode + ") : terminee, VTN_HasVelyn=1")
EndFunction

Function DismissVelyn(bool abUninstall)
    Actor velynActor = GetVelynActor()
    if velynActor
        velynActor.RemoveAllItems(Game.GetPlayer(), true, true)
    endif
    VTN_HasVelyn.SetValueInt(0)
EndFunction

; Restaure le mouvement de Velyn apres un chargement de save. APPELEE DEPUIS L'ALIAS JOUEUR
; (VTN_PlayerAliasScript.OnPlayerLoadGame) et NON depuis l'alias de Velyn : OnPlayerLoadGame n'est
; envoye qu'aux alias remplis par le JOUEUR, pas a celui de Velyn - c'est pour ca que le handler place
; sur VTN_VelynAliasScript ne se declenchait jamais (2026-07-24, retour Kevin : "charger une save ne
; regle pas qu'elle descend de mon dos, et elle reste statique").
; Deux problemes traites :
;  - Piggyback ne persiste pas son etat d'attache au chargement (map C++ en memoire) : si Velyn etait
;    portee, elle ne l'est plus, mais le SetDontMove(true) pose a l'attache, LUI, a persiste dans la
;    save -> elle reste figee sur place. On le leve.
;  - Le moteur ne re-priorise pas la pile de packages au chargement -> EvaluatePackage force le suivi.
Function RestoreVelynMovementAfterLoad()
    if VTN_HasVelyn.GetValueInt() != 1
        return
    endif
    Actor velynActor = GetVelynActor()
    if !velynActor
        return
    endif
    if VTN_IsWaiting.GetValueInt() == 1
        velynActor.SetDontMove(true) ; en attente : on la garde figee (etat voulu)
    else
        velynActor.SetDontMove(false) ; leve un SetDontMove residuel (portage perdu au chargement)
        velynActor.EvaluatePackage()  ; force la reprise de VTN_FollowPackage
        Debug.TraceUser("VTN", "RestoreVelynMovementAfterLoad : suivi restaure")
    endif
EndFunction

; Affiche une notification LOCALISABLE : le texte vit dans un record Message de l'ESP (donc traduisible
; par la communaute via DSD, contrairement a une chaine codee dans le .pex). Resolu par EditorID via po3
; -> aucune propriete/fill a maintenir. Un Message sans flag MessageBox, affiche par Show(), apparait en
; notification de coin. (2026-07-25 : passage a une base anglaise localisable, option C.)
Function Notify(string asEditorID)
    Message m = PO3_SKSEFunctions.GetFormFromEditorID(asEditorID) as Message
    if m
        m.Show()
    endif
EndFunction

Actor Function GetVelynActor()
    ReferenceAlias velynAlias = GetAlias(1) as ReferenceAlias
    if velynAlias
        return velynAlias.GetReference() as Actor
    endif
    return None
EndFunction

; Ouverture DIFFEREE de l'inventaire (2026-07-22, retour "j'ai une reaction mais ca n'ouvre pas son
; inventaire"). Cause : OpenVelynInventory() est appelee depuis le fragment du Topic de dialogue, donc
; PENDANT que le menu de dialogue est encore ouvert - on ne peut pas empiler le menu conteneur par
; dessus, l'appel OpenInventory est ignore en silence. On ne peut pas non plus attendre dans le
; fragment (bloquerait la VM du dialogue). Solution : le fragment ne fait plus qu'armer un
; RegisterForSingleUpdate ; OnUpdate rouvre l'inventaire une fois qu'on est reellement sorti de tout
; menu (poll IsInMenuMode - robuste quel que soit le flag Goodbye du Topic).
Function OpenVelynInventory()
    RegisterForSingleUpdate(0.1)
EndFunction

Event OnUpdate()
    if Utility.IsInMenuMode()
        ; menu de dialogue (ou autre) encore ouvert : on repolle jusqu'a fermeture
        RegisterForSingleUpdate(0.1)
        return
    endif
    Actor velynActor = GetVelynActor()
    if velynActor
        Debug.TraceUser("VTN", "OpenVelynInventory : menu ferme, ouverture de l'inventaire de Velyn")
        velynActor.OpenInventory(true)
    endif
EndEvent

; Ouvre le menu de Velyn (2026-07-22). Remplace l'ancien Activate() : le log a prouve qu'Activate() sur
; Velyn n'ouvre AUCUN dialogue (netch = race creature sans VoiceType, le moteur ne declenche pas le menu
; de dialogue du joueur). On passe donc par un MessageBox (record VTN_VelynMenu), fiable sur n'importe
; quel acteur. Meme menu declenche par la touche L (ici) et par l'activation directe E (OnActivate dans
; VTN_VelynAliasScript).
Event OnKeyDown(int keyCode)
    if keyCode == VTN_InventoryKey
        Debug.TraceUser("VTN", "Touche inventaire detectee (keyCode=" + keyCode + ", VTN_HasVelyn=" + VTN_HasVelyn.GetValueInt() + ", IsInMenuMode=" + Utility.IsInMenuMode() + ")")
        if VTN_HasVelyn.GetValueInt() == 1 && !Utility.IsInMenuMode()
            ShowVelynMenu()
        endif
    elseif _registeredFilterKey > 0 && keyCode == _registeredFilterKey
        Debug.TraceUser("VTN", "Touche filtre detectee (keyCode=" + keyCode + ")")
        if VTN_HasVelyn.GetValueInt() == 1 && !Utility.IsInMenuMode()
            VTN_HarvestScript harvest = (self as Quest) as VTN_HarvestScript
            if harvest
                harvest.HandleFilterKeyPress()
            endif
        endif
    endif
EndEvent

; Menu MessageBox : Show() est bloquant et renvoie l'index du bouton choisi (0 = 1er bouton). Appelable
; depuis OnKeyDown (hors menu) comme depuis OnActivate. L'ouverture de l'inventaire reste differee
; (OpenVelynInventory) car le MessageBox est encore techniquement un menu au moment ou Show() rend la
; main sur certaines versions - le poll IsInMenuMode d'OnUpdate couvre ce cas.
Function ShowVelynMenu()
    if VTN_HasVelyn.GetValueInt() != 1
        return
    endif

    ; Proximite requise (2026-07-22, demande de Kevin) : si Velyn attend a l'autre bout de Bordeciel, la
    ; touche L ne doit PAS ouvrir son menu a distance - il faut aller la rejoindre pour lui redire de
    ; suivre. Is3DLoaded couvre le cas "autre worldspace / cellule dechargee", ou GetDistance n'est pas
    ; fiable (piege documente journal 1) ; le test de distance couvre le cas "meme zone mais trop loin".
    Actor velynActor = GetVelynActor()
    if !velynActor || !velynActor.Is3DLoaded() || velynActor.GetDistance(Game.GetPlayer()) > VTN_MenuRange
        Notify("VTN_MsgNotNearby")
        Debug.TraceUser("VTN", "ShowVelynMenu : Velyn hors de portee (menu non ouvert)")
        return
    endif

    ; Portage disponible SEULEMENT si Piggyback est installe (DLL present -> IsInstalled() renvoie true ;
    ; absent -> la native n'est pas enregistree et renvoie false) ET non desactive au MCM. Sinon on affiche
    ; la variante de menu SANS l'option "Monte sur mon dos" (demande Kevin 2026-07-25 : ne pas proposer une
    ; option inutilisable). Les indices de la variante sont ensuite remappes sur ceux du menu complet
    ; (l'emplacement du portage, index 3, est simplement absent -> tout ce qui suit est decale de 1).
    bool hasRide = Piggyback.IsInstalled() && !(VTN_CfgRideEnabled && VTN_CfgRideEnabled.GetValueInt() == 0)
    int choice
    if hasRide
        choice = VTN_VelynMenu.Show()
    else
        choice = VTN_VelynMenuNoRide.Show()
        if choice >= 3
            choice += 1 ; remappe : 3->4 (Comment vas-tu), 4->5 (Ne rien faire) - saute l'emplacement portage
        endif
    endif
    Debug.TraceUser("VTN", "ShowVelynMenu : hasRide=" + hasRide + " choix=" + choice)
    if choice == 0
        OpenVelynInventory()
    elseif choice == 1
        ; Si elle est portee, la faire descendre AVANT de la mettre en attente (2026-07-22) : sinon
        ; Piggyback continue de la coller au dos a chaque frame et "attends ici" n'a aucun effet visible.
        if Piggyback.IsAttached(velynActor)
            Piggyback.Detach(velynActor)
            velynActor.SetDontMove(false)
            Utility.Wait(0.9) ; laisse la transition de sortie se terminer avant de la figer sur place
        endif
        VTN_IsWaiting.SetValueInt(1)
        Notify("VTN_MsgWaiting")
    elseif choice == 2
        VTN_IsWaiting.SetValueInt(0)
        Notify("VTN_MsgFollowing")
    elseif choice == 3
        ToggleRide(velynActor)
    elseif choice == 4
        ShowStatus(velynActor)
    endif
EndFunction

; Ecran d'etat : rend visibles la progression et l'energie, qui sinon resteraient invisibles au joueur.
;
; ⚑ LOCALISATION PARTICULIERE (2026-07-26, Kevin : "sur la version FR, quelque chose n'est pas traduit").
; Ce texte est construit LIGNE PAR LIGNE avec des valeurs dynamiques (niveau, charge, XP, energie), il ne
; peut donc pas etre un record Message, et DSD ne peut pas l'atteindre : DSD ne traduit que les chaines
; de l'ESP, jamais celles compilees dans un .pex.
; Solution retenue : on lit la LANGUE DU JEU au runtime via Utility.GetINIString("sLanguage:General")
; (natif SKSE, verifie dans Utility.psc) et on choisit les libelles en consequence. Aucun bricolage cote
; FOMOD, et un joueur francais est servi meme s'il installe la version anglaise du mod.
; Les autres langues retombent sur l'anglais : pour en ajouter une, completer IsFrench/les libelles.
bool Function IsFrenchGame()
    string lang = Utility.GetINIString("sLanguage:General")
    return StringUtil.Find(lang, "FRENCH") >= 0 || StringUtil.Find(lang, "French") >= 0 || StringUtil.Find(lang, "french") >= 0
EndFunction

Function ShowStatus(Actor velynActor)
    ; Ce script EST celui de la quete : pour joindre un script frere attache au meme objet, on repasse
    ; par le type de base (self -> Quest -> l'autre script).
    VTN_ProgressionScript prog = (self as Quest) as VTN_ProgressionScript
    if !prog
        Notify("VTN_MsgStatusUnavailable")
        return
    endif

    float carried = velynActor.GetTotalItemWeight()
    string text = ""

    if IsFrenchGame()
        text = "Velyn - niveau " + prog.GetLevel() + "\n"
        text += "Charge : " + (carried as int) + " / " + (prog.GetCapacity() as int) + "\n"
        if prog.GetLevel() >= prog.VTN_MaxLevel
            text += "Experience : niveau maximum atteint\n"
        else
            text += "Experience : encore " + (prog.GetXPToNextLevel() as int) + " avant le niveau suivant\n"
        endif
        if prog.IsHarvestUnlocked()
            text += "Energie de recolte : " + (prog.VTN_Energy.GetValue() as int) + " / " + (prog.GetMaxEnergy() as int) + " points"
        else
            text += "Recolte : elle l'apprendra au niveau " + prog.VTN_HarvestUnlockLevel
        endif
    else
        text = "Velyn - level " + prog.GetLevel() + "\n"
        text += "Load: " + (carried as int) + " / " + (prog.GetCapacity() as int) + "\n"
        if prog.GetLevel() >= prog.VTN_MaxLevel
            text += "Experience: maximum level reached\n"
        else
            text += "Experience: " + (prog.GetXPToNextLevel() as int) + " to go before the next level\n"
        endif
        if prog.IsHarvestUnlocked()
            text += "Harvest energy: " + (prog.VTN_Energy.GetValue() as int) + " / " + (prog.GetMaxEnergy() as int) + " points"
        else
            text += "Harvest: she will learn it at level " + prog.VTN_HarvestUnlockLevel
        endif
    endif

    Debug.MessageBox(text)
EndFunction

; Bascule le rig "sur le dos" via le plugin SKSE Piggyback (attache per-frame). OPTIONNEL : si le DLL
; n'est pas installe, l'appel natif echoue simplement et on le dit au joueur - le mode de deplacement
; par defaut reste le suivi par IA native, qui n'a besoin d'aucun plugin.
; SetDontMove pendant l'attache : sans ca, VTN_FollowPackage continuerait a vouloir la deplacer et se
; battrait contre le repositionnement per-frame du plugin (Piggyback doit etre le SEUL pilote).
Function ToggleRide(Actor velynActor)
    if VTN_CfgRideEnabled && VTN_CfgRideEnabled.GetValueInt() == 0
        Notify("VTN_MsgRideDisabled")
        return
    endif

    if Piggyback.IsAttached(velynActor)
        Piggyback.Detach(velynActor)
        velynActor.SetDontMove(false)
        ; Force la re-evaluation de la pile de packages en descendant du dos (2026-07-23, retour Kevin :
        ; elle vadrouillait au lieu de reprendre le suivi apres "descends"). Meme cause que le bug de
        ; chargement : sans EvaluatePackage, le moteur ne repriorise pas VTN_FollowPackage et elle retombe
        ; sur VTN_WanderPackage. On ne le fait que si elle n'est pas en attente (une Velyn en attente reste
        ; volontairement figee).
        if VTN_IsWaiting.GetValueInt() == 0
            velynActor.EvaluatePackage()
        endif
        Notify("VTN_MsgDismount")
        Debug.TraceUser("VTN", "Piggyback : detache")
    else
        float ox = GetRideOffset(VTN_CfgRideOffsetX, VTN_RideOffsetX)
        float oy = GetRideOffset(VTN_CfgRideOffsetY, VTN_RideOffsetY)
        float oz = GetRideOffset(VTN_CfgRideOffsetZ, VTN_RideOffsetZ)
        if Piggyback.Attach(velynActor, Game.GetPlayer(), VTN_RideNode, ox, oy, oz, true)
            velynActor.SetDontMove(true)
            ; Memorise l'offset applique pour detecter, au tick, un changement fait au MCM (voir
            ; RefreshRideOffsetIfChanged) et l'appliquer a chaud sans la faire descendre.
            _appliedOffsetX = ox
            _appliedOffsetY = oy
            _appliedOffsetZ = oz
            Notify("VTN_MsgMount")
            Debug.TraceUser("VTN", "Piggyback : attachee sur " + VTN_RideNode)
        else
            Notify("VTN_MsgNoPiggyback")
            Debug.TraceUser("VTN", "Piggyback : Attach a echoue (DLL absent ?)")
        endif
    endif
EndFunction

; Reglage de position "a chaud" (2026-07-23, retour Kevin : "changer sa position ne change pas quand on
; la porte deja"). Appelee depuis le tick de VTN_PlayerAliasScript : si Velyn est portee et qu'un
; curseur de position a bouge au MCM, on pousse le nouvel offset au plugin via SetOffset - qui met a
; jour la position SANS detacher (pas de descente/remontee). Aucun effet si elle n'est pas portee.
float _appliedOffsetX = 0.0
float _appliedOffsetY = 0.0
float _appliedOffsetZ = 0.0

Function RefreshRideOffsetIfChanged()
    Actor velynActor = GetVelynActor()
    if !velynActor || !Piggyback.IsAttached(velynActor)
        return
    endif
    float ox = GetRideOffset(VTN_CfgRideOffsetX, VTN_RideOffsetX)
    float oy = GetRideOffset(VTN_CfgRideOffsetY, VTN_RideOffsetY)
    float oz = GetRideOffset(VTN_CfgRideOffsetZ, VTN_RideOffsetZ)
    if ox != _appliedOffsetX || oy != _appliedOffsetY || oz != _appliedOffsetZ
        Piggyback.SetOffset(velynActor, ox, oy, oz)
        _appliedOffsetX = ox
        _appliedOffsetY = oy
        _appliedOffsetZ = oz
        Debug.TraceUser("VTN", "Piggyback : offset mis a jour a chaud (" + ox + ", " + oy + ", " + oz + ")")
    endif
EndFunction
