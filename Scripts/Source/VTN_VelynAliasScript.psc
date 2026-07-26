Scriptname VTN_VelynAliasScript extends ReferenceAlias

Quest Property VTN_MainQuest Auto
GlobalVariable Property VTN_HasVelyn Auto
GlobalVariable Property VTN_IsWaiting Auto
; Repli utilise uniquement si le script de progression est indisponible : la capacite reelle est
; desormais DYNAMIQUE (100 + 10 par niveau), calculee par VTN_ProgressionScript.GetCapacity().
float Property VTN_MaxCarryWeight = 100.0 Auto

; Cadence du scan de recolte. OnUpdate tourne a 0.1 s (necessaire pour le reste), mais scanner
; l'environnement 10 fois par seconde serait absurde -> on ne le fait qu'un tick sur 30, soit ~3 s.
int Property VTN_HarvestTickInterval = 30 Auto
int _harvestTick = 0

; Activation directe (E) sur Velyn -> meme menu MessageBox que la touche L (2026-07-22). Peut ne pas se
; declencher si le netch n'offre pas d'invite d'activation au reticule (comportement de race creature) ;
; dans ce cas la touche L reste le moyen fiable. Sans effet de bord si l'evenement ne se produit jamais.
Event OnActivate(ObjectReference akActionRef)
    if akActionRef == Game.GetPlayer() && VTN_HasVelyn.GetValueInt() == 1
        (VTN_MainQuest as VTN_MainQuestScript).ShowVelynMenu()
    endif
EndEvent

bool _wasSneaking = false
bool _isFrozen = false ; etat "gelee sur place" (SetDontMove) pendant l'attente, voir OnUpdate
bool _frozenOnRock = false ; gel de DECOR avant l'achat (posee sur son rocher), voir OnUpdate

; Position exacte du rocher au campement de Revus, relevee en jeu par Kevin (player.getpos debout
; dessus : 69110.32 / 29798.49 / 1180.55), +15 en Z pour qu'elle levite au lieu d'etre encastree.
; Exposees en proprietes : ajustables sans retoucher le code si le rendu ne convient pas.
float Property VTN_RockX = 69110.32 Auto
float Property VTN_RockY = 29798.49 Auto
float Property VTN_RockZ = 1195.55 Auto
; Orientation (degres, cap Z). 180 = demi-tour par rapport a son placement d'origine, ou elle regardait
; au nord alors que Kevin la veut tournee dans l'autre sens.
float Property VTN_RockAngleZ = 180.0 Auto

Event OnInit()
    RegisterForUpdate(0.1)
EndEvent

; NB : PAS de OnPlayerLoadGame ici - cet event n'est envoye qu'aux alias remplis par le JOUEUR, jamais a
; celui de Velyn (verifie empiriquement : le handler place ici ne se declenchait jamais). La restauration
; du mouvement au chargement (suivi/gel apres portage) est donc pilotee depuis l'alias joueur, voir
; VTN_PlayerAliasScript.OnPlayerLoadGame -> VTN_MainQuestScript.RestoreVelynMovementAfterLoad().

