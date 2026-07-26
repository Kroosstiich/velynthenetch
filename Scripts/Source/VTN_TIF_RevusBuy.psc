Scriptname VTN_TIF_RevusBuy extends TopicInfo Hidden

Quest Property VTN_MainQuest Auto
GlobalVariable Property VTN_PriceGold Auto
MiscObject Property Gold001 Auto
Book Property VTN_NetchGuideBook Auto

Function Fragment_Buy(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
Game.GetPlayer().RemoveItem(Gold001, VTN_PriceGold.GetValueInt(), true)
Debug.Notification(VTN_PriceGold.GetValueInt() + " gold removed.")
Game.GetPlayer().AddItem(VTN_NetchGuideBook, 1)
(VTN_MainQuest as VTN_MainQuestScript).AcquireVelyn(1)
;END CODE
EndFunction
