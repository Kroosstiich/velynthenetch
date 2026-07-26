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

float _lastGameTime = 0.0

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
