Scriptname VTN_ProgressionScript extends Quest

; ==================================================================================================
; M3 - Bloc 1 : progression de Velyn (XP, niveaux, capacite) + energie de recolte.
; ==================================================================================================
; Script SEPARE de VTN_MainQuestScript (2e script sur la meme quete) pour garder les responsabilites
; distinctes : celui-ci ne gere que l'ETAT de progression et les regles associees. Les declencheurs
; vivent ailleurs (transport -> VTN_PlayerAliasScript, recolte -> VTN_VelynAliasScript) et appellent
; les fonctions publiques d'ici.
;
; Toutes les valeurs de reglage sont des Property : elles seront exposees dans le MCM au Bloc 3, donc
; ne jamais coder un nombre en dur dans la logique ci-dessous.

GlobalVariable Property VTN_Level Auto
GlobalVariable Property VTN_XP Auto
GlobalVariable Property VTN_Energy Auto
GlobalVariable Property VTN_HasVelyn Auto
GlobalVariable Property VTN_DebugAddXP Auto

; --- Reglages pilotes par le MCM ------------------------------------------------------------------
; Ces globales sont ecrites DIRECTEMENT par MCM Helper (sourceType GlobalValue). Consequence voulue :
; le mod ne depend pas de MCM a l'execution - sans lui, les valeurs par defaut des globales s'appliquent.
GlobalVariable Property VTN_CfgProgressionEnabled Auto
GlobalVariable Property VTN_CfgEnergyPerHour Auto

; --- Capacite de portage ---
; Depart 100, +10 par niveau. Remplace l'ancien VTN_MaxCarryWeight fige a 100 dans l'alias de Velyn.
float Property VTN_CapacityBase = 100.0 Auto
float Property VTN_CapacityPerLevel = 10.0 Auto
int Property VTN_MaxLevel = 20 Auto

; --- Courbe d'experience ---
; Palier suivant = VTN_XPPerLevel * niveau courant : la montee ralentit naturellement.
float Property VTN_XPPerLevel = 100.0 Auto

; --- Energie de recolte ---
; Regeneration CONTINUE (et non un lot par heure) : evite d'attendre bêtement devant un filon.
; 10 points par heure de jeu = 240 par jour de jeu.
int Property VTN_HarvestUnlockLevel = 5 Auto
float Property VTN_EnergyPerGameHour = 10.0 Auto
float Property VTN_EnergyMaxBase = 10.0 Auto
float Property VTN_EnergyMaxPerLevel = 2.0 Auto

