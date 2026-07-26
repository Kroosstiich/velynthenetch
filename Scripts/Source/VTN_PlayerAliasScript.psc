Scriptname VTN_PlayerAliasScript extends ReferenceAlias

Quest Property VTN_MainQuest Auto
GlobalVariable Property VTN_HasVelyn Auto
GlobalVariable Property VTN_DebugAcquire Auto
GlobalVariable Property VTN_IsWaiting Auto

; --- XP de transport (M3) -------------------------------------------------------------------------
; L'XP est gagnee en TRANSPORTANT reellement : proportionnelle a la distance parcourue ET au taux de
; charge de Velyn. Deux garde-fous voulus des la conception (Kevin) :
;   - rien ne s'accumule a l'arret : poser 300 unites sur elle et rester a la taverne ne rapporte rien ;
;   - rien ne s'accumule via prendre/donner : ce serait trivial a exploiter.
float Property VTN_XPPerUnitDistance = 0.002 Auto
; Au-dela de cette distance sur un seul tick, c'est un voyage rapide ou une teleportation, pas de la
; marche : on ignore, sinon un aller-retour a l'autre bout de Bordeciel donnerait des niveaux gratuits.
float Property VTN_MaxDistancePerTick = 2000.0 Auto
; Reglage MCM (Bloc 3, 2026-07-23) : remplace VTN_XPPerUnitDistance si defini (>0), pour les joueurs qui
; trouvent la progression de transport trop lente/rapide.
GlobalVariable Property VTN_CfgXPTransportRate Auto

float _lastX = 0.0
float _lastY = 0.0
bool _hasLastPos = false

int _unloadedTicks = 0
bool _reconnecting = false

Event OnInit()
    Debug.OpenUserLog("VTN") ; voir VTN_MainQuestScript.OnInit pour le detail (log dedie au mod)
    RegisterForSingleUpdate(3.0)
EndEvent

; Reaction quasi instantanee a un changement de scene (porte, voyage rapide, tp console d'un autre
; mod...) - c'est le cas ou l'orbite (VTN_VelynAliasScript) ne peut pas suivre puisqu'un chargement
; est instantane, aucune boucle Papyrus ne peut anticiper l'evenement avant qu'il n'arrive. Existence
; verifiee directement dans ReferenceAlias.psc avant utilisation (ni l'un ni l'autre n'a besoin d'un
; RegisterFor, ce sont de simples Event a implementer).
Event OnCellAttach()
    ReconnectVelynIfLost()
EndEvent

Event OnPlayerFastTravelEnd(float afTravelGameTimeHours)
    ReconnectVelynIfLost()
EndEvent

