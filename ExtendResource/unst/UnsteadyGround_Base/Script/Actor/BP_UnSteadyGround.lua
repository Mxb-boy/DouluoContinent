---@class BP_UnSteadyGround_C:ActivityBaseActor
---@field Broken_Particle UParticleSystemComponent
---@field Reply_Particle UParticleSystemComponent
---@field Broking_Particle UParticleSystemComponent
---@field ReBirth_Sequence UActorSequenceComponent
---@field Broke_Reply_Sequence UActorSequenceComponent
---@field Broking_Sequence UActorSequenceComponent
---@field Broken_Sequence UActorSequenceComponent
---@field Box UBoxComponent
---@field Mesh UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field PlayerCap int32
---@field BrokenTime float
---@field BelowTheLimitTime float
---@field ReBirthTime float
---@field GroundMesh UStaticMesh
---@field JitterSound UAkAudioEvent
---@field BrokenSound UAkAudioEvent
---@field FallDistance float
---@field BrokenParticle UParticleSystem
---@field PawnClass UClass
---@field ReplySound UAkAudioEvent
---@field ReBirthSound UAkAudioEvent
---@field FallTime float
---@field CollisionExtent FVector
--Edit Below--
local BP_UnsteadyGround = {
    CurrentBrokingTime=0,
    CurrentReplyTime=0,
    --音效ID
    JitterSoundID=-1,
    BrokenSoundID=-1,
    ReplySoundID=-1,
    ReBirthSoundID=-1,

    --位置
    NormalLocation={X=0,Y=0,Z=0},
    TargetHeight=0,

}; 
function BP_UnsteadyGround:ReceiveBeginPlay()
    print("BP_UnsteadyGround:ReceiveBeginPlay")
    BP_UnsteadyGround.SuperClass.ReceiveBeginPlay(self)

    --设置Mesh
    if self.GroundMesh~=nil then
        self.Mesh:SetStaticMesh(self.GroundMesh); 
    end




    --设置碰撞体边长
    self.Box:SetBoxExtent(self.CollisionExtent,true);

    --关闭客户端Tick
    if not self:HasAuthority() then
        self:SetActorTickEnabled(false);
    end

    --设置位置
    print("BP_UnsteadyGround:ReceiveBeginPlay set location")
    self.NormalLocation=self:K2_GetActorLocation();
    self.TargetHeight=self.NormalLocation.Z-self.FallDistance*100;

end

--开始重生，结束这段seququence后自己跳到Complate状态上
function BP_UnsteadyGround:BeginReBirth()
    print("BP_UnsteadyGround:BeginReBirth")
    self:JumpToState("ReBirth",0)
    self:K2_SetActorLocation(self.NormalLocation);
end


--完整的地面，最开始的状态，没有抖动
function BP_UnsteadyGround:BeginComplate()
    print("BP_UnsteadyGround:BeginComplate")
    self.CurrentReplyTime=0;
    self.CurrentBrokingTime=0;
    

    

end




