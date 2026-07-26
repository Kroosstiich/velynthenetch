Scriptname VTN_TIF_RevusLore extends TopicInfo Hidden

GlobalVariable Property VTN_HasAskedAboutNetch Auto

Function Fragment_Lore(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
VTN_HasAskedAboutNetch.SetValueInt(1)
;END CODE
EndFunction