; Reenregistre la touche d'inventaire (L) a chaque chargement de sauvegarde (2026-07-20, retour "la
; touche L ne fonctionne toujours pas") - OnPlayerLoadGame existe sur ReferenceAlias (verifie dans
; ReferenceAlias.psc) mais PAS sur Quest, donc l'appel reel doit rester dans VTN_MainQuestScript
; (RegisterForKey/OnKeyDown exigent un script qui etend Form, piege #8) ; ce hook-ci se contente de le
; declencher a chaque chargement plutot qu'une seule fois via Quest.OnInit(), qui ne rejoue jamais sur
; une sauvegarde existante apres une simple recompilation du script.
Event OnPlayerLoadGame()
    Debug.OpenUserLog("VTN") ; echoue silencieusement si deja ouvert, aucun risque a le rappeler ici
    Debug.TraceUser("VTN", "OnPlayerLoadGame")
    (VTN_MainQuest as VTN_MainQuestScript).RegisterInventoryKey()
    (VTN_MainQuest as VTN_MainQuestScript).RegisterFilterKey()
    ; Restaure le mouvement de Velyn (suivi/gel) au chargement : c'est ICI que ca doit vivre car
    ; OnPlayerLoadGame ne part qu'aux alias remplis par le joueur, pas a celui de Velyn.
    (VTN_MainQuest as VTN_MainQuestScript).RestoreVelynMovementAfterLoad()
EndEvent

Event OnUpdate()
    ; VTN_DebugAcquire : declencheur de test console (setglobalvalue), remplace par le vrai
    ; parcours d'acquisition en M2 (dialogue/adoption/oeuf).
    if VTN_DebugAcquire.GetValueInt() == 1
        VTN_DebugAcquire.SetValueInt(0)
        (VTN_MainQuest as VTN_MainQuestScript).AcquireVelyn(0)
    endif

    ; Filet de secours au cas ou OnCellAttach/OnPlayerFastTravelEnd manqueraient un cas - avec
    ; l'orbite, Velyn ne devrait plus jamais s'eloigner "en marchant" pendant le jeu normal (elle est
    ; repositionnee par rapport au joueur en continu, jamais en poursuite), donc ce tick ne devrait
    ; quasiment plus jamais avoir a agir.
    ReconnectVelynIfLost()

    ; Rend effectif a chaud un rebind de touche fait dans le MCM (aucun script MCM dedie n'est utilise).
    (VTN_MainQuest as VTN_MainQuestScript).RefreshInventoryKeyIfChanged()
    (VTN_MainQuest as VTN_MainQuestScript).RefreshFilterKeyIfChanged()
    ; Applique a chaud un changement de position Piggyback fait au MCM (si Velyn est portee).
    (VTN_MainQuest as VTN_MainQuestScript).RefreshRideOffsetIfChanged()

    ; --- M3 : progression ---
    VTN_ProgressionScript prog = VTN_MainQuest as VTN_ProgressionScript
    if prog
        prog.ProcessDebugRequests()
        prog.UpdateEnergy()
        AccrueTransportXP(prog)
    endif

    RegisterForSingleUpdate(3.0)
EndEvent

; XP proportionnelle a (distance parcourue x taux de charge). Une Velyn a moitie vide rapporte peu,
; bien chargee rapporte plus : cela recompense l'usage prevu du compagnon.
Function AccrueTransportXP(VTN_ProgressionScript prog)
    if VTN_HasVelyn.GetValueInt() != 1
        return
    endif
    Actor playerRef = GetReference() as Actor
    if !playerRef
        return
    endif

    float x = playerRef.GetPositionX()
    float y = playerRef.GetPositionY()
    if !_hasLastPos
        _lastX = x
        _lastY = y
        _hasLastPos = true
        return
    endif

    float dx = x - _lastX
    float dy = y - _lastY
    _lastX = x
    _lastY = y
    float distance = Math.sqrt(dx * dx + dy * dy)

    ; Immobile, ou saut de position (chargement / voyage rapide / tcl) : on ne credite rien.
    if distance < 1.0 || distance > VTN_MaxDistancePerTick
        return
    endif

    Actor velynActor = (VTN_MainQuest as VTN_MainQuestScript).GetVelynActor()
    if !velynActor
        return
    endif

    float capacity = prog.GetCapacity()
    if capacity <= 0.0
        return
    endif
    float loadRatio = velynActor.GetTotalItemWeight() / capacity
    if loadRatio <= 0.0
        return ; elle ne porte rien : elle ne "travaille" pas
    endif
    if loadRatio > 1.0
        loadRatio = 1.0
    endif

    float rate = VTN_XPPerUnitDistance
    if VTN_CfgXPTransportRate && VTN_CfgXPTransportRate.GetValue() > 0.0
        rate = VTN_CfgXPTransportRate.GetValue()
    endif
    prog.AddXP(distance * rate * loadRatio)
EndFunction

; Recuperation des objets recoltes (M3). MineOreScript.giveOre() donne le minerai AU JOUEUR (code en
; dur dans le script vanilla) : pendant une recolte, on transfere donc immediatement a Velyn ce que le
; joueur vient de recevoir. Passer par cet evenement gere aussi les GEMMES ALEATOIRES des listes de
; butin, qu'on ne pourrait pas predire a l'avance.
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    VTN_HarvestScript harvest = VTN_MainQuest as VTN_HarvestScript
    if !harvest || !harvest.IsRedirecting()
        return
    endif

    ; FILTRE PAR TYPE (2026-07-22, retour "je crois qu'elle m'a pique une amulette et un anneau").
    ; Defaut de conception initial : la fenetre de redirection capturait TOUT ce que le joueur recevait
    ; pendant ~0.5 s, donc aussi ce qu'il ramassait lui-meme. On ne redirige plus que des RESSOURCES :
    ;   30 = INGR (ingredients, ce que donne la flore)   32 = MISC (minerais, lingots, gemmes)
    ; Les bijoux et armes sont des ARMO/WEAP -> desormais exclus, ils restent chez le joueur.
    if !akBaseItem
        return
    endif
    int itemType = akBaseItem.GetType()
    if itemType != 30 && itemType != 32
        Debug.TraceUser("VTN", "Redirection ignoree (type " + itemType + ") : " + akBaseItem.GetName())
        return
    endif
    Actor velynActor = (VTN_MainQuest as VTN_MainQuestScript).GetVelynActor()
    if !velynActor
        return
    endif
    Actor playerRef = GetReference() as Actor
    if playerRef
        playerRef.RemoveItem(akBaseItem, aiItemCount, true, velynActor) ; true = silencieux
        Debug.TraceUser("VTN", "Recolte redirigee vers Velyn : " + akBaseItem.GetName() + " x" + aiItemCount)
    endif
EndEvent

; Bug corrige (2026-07-20, retour "elle se tp pas meme hyper loin") : GetDistance() exige que les deux
; refs soient dans le meme interieur/worldspace pour donner un resultat fiable (doc native,
; ObjectReference.psc). Si Velyn est laissee derriere en franchissant une limite de worldspace (ex.
; Solstheim <-> continent) ou reste simplement desimulee assez longtemps, la distance mesuree peut ne
; jamais depasser le seuil meme si elle est en realite tres loin - le filet de securite restait alors
; silencieusement inactif. Is3DLoaded() sert de 2e declencheur, independant de la distance.
; Seuil abaisse de 14000 a 2000 (2026-07-20, suite au passage a l'orbite) : le seuil eleve ne servait
; qu'a laisser de la marge au rattrapage anime avant de basculer en tp, un concept qui n'existe plus
; avec l'orbite (elle ne s'eloigne plus jamais par simple retard de poursuite) - seul un vrai
; changement de scene la laisse desormais derriere, donc plus besoin de cette marge.
Function ReconnectVelynIfLost()
    ; Ne JAMAIS reconnecter tant qu'elle attend (VTN_IsWaiting==1). Sinon, laisser Velyn en attente a
    ; Bordeciel puis partir a Solstheim la desimule -> _unloadedTicks atteint le seuil (ou OnCellAttach/
    ; OnPlayerFastTravelEnd se declenchent a l'arrivee) -> elle serait teleportee jusqu'au joueur, ce qui
    ; casse l'attente. En attente, elle DOIT rester exactement ou on l'a laissee. Des que le joueur lui
    ; redit de suivre (VTN_IsWaiting=0), la reconnexion reprend au tick suivant et la ramene.
    if _reconnecting || VTN_HasVelyn.GetValueInt() != 1 || VTN_IsWaiting.GetValueInt() == 1
        return
    endif
    Actor velynActor = (VTN_MainQuest as VTN_MainQuestScript).GetVelynActor()
    Actor playerRef = GetReference() as Actor
    if !velynActor || !playerRef
        return
    endif

    if !velynActor.Is3DLoaded()
        _unloadedTicks += 1
    else
        _unloadedTicks = 0
    endif

    if velynActor.GetDistance(playerRef) > 2000.0 || _unloadedTicks >= 3
        _reconnecting = true
        Debug.TraceUser("VTN", "Velyn perdue, reconnexion (distance=" + velynActor.GetDistance(playerRef) + ", unloadedTicks=" + _unloadedTicks + ")")
        ; Fondu plutot qu'un MoveTo brut - meme pattern que le vanilla DLC2SummonDremoraMerchantScript.psc.
        velynActor.Disable(true)
        Utility.Wait(1.0)
        velynActor.MoveTo(playerRef, 60.0, 60.0, 0.0, false)
        velynActor.Enable(true)
        _unloadedTicks = 0
        _reconnecting = false
    endif
EndFunction
