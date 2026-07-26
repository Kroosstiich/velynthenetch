Scriptname VTN_MCMScript extends MCM_ConfigBase

; ==================================================================================================
; Point d'ancrage du menu MCM. Volontairement VIDE.
; ==================================================================================================
; Pourquoi ce fichier existe : le config.json seul NE SUFFIT PAS. La doc officielle de MCM Helper est
; explicite (wiki, "Getting Started") :
;   "A configuration menu must at minimum, have a quest with an appropriate Papyrus script attached,
;    and have a config.json file defined."
; C'est ce script, attache a VTN_MCMQuest, qui enregistre le menu aupres de SkyUI. Sans lui, MCM Helper
; ignore purement et simplement notre config.json - constate en jeu : "Registered 11 mod configs" sans
; aucune mention de VelynTheNetch, et aucun menu affiche.
;
; Aucun code n'est necessaire ici : tous les reglages sont declares dans config.json et ecrits
; DIRECTEMENT dans nos variables globales (sourceType "GlobalValue"). Les scripts de jeu lisent ces
; globales, ce qui evite toute dependance a MCM Helper a l'execution.
;
; La quete porte aussi un alias nomme "PlayerAlias" (reference forcee = joueur) avec le script vanilla
; SkyUI "SKI_PlayerLoadGameAlias" : il execute la maintenance du menu a chaque chargement de partie.
; Cet alias est exige par la doc, il n'est pas optionnel.

; ==================================================================================================
; Reinitialisation aux valeurs par defaut (2026-07-23)
; ==================================================================================================
; POURQUOI ce bouton maison plutot que le champ "defaultValue" du config.json : la version de MCM Helper
; installee (1.6.2) N'ACCEPTE PAS "defaultValue" sur une source "GlobalValue" - testee 2 fois en jeu,
; elle casse le menu ("Error loading config"). On implemente donc le reset nous-memes : un bouton
; (type "text" + action CallFunction "ResetToDefaults", schema releve sur Wyrmstooth/Ordinator) appelle
; cette fonction, qui reecrit chaque globale a son defaut puis rafraichit l'affichage. Marche a coup sur
; avec des sources GlobalValue.
;
; Les globales sont resolues par EditorID via po3 (deja une dependance) : aucun FormID en dur, aucune
; propriete a remplir dans le YAML de la quete MCM (donc rien qui puisse redevenir None au runtime).
Function ResetToDefaults()
    ; Page General
    ResetG("VTN_CfgProgressionEnabled", 1.0)
    ResetG("VTN_CfgHarvestEnabled", 1.0)
    ResetG("VTN_CfgRideEnabled", 1.0)
    ResetG("VTN_CfgPickupEnabled", 1.0)
    ResetG("VTN_CfgNotifyHarvest", 1.0)
    ResetG("VTN_CfgInventoryKey", 38.0) ; L
    ; Page Recolte
    ResetG("VTN_CfgHarvestRadius", 400.0)
    ResetG("VTN_CfgEnergyPerHour", 10.0)
    ResetG("VTN_CfgXPPerHarvest", 15.0)
    ResetG("VTN_CfgXPTransportRate", 0.002)
    ResetG("VTN_CfgRadiusFlora", 0.0)
    ResetG("VTN_CfgRadiusOre", 0.0)
    ResetG("VTN_CfgRadiusCritter", 0.0)
    ResetG("VTN_CfgRadiusItems", 0.0)
    ; Page Filtres
    ResetG("VTN_CfgFilterKey", -1.0) ; -1 = non liee (SkyUI l'affiche comme non assignee, pas "Esc")
    ResetG("VTN_CfgPickupGoldEnabled", 1.0)
    ResetG("VTN_CfgPickupIngredientsEnabled", 1.0)
    ResetG("VTN_CfgPickupMiscEnabled", 1.0)
    ResetG("VTN_CfgMinItemValue", 5.0)
    ResetG("VTN_CfgOreCooldownMinutes", 15.0)
    ResetG("VTN_CfgBlockDwelling", 1.0)
    ResetG("VTN_CfgBlockPlayerHouse", 1.0)
    ResetG("VTN_CfgBlockStore", 1.0)
    ResetG("VTN_CfgBlockInn", 1.0)
    ResetG("VTN_CfgBlockStable", 1.0)
    ResetG("VTN_CfgBlockFarm", 1.0)
    ; Page Portage
    ResetG("VTN_CfgRideOffsetX", 18.0)
    ResetG("VTN_CfgRideOffsetY", -60.0)
    ResetG("VTN_CfgRideOffsetZ", -90.0)

    ; Rafraichit les valeurs affichees dans le menu ouvert (natif MCM_ConfigBase). Les rebinds de touche
    ; (inventaire/filtre) et l'offset de portage sont repris automatiquement par les ticks dedies de
    ; VTN_PlayerAliasScript (RefreshInventoryKeyIfChanged / RefreshFilterKeyIfChanged /
    ; RefreshRideOffsetIfChanged), donc rien de plus a faire ici.
    RefreshMenu()
    Message m = PO3_SKSEFunctions.GetFormFromEditorID("VTN_MsgSettingsReset") as Message
    if m
        m.Show()
    endif
EndFunction

Function ResetG(string asEditorID, float afValue)
    GlobalVariable g = PO3_SKSEFunctions.GetFormFromEditorID(asEditorID) as GlobalVariable
    if g
        g.SetValue(afValue)
    endif
EndFunction