; --- Production de gelee de netch (2026-07-29, demande de Kevin, inspiree d'une suggestion joueuse) ---
; Un netch en bonne sante laisse naturellement echapper un peu de gelee quand il se repose : Velyn en
; produit donc toute seule avec le temps, sans que le joueur ait a la "traire". La quantite depend de
; son NIVEAU - c'est une recompense de progression, pas une source infinie.
; Cadence en jours de jeu. La globale MCM l'emporte si elle est definie ; 0 = production desactivee.
GlobalVariable Property VTN_CfgJellyDays Auto
; Partagee avec VTN_HarvestScript : un joueur qui a coupe les notifications de recolte ne veut pas non
; plus etre notifie de la production de gelee.
GlobalVariable Property VTN_CfgNotifyHarvest Auto
float Property VTN_JellyIntervalDays = 3.0 Auto
; Quantite = base + niveau / paliers -> 1 unite au niveau 1, puis +1 tous les 5 niveaux (5 au niveau 20).
int Property VTN_JellyBase = 1 Auto
int Property VTN_JellyLevelsPerUnit = 5 Auto

float _lastGameTime = 0.0
float _lastJellyDay = 0.0

; --------------------------------------------------------------------------------------------------
; Consultation
; --------------------------------------------------------------------------------------------------

int Function GetLevel()
    return VTN_Level.GetValueInt()
EndFunction

float Function GetCapacity()
    return VTN_CapacityBase + VTN_CapacityPerLevel * (GetLevel() - 1)
EndFunction

float Function GetMaxEnergy()
    int levelsPastUnlock = GetLevel() - VTN_HarvestUnlockLevel
    if levelsPastUnlock < 0
        levelsPastUnlock = 0
    endif
    return VTN_EnergyMaxBase + VTN_EnergyMaxPerLevel * levelsPastUnlock
EndFunction

bool Function IsHarvestUnlocked()
    return GetLevel() >= VTN_HarvestUnlockLevel
EndFunction

; XP restante avant le prochain niveau (0 si niveau max atteint).
float Function GetXPToNextLevel()
    if GetLevel() >= VTN_MaxLevel
        return 0.0
    endif
    return VTN_XPPerLevel * GetLevel() - VTN_XP.GetValue()
EndFunction

; --------------------------------------------------------------------------------------------------
; Progression
; --------------------------------------------------------------------------------------------------

Function AddXP(float afAmount)
    if VTN_CfgProgressionEnabled && VTN_CfgProgressionEnabled.GetValueInt() == 0
        return ; progression desactivee au MCM : la capacite reste celle du niveau courant
    endif
    if afAmount <= 0.0 || VTN_HasVelyn.GetValueInt() != 1 || GetLevel() >= VTN_MaxLevel
        return
    endif

    VTN_XP.SetValue(VTN_XP.GetValue() + afAmount)

    ; Boucle (et non un simple if) : un gros gain ponctuel peut faire franchir plusieurs paliers.
    while GetLevel() < VTN_MaxLevel && VTN_XP.GetValue() >= VTN_XPPerLevel * GetLevel()
        VTN_XP.SetValue(VTN_XP.GetValue() - VTN_XPPerLevel * GetLevel())
        VTN_Level.SetValueInt(GetLevel() + 1)
        OnLevelUp()
    endwhile
EndFunction

Function OnLevelUp()
    int level = GetLevel()
    Debug.TraceUser("VTN", "Niveau " + level + " atteint (capacite=" + GetCapacity() + ", energie max=" + GetMaxEnergy() + ")")

    if level == VTN_HarvestUnlockLevel
        Notify("VTN_MsgCanHarvest")
    else
        Notify("VTN_MsgLevelUp")
    endif

    ; L'energie suit immediatement le nouveau plafond, sinon le gain de niveau ne se "sent" pas.
    if VTN_Energy.GetValue() < GetMaxEnergy() && level == VTN_HarvestUnlockLevel
        VTN_Energy.SetValue(GetMaxEnergy())
    endif
EndFunction

; --------------------------------------------------------------------------------------------------
; Energie
; --------------------------------------------------------------------------------------------------

; Regeneration basee sur le TEMPS DE JEU ecoule (Utility.GetCurrentGameTime renvoie des jours), et non
; sur le nombre de ticks : le resultat reste correct quelle que soit la frequence d'appel, et suit
; naturellement l'attente, le sommeil et le timescale du joueur.
Function UpdateEnergy()
    float now = Utility.GetCurrentGameTime()

    if _lastGameTime <= 0.0
        _lastGameTime = now
        return
    endif

    float elapsedDays = now - _lastGameTime
    _lastGameTime = now

    ; Garde-fou : un voyage rapide ou un sommeil long ne doit pas remplir l'energie d'un coup au-dela
    ; du plafond (le clamp s'en charge), et un temps negatif (chargement d'une save anterieure) est
    ; simplement ignore.
    if elapsedDays <= 0.0 || !IsHarvestUnlocked()
        return
    endif

    ; Taux reglable au MCM ; repli sur la valeur par defaut du script si la globale est absente.
    float ratePerHour = VTN_EnergyPerGameHour
    if VTN_CfgEnergyPerHour && VTN_CfgEnergyPerHour.GetValue() > 0.0
        ratePerHour = VTN_CfgEnergyPerHour.GetValue()
    endif

    float gained = elapsedDays * 24.0 * ratePerHour
    float energy = VTN_Energy.GetValue() + gained
    float maxEnergy = GetMaxEnergy()
    if energy > maxEnergy
        energy = maxEnergy
    endif
    VTN_Energy.SetValue(energy)
EndFunction

; --------------------------------------------------------------------------------------------------
; Gelee de netch
; --------------------------------------------------------------------------------------------------

; Quantite produite par cycle, fonction du niveau. Division entiere volontaire : 1 unite du niveau 1 a
; 4, 2 de 5 a 9... jusqu'a 5 au niveau 20.
int Function GetJellyYield()
    return VTN_JellyBase + GetLevel() / VTN_JellyLevelsPerUnit
EndFunction

; Cadence effective en jours de jeu : la globale MCM l'emporte si elle existe. Une valeur a 0 est ici
; LEGITIME (le joueur a coupe la production), on ne replie donc PAS sur le defaut dans ce cas - c'est
; l'inverse de GetRideOffset, ou 0 est une position valide et l'absence de globale le seul repli.
float Function GetJellyIntervalDays()
    if VTN_CfgJellyDays
        return VTN_CfgJellyDays.GetValue()
    endif
    return VTN_JellyIntervalDays
EndFunction

; Meme principe que UpdateEnergy : on raisonne en TEMPS DE JEU ecoule, pas en nombre de ticks, donc le
; sommeil, l'attente et le timescale du joueur sont pris en compte gratuitement.
Function UpdateJelly(Actor akVelyn)
    if !akVelyn || VTN_HasVelyn.GetValueInt() != 1
        return
    endif

    float interval = GetJellyIntervalDays()
    if interval <= 0.0
        return ; production desactivee au MCM
    endif

    float now = Utility.GetCurrentGameTime()

    ; Premier passage (ou premiere fois apres une mise a jour du mod) : on amorce l'horloge sans rien
    ; produire, sinon Velyn offrirait un lot d'emblee a un joueur qui vient de mettre a jour.
    if _lastJellyDay <= 0.0
        _lastJellyDay = now
        return
    endif

    ; Temps negatif = chargement d'une sauvegarde anterieure : on resynchronise sans produire.
    if now < _lastJellyDay
        _lastJellyDay = now
        return
    endif

    if (now - _lastJellyDay) < interval
        return
    endif

    ; Elle ne produit pas si elle ploie deja sous la charge. On ne touche PAS a _lastJellyDay dans ce
    ; cas : la gelee est simplement "en attente" et arrivera des que le joueur l'aura delestee, plutot
    ; que d'etre perdue en silence.
    if akVelyn.GetTotalItemWeight() >= GetCapacity()
        return
    endif

    ; ⚠️ PAS GetFormFromEditorID ici (2026-07-29) : cette fonction a bien renvoye None sur
    ; "DLC02NetchJelly", constate dans le log ("Gelee : DLC02NetchJelly introuvable"). Elle ne resout
    ; que les EditorID reellement conservees en memoire par le moteur - ce qui marche pour les mots-cles
    ; et pour nos propres records, mais pas pour un ingredient d'un master. Pour une forme vanilla ou
    ; DLC, c'est GetFormFromFile qu'il faut : elle resout par plugin + FormID, sans dependre d'aucun
    ; cache. FormID de Netch Jelly verifie sur UESP : xx01CD72 (EditorID DLC02NetchJelly).
    Ingredient jelly = Game.GetFormFromFile(0x0001CD72, "Dragonborn.esm") as Ingredient
    if !jelly
        ; Dragonborn absent : on n'insiste pas, et on n'arme pas l'horloge non plus, pour que la
        ; production reprenne d'elle-meme si le probleme est corrige.
        Debug.TraceUser("VTN", "Gelee : Netch Jelly introuvable (Dragonborn.esm absent ?), production ignoree")
        return
    endif

    int amount = GetJellyYield()
    akVelyn.AddItem(jelly, amount, true) ; true = silencieux, la notification ci-dessous suffit
    _lastJellyDay = now

    if VTN_CfgNotifyHarvest == None || VTN_CfgNotifyHarvest.GetValueInt() != 0
        Notify("VTN_MsgJelly")
    endif
    Debug.TraceUser("VTN", "Gelee produite : " + amount + " (niveau " + GetLevel() + ")")
EndFunction

; Consomme 1 point si possible. Un point = UN point de recolte, quelle que soit la quantite obtenue
; (un filon donne 3 minerais et parfois une gemme : cela reste 1 point).
bool Function SpendHarvestPoint()
    if !IsHarvestUnlocked() || VTN_Energy.GetValue() < 1.0
        return false
    endif
    VTN_Energy.SetValue(VTN_Energy.GetValue() - 1.0)
    return true
EndFunction

; --------------------------------------------------------------------------------------------------
; Debug (a retirer avant publication, voir docs/03-plan-M3.md)
; --------------------------------------------------------------------------------------------------
; Utilisation console : set VTN_DebugAddXP to 250
; ATTENTION : "cqf" n'existe pas dans Skyrim (commande Fallout 4) - c'est pour cela qu'on passe par un
; global plutot que par un appel de fonction depuis la console.
; Notification localisable via record Message (voir VTN_MainQuestScript.Notify pour le detail).
Function Notify(string asEditorID)
    Message m = PO3_SKSEFunctions.GetFormFromEditorID(asEditorID) as Message
    if m
        m.Show()
    endif
EndFunction

Function ProcessDebugRequests()
    float requested = VTN_DebugAddXP.GetValue()
    if requested > 0.0
        VTN_DebugAddXP.SetValue(0.0)
        Debug.TraceUser("VTN", "Debug : ajout de " + requested + " XP")
        AddXP(requested)
    endif
EndFunction
