local UGCPlayerPawn = {}
 
function UGCPlayerPawn:ReceiveBeginPlay()
    UGCPlayerPawn.SuperClass.ReceiveBeginPlay(self)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.Test_01) 
UGCPawnAttrSystem.SetSpeedScale(self,5)
end


function UGCPlayerPawn:GetReplicatedProperties()
    return {"__SubObjectRepList", "Lazy"}
end


return UGCPlayerPawn