; En temps normal, Velyn est une créature ordinaire (détection naturelle, ni forcée ni masquée) :
; inoffensive de par son Aggression/Confidence/faction, mais visible comme n'importe quelle créature.
; Dès que le joueur passe en discrétion, elle devient totalement indétectable pour ne jamais le trahir.
Event OnUpdate()
    ; --- AVANT l'achat : Velyn est un DECOR STATIQUE, posee sur un rocher du campement de Revus. -------
    ; Decision Kevin (2026-07-25) apres de nombreux essais infructueux : la faire vadrouiller ou suivre
    ; Revus avant l'achat ne fonctionne pas (sandbox ET suivi cible sur Revus tous deux inoperants sur
    ; cette creature - voir le journal pour la liste complete de ce qui a ete elimine). On assume donc
    ; qu'elle reste sagement posee la ou Revus la garde : coherent, et sans dette technique.
    ; ⚑⚑ DECOUVERTE FINALE (2026-07-25) : elle N'ETAIT PAS immobile, elle DERIVAIT - tres lentement.
    ; Mesure en jeu par Kevin sur une partie neuve : placee en (69110, 29798, 1195), retrouvee en
    ; (69005, 30052, 1167), soit ~275 unites plus loin et 28 plus bas. A ~9 u/s (vitesse d'un netch a
    ; l'echelle 0.15), c'est imperceptible sur quelques secondes mais tres visible sur plusieurs minutes.
    ; => TOUS les "elle ne bouge pas" de cette session etaient en realite "elle bouge trop lentement pour
    ; que ca se voie". L'IA de race la fait bien deriver, meme sans aucun package.
    ; Pour un decor statique pose sur un rocher, il faut donc la GELER ACTIVEMENT : couper les packages ne
    ; suffit pas (meme constat que pour l'etat "Attends ici", voir plus bas).
    ; SetDontMove est leve a l'achat (VTN_MainQuestScript.AcquireVelyn) et au chargement d'une save
    ; (RestoreVelynMovementAfterLoad).
    if VTN_HasVelyn.GetValueInt() != 1
        if !_frozenOnRock
            Actor preVelyn = GetReference() as Actor
            ; ⚠️ VOLONTAIREMENT PAS de test Is3DLoaded() ici (2026-07-25) : exiger le chargement du modele
            ; faisait faire le repositionnement PILE au moment ou le joueur arrive -> teleportation visible
            ; ("c'est bizarre de voir ca", retour Kevin). Sans ce test, l'operation a lieu des le demarrage
            ; de la partie, alors qu'elle est hors de portee - donc invisible. SetPosition/SetAngle
            ; fonctionnent sur une reference dont la 3D n'est pas chargee.
            if preVelyn
                preVelyn.StopTranslation()
                ; ⚑ REPOSITIONNEMENT OBLIGATOIRE avant de geler. La position d'une reference PERSISTANTE
                ; est memorisee d'une session a l'autre : une fois qu'elle a derive, le placement de l'ESP
                ; ne s'applique PLUS, et un simple gel la clouerait la ou elle a fini. Constate en jeu :
                ; gelee en (69016, 30043, 1168) au lieu du rocher (69110, 29798, 1195).
                preVelyn.SetPosition(VTN_RockX, VTN_RockY, VTN_RockZ)
                ; Orientation : elle regardait au nord, Kevin la veut tournee de 180 degres. SetAngle
                ; attend des DEGRES en Papyrus (le record ESP, lui, stocke des radians - ne pas confondre).
                preVelyn.SetAngle(0.0, 0.0, VTN_RockAngleZ)
                preVelyn.SetDontMove(true)
                _frozenOnRock = true
                Debug.TraceUser("VTN", "Pre-achat : Velyn replacee sur son rocher et gelee. Pos=" + preVelyn.GetPositionX() + "," + preVelyn.GetPositionY() + "," + preVelyn.GetPositionZ() + " AngleZ=" + preVelyn.GetAngleZ())
            endif
        endif
        return
    endif
    ; Achetee : on s'assure que le gel de decor est bien leve (filet de securite si AcquireVelyn a ete
    ; court-circuite, par ex. via le global de debug).
    if _frozenOnRock
        Actor justBought = GetReference() as Actor
        if justBought
            justBought.SetDontMove(false)
        endif
        _frozenOnRock = false
    endif

    if VTN_HasVelyn.GetValueInt() == 1
        Actor velynActor = GetReference() as Actor
        if velynActor
            Actor playerRef = Game.GetPlayer()
            bool isSneaking = playerRef.IsSneaking()
            if isSneaking != _wasSneaking
                if isSneaking
                    PO3_SKSEFunctions.PreventActorDetection(velynActor)
                else
                    PO3_SKSEFunctions.ResetActorDetection(velynActor)
                endif
                _wasSneaking = isSneaking
            endif

            ; Filet de securite independant des relations de faction (peu fiables avec des centaines
            ; de mods qui definissent chacun leurs propres factions hostiles) : si un PNJ hostile
            ; arrive quand meme a l'engager, on coupe le combat des qu'on le detecte plutot que de
            ; compter uniquement sur PlayerFaction pour empecher le ciblage en amont.
            if velynActor.IsInCombat()
                velynActor.StopCombat()
                velynActor.StopCombatAlarm()
            endif

            ; ============================================================================================
            ; ATTENTE : GEL EXPLICITE (2026-07-22, retour "si je la fais attendre elle zigzag partout")
            ; ============================================================================================
            ; Cause du zigzag identifiee dans les records : pendant l'attente, VTN_FollowPackage ET
            ; VTN_WanderPackage sont tous deux desactives (conditionnes sur VTN_IsWaiting == 0) et le
            ; script ne pilotait plus rien -> PLUS AUCUN package actif -> le moteur retombe sur l'IA par
            ; defaut de la race netch, qui derive/vagabonde toute seule. Couper nos packages ne suffit
            ; donc pas : il faut la figer activement. SetDontMove empeche le moteur de la deplacer, quelle
            ; que soit l'IA qui essaie. StopTranslation tue au passage un TranslateTo encore en vol.
            ; --- M3 : recolte automatique (cadencee, voir VTN_HarvestTickInterval) ---
            _harvestTick += 1
            if _harvestTick >= VTN_HarvestTickInterval
                _harvestTick = 0
                VTN_HarvestScript harvest = VTN_MainQuest as VTN_HarvestScript
                if harvest
                    harvest.TryHarvest(velynActor)
                endif
            endif

            if VTN_IsWaiting.GetValueInt() == 1
                if !_isFrozen
                    velynActor.StopTranslation()
                    velynActor.SetDontMove(true)
                    _isFrozen = true
                endif
                return
            elseif _isFrozen
                velynActor.SetDontMove(false)
                _isFrozen = false
            endif

            ; ============================================================================================
            ; SUIVI SCRIPT (TranslateTo) : SUPPRIME le 2026-07-22.
            ; ============================================================================================
            ; Historique : 5 modeles successifs (v1 vadrouille -> v2 orbite -> v3 maintien de distance ->
            ; v4/v5 ancrage sur le cap) ont tous echoue au test. Retour de Kevin sur le v5 : "il continue
            ; de se teleporter partout", "pas rig a la frame pres", "quand je monte ou descend il passe a
            ; travers le sol".
            ; Cause de fond (diagnostic 2026-07-22) : on forcait la position d'une CREATURE NON-TEAMMATE
            ; par script, ce qui (a) ignore le navmesh et le sol - d'ou la traversee du decor en denivele,
            ; (b) se battait en permanence contre les DEUX packages IA natifs actifs en parallele. Papyrus
            ; ne tourne au mieux qu'a 10-20 Hz : ce modele ne pouvait de toute facon jamais etre lisse.
            ; A la place :
            ;   - deplacement au sol -> laisse a VTN_FollowPackage (IA native, navigue le navmesh, ne
            ;     traverse pas le sol) ;
            ;   - rig "sur le dos" frame-perfect -> plugin SKSE Piggyback (attache moteur per-frame),
            ;     voir docs/02-plugin-rig-moteur.md. Piggyback doit etre le SEUL pilote quand il est actif,
            ;     sinon un suivi script rivaliserait avec l'attache et provoquerait du jitter.
            ; Ne pas reintroduire de pilotage de position par script ici.
        endif
    endif
EndEvent

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    Actor velynActor = GetReference() as Actor
    if velynActor && velynActor.GetTotalItemWeight() > GetCapacity()
        velynActor.RemoveItem(akBaseItem, aiItemCount, true, akSourceContainer)
        Message m = PO3_SKSEFunctions.GetFormFromEditorID("VTN_MsgCannotCarryMore") as Message
        if m
            m.Show()
        endif
    endif
EndEvent

; Capacite reelle = celle de la progression, avec repli sur l'ancienne valeur fixe si le script de
; progression n'est pas joignable (ne jamais laisser la capacite a 0, ce qui bloquerait tout transfert).
float Function GetCapacity()
    VTN_ProgressionScript prog = VTN_MainQuest as VTN_ProgressionScript
    if prog
        return prog.GetCapacity()
    endif
    return VTN_MaxCarryWeight
EndFunction