function BP_UnsteadyGround:ReceiveTick(DeltaTime)
    print("BP_UnsteadyGround:ReceiveTick")
    --DS

    if self.PlayerCap==0 then
        print("BP_UnsteadyGround:ReceiveTick PlayerCap == 0")
        return;
    end

    local class=self.PawnClass;
    local Players=self.Box:GetOverlappingActors({},class);
    print("BP_UnsteadyGround:ReceiveTick Player Length"..#Players)
    if #Players==0 then
        return;
    end
    if #Players>=self.PlayerCap then
        if self:GetCurrentStateName()=="ReBirth" then
            return;
        end
        if self:GetCurrentStateName()=="Complate" or  self:GetCurrentStateName()=="Broking" or self:GetCurrentStateName()=="Broke_Reply" then
            self:BeginBroking(DeltaTime);
            self.CurrentReplyTime=0;
        end
    else
        --只有在Broking或者Broke_Reply的时候才会Reply

        if self:GetCurrentStateName()=="Broking"or self:GetCurrentStateName()=="Broke_Reply" then
            self.CurrentBrokingTime=0;
            self:BeginReply(DeltaTime);
        end
    end

    --Broken时向下移动FallDistance*100cm
    if self:GetCurrentStateName()=="Broken" and self:K2_GetActorLocation().Z>self.TargetHeight then
        print("BP_UnsteadyGround:ReceiveTick set actor Location")
        local NewLocation=Vector.New(0,0,0);
        NewLocation.X=self:K2_GetActorLocation().X;
        NewLocation.Y=self:K2_GetActorLocation().Y;
        NewLocation.Z=self:K2_GetActorLocation().Z-self.FallDistance*100*DeltaTime/self.FallTime;
        self:K2_SetActorLocation(NewLocation);
    end


end

--开始破碎裂缝，抖动
function BP_UnsteadyGround:BeginBroking(DeltaTime)
    --DS
    print("BP_UnsteadyGround:BeginBroking")
    if self:GetCurrentStateName()~="Broking" then
        self:JumpToState("Broking",0)
    end
    self.CurrentBrokingTime=self.CurrentBrokingTime+DeltaTime;
    print("BP_UnsteadyGround:BeginBroking CurrentBrokingTime"..self.CurrentBrokingTime)
    if self.CurrentBrokingTime>=self.BrokenTime then
        self:BeginBroken();
    end
end




--开始恢复破碎裂缝，抖动
function BP_UnsteadyGround:BeginReply(DeltaTime)
    print("BP_UnsteadyGround:BeginReply")
    if self:GetCurrentStateName()=="Broking" then
        self:JumpToState("Broke_Reply",0)
    end

    self.CurrentReplyTime=self.CurrentReplyTime+DeltaTime;
    print("BP_UnsteadyGround:BeginReply"..self.CurrentReplyTime)
    if self.CurrentReplyTime>=self.BelowTheLimitTime then
        self:BeginComplate();
        self.CurrentReplyTime=0;
        self.CurrentBrokingTime=0;
        self:JumpToState("Complate",0)
    end
end


--完全破碎的地面，抖动
function BP_UnsteadyGround:BeginBroken()
    print("BP_UnsteadyGround:BeginBroken")
    self:JumpToState("Broken",0)

    self.CurrentReplyTime=0;
    self.CurrentBrokingTime=0;



    --到达重生时间之后进入重生状态
    local TempTimer=nil;
    if TempTimer~=nil then
        Timer.RemoveTimer(TempTimer);
    end
    TempTimer=Timer.InsertTimer(
        self.ReBirthTime,
        function()
            self:BeginReBirth();
        end,
        false
    )
end

----------------------------------------状态机入口出口-----------------------------------------
--爆炸状态
function BP_UnsteadyGround:Broken_Entry()
    print("BP_UnsteadyGround:Broken_Entry")
    if self:HasAuthority() then
        --DS
        --设置碰撞
        if self.Mesh~=nil then
            self.Mesh:SetCollisionResponsetoAllChannels(ECollisionResponse.ECR_Ignore) 
        end

    else

        --Client
        --设置碰撞
        if self.Mesh~=nil then
            self.Mesh:SetCollisionResponsetoAllChannels(ECollisionResponse.ECR_Ignore) 
        end
        local TempTimer=nil;
        if TempTimer~=nil then
            Timer.RemoveTimer(TempTimer);
        end
        TempTimer=Timer.InsertTimer(
            self.FallTime,
            function()
                --播放爆炸音效
                self:PlayBrokenSound(true);
                self:PlayBrokingSound(false);
                self:PlayReBirthSound(false);
                self:PlayReplySound(false);
                --隐藏板子模型
                self.Mesh:SetVisibility(false,false,false);
                
            end,
            false
        )


    end


end
---恢复状态

function BP_UnsteadyGround:Broke_Reply_Entry()
    print("BP_UnsteadyGround:Broke_Reply_Entry")
    if self:HasAuthority() then
        --DS
    else
        --client
        --播放恢复音效
        self:PlayBrokenSound(false);
        self:PlayBrokingSound(false);
        self:PlayReBirthSound(false);
        self:PlayReplySound(true);
    end   
end


--重生状态
function BP_UnsteadyGround:ReBirth_Entry()
    print("BP_UnsteadyGround:ReBirth_Entry")
    if self:HasAuthority() then
    else
        --Client
        --播放重生音效
        self:PlayBrokenSound(false);
        self:PlayBrokingSound(false);
        self:PlayReBirthSound(true);
        self:PlayReplySound(false);
    end   
end

--Broking状态

function BP_UnsteadyGround:Broking_Entry()
    print("BP_UnsteadyGround:Broking_Entry")
    if self:HasAuthority() then

    else
        --Client
        --播放抖动音效
        self:PlayBrokenSound(false);
        self:PlayBrokingSound(true);
        self:PlayReBirthSound(false);
        self:PlayReplySound(false);
        --设置粒子
        if self.BrokenParticle~=nil then
            self.Broken_Particle:SetTemplate(self.BrokenParticle);
        end
        
    end 
end

--Complate状态
function BP_UnsteadyGround:Complate_Entry()
    print("BP_UnsteadyGround:Complate_Entry")
    if self:HasAuthority() then
        --DS
        --设置碰撞
        if self.Mesh~=nil then
            self.Mesh:SetCollisionResponsetoAllChannels(ECollisionResponse.ECR_Block) 
        end
        self:BeginComplate()
    else
        --Client
        --显示板子模型
        self.Mesh:SetVisibility(true,false,false);

        --设置碰撞
        if self.Mesh~=nil then
            self.Mesh:SetCollisionResponsetoAllChannels(ECollisionResponse.ECR_Block) 
        end
        self:PlayBrokenSound(false);
        self:PlayBrokingSound(false);
        self:PlayReBirthSound(false);
        self:PlayReplySound(false);

    end

end



--sequence里播放不了音效，所以音效在这里控制
------------------------------------------------音效------------------------------------------
--破碎音效
function BP_UnsteadyGround:PlayBrokenSound(IsPlay)
    if IsPlay then
        if self.BrokenSound~=nil then
            self.BrokenSoundID=AkGameplayStatics.PostEvent(self.BrokenSound,self,false,"");
        end
    else
        if self.BrokenSoundID~=-1 then
            AkGameplayStatics.StopAkEventByID(self.BrokenSoundID)
            self.BrokenSoundID=-1;
        end
    end
end

--Broking音效

function BP_UnsteadyGround:PlayBrokingSound(IsPlay)
    if IsPlay then
        if self.JitterSound~=nil then
            self.JitterSoundID=AkGameplayStatics.PostEvent(self.JitterSound,self,false,"");
        end
    else
        if self.JitterSoundID~=-1 then
            AkGameplayStatics.StopAkEventByID(self.JitterSoundID)
            self.JitterSoundID=-1;
        end
    end
end


--恢复破碎音效

function BP_UnsteadyGround:PlayReplySound(IsPlay)
    if IsPlay then
        if self.ReplySound~=nil then
            self.ReplySoundID=AkGameplayStatics.PostEvent(self.ReplySound,self,false,"");
        end
    else
        print("BP_UnsteadyGround:PlayReplySound ReplySoundID ")
        if self.ReplySoundID~=-1 then
            AkGameplayStatics.StopAkEventByID(self.ReplySoundID)
            self.ReplySoundID=-1;
        end
    end
end



--重生音效

function BP_UnsteadyGround:PlayReBirthSound(IsPlay)
    if IsPlay then
        if self.ReBirthSound~=nil then
            self.ReBirthSoundID=AkGameplayStatics.PostEvent(self.ReBirthSound,self,false,"");
        end
    else
        if self.ReBirthSoundID~=-1 then
            AkGameplayStatics.StopAkEventByID(self.ReBirthSoundID)
            self.ReBirthSoundID=-1;
        end
    end
end

--





function BP_UnsteadyGround:ReceiveEndPlay()
 
end
return BP_UnsteadyGround;