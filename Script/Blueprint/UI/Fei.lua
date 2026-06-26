---@class Fei_C:UUserWidget
---@field Button_84 UButton
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")

local FLY_SPEED = 3600
local FLY_ANIM_PATHS = {
    "/Game/Arts_Timeliness/CG005_Concert/Arts_Player/CommingHome/Anim/Concert_CommingHome_Idle.Concert_CommingHome_Idle",
}
local FLY_EFFECT_RELATIVE_PATH = "Asset/cs/P_Speed.P_Speed"
local FLY_EFFECT_SOCKET = "Root"
local FLY_EFFECT_OFFSET = Vector.New(0, 0, 80)
local FLY_EFFECT_ROTATION = Rotator.New(0, 0, 0)
local FLY_EFFECT_SCALE = Vector.New(2, 2, 2)

local BlockedControlWidgetNames = {
    "MainUI_FireLeft_C_0",
    "MainUI_FireRight_C_0",
    "MainUI_Jump_C_0",
    "MainUI_Crouch_C_0",
    "MainUI_Crawl_C_0",
    "MainUI_Reload_14_C_0",
    "MainUI_Weapon1_C_0",
    "MainUI_Weapon2_C_0",
    "MainUI_Pistol_C_0",
    "MainUI_AimMode_16_C_0",
    "MainUI_Scope_29_C_0",
    "MainUI_ScopeList_42_C_0",
    "MainUI_ScopeSide_43_C_0",
    "MainUI_Projectile_C_0",
    "MainUI_DrawBow_139_C_0",
    "MainUI_Rush_C_0",
    "MainUI_BackPack_C_0",
}

local Fei = { bInitDoOnce = false } 

function Fei:Construct()
    self:LuaInit()
end

function Fei:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    if self.Button_84 ~= nil then
        UIEffectUtil.SetButtonStateBrushSameAsNormal(self.Button_84)
        UIEffectUtil.BindPressScale(self, self.Button_84, self.Button_84, 1.06, 1.0)

        if self.Button_84.OnPressed ~= nil then
            self.Button_84.OnPressed:Add(self.Button_84_OnPressed, self)
        end
        if self.Button_84.OnReleased ~= nil then
            self.Button_84.OnReleased:Add(self.Button_84_OnReleased, self)
        end
    end
end

function Fei:Button_84_OnPressed()
    self.bFlying = true
    self:BeginFly()
    self:PlayFlyAnimation()
    self:SpawnFlyEffect()
    self:SetOtherBlueprintUIHidden(true)
    self:SetNativeControlBlocked(true)
end

function Fei:Button_84_OnReleased()
    self.bFlying = false
    self:EndFly()
    self:StopFlyAnimation()
    self:DestroyFlyEffect()
    self:SetFlyMovementMode(false)
    self:SetOtherBlueprintUIHidden(false)
    self:SetNativeControlBlocked(false)
end

function Fei:Tick(MyGeometry, InDeltaTime)
    if self.bFlying then
        self:ApplyFlyMovement(InDeltaTime)
    end
end

function Fei:SetOtherBlueprintUIHidden(bHidden)
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        return
    end

    if bHidden then
        self.HiddenBlueprintWidgets = {}
        self:HideWidget(PlayerController.MainUIInstance)

        if PlayerController.MainUIInstance ~= nil then
            self:HideWidget(PlayerController.MainUIInstance.UI10Instance)
            self:HideWidget(PlayerController.MainUIInstance.TitleUIInstance)
        end
        return
    end

    if self.HiddenBlueprintWidgets == nil then
        return
    end

    for _, Item in ipairs(self.HiddenBlueprintWidgets) do
        if Item.Widget ~= nil and Item.Widget.SetVisibility ~= nil then
            Item.Widget:SetVisibility(Item.Visibility or ESlateVisibility.Visible)
        end
    end
    self.HiddenBlueprintWidgets = nil
end

function Fei:HideWidget(Widget)
    if Widget == nil or Widget == self or Widget.SetVisibility == nil then
        return
    end

    local Visibility = ESlateVisibility.Visible
    if Widget.GetVisibility ~= nil then
        local Success, Result = pcall(Widget.GetVisibility, Widget)
        if Success and Result ~= nil then
            Visibility = Result
        end
    end

    table.insert(self.HiddenBlueprintWidgets, {
        Widget = Widget,
        Visibility = Visibility,
    })
    Widget:SetVisibility(ESlateVisibility.Collapsed)
end

function Fei:BeginFly()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn ~= nil and PlayerPawn.BeginFly ~= nil then
        PlayerPawn:BeginFly()
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_BeginFlyState")
    end
end

function Fei:EndFly()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn ~= nil and PlayerPawn.EndFly ~= nil then
        PlayerPawn:EndFly()
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_EndFlyState")
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_StopFlyMove")
    end
end

function Fei:GetFlyAnimation()
    if self.FlyAnimation ~= nil then
        return self.FlyAnimation
    end

    for _, AnimPath in ipairs(FLY_ANIM_PATHS) do
        local AnimAsset = UE.LoadObject(AnimPath)
        if AnimAsset ~= nil then
            self.FlyAnimation = AnimAsset
            self.FlyAnimationPath = AnimPath
            ugcprint("[Fei] Fly animation loaded: " .. tostring(AnimPath))
            return AnimAsset
        end
    end

    ugcprint("[Fei] Fly animation load failed")
    return nil
end

function Fei:PlayFlyAnimation()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil or PlayerPawn.Mesh == nil then
        return
    end

    local AnimAsset = self:GetFlyAnimation()
    if AnimAsset == nil then
        return
    end

    if PlayerPawn.Mesh.GetAnimationMode ~= nil then
        local Success, AnimationMode = pcall(PlayerPawn.Mesh.GetAnimationMode, PlayerPawn.Mesh)
        if Success then
            self.CacheAnimationMode = AnimationMode
        end
    end

    if PlayerPawn.Mesh.PlayAnimation ~= nil then
        pcall(PlayerPawn.Mesh.PlayAnimation, PlayerPawn.Mesh, AnimAsset, true)
    end
end

function Fei:StopFlyAnimation()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil or PlayerPawn.Mesh == nil then
        return
    end

    if PlayerPawn.Mesh.SetAnimationMode ~= nil then
        if self.CacheAnimationMode ~= nil then
            pcall(PlayerPawn.Mesh.SetAnimationMode, PlayerPawn.Mesh, self.CacheAnimationMode)
        elseif EAnimationMode ~= nil and EAnimationMode.AnimationBlueprint ~= nil then
            pcall(PlayerPawn.Mesh.SetAnimationMode, PlayerPawn.Mesh, EAnimationMode.AnimationBlueprint)
        end
    end

    self.CacheAnimationMode = nil
end

function Fei:GetFlyEffectTemplate()
    if self.FlyEffectTemplate ~= nil then
        return self.FlyEffectTemplate
    end

    local EffectPaths = {}
    if UGCGameSystem ~= nil and UGCGameSystem.GetUGCResourcesFullPath ~= nil then
        local Success, Path = pcall(UGCGameSystem.GetUGCResourcesFullPath, FLY_EFFECT_RELATIVE_PATH)
        if Success and Path ~= nil then
            table.insert(EffectPaths, Path)
        end
    end
    if UGCMapInfoLib ~= nil and UGCMapInfoLib.GetRootLongPackagePath ~= nil then
        table.insert(EffectPaths, UGCMapInfoLib.GetRootLongPackagePath() .. FLY_EFFECT_RELATIVE_PATH)
    end
    table.insert(EffectPaths, "/Douluo/" .. FLY_EFFECT_RELATIVE_PATH)

    for _, EffectPath in ipairs(EffectPaths) do
        self.FlyEffectTemplate = UE.LoadObject(EffectPath)
        if self.FlyEffectTemplate ~= nil then
            self.FlyEffectPath = EffectPath
            ugcprint("[Fei] Fly effect loaded: " .. tostring(EffectPath))
            return self.FlyEffectTemplate
        end
    end

    if self.FlyEffectTemplate == nil then
        ugcprint("[Fei] Fly effect load failed: " .. tostring(FLY_EFFECT_RELATIVE_PATH))
    end

    return self.FlyEffectTemplate
end

function Fei:SpawnFlyEffect()
    if self.FlyEffectComponent ~= nil then
        return
    end

    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil or PlayerPawn.Mesh == nil then
        return
    end

    local EffectTemplate = self:GetFlyEffectTemplate()
    if EffectTemplate == nil or GameplayStatics == nil or GameplayStatics.SpawnEmitterAttached == nil then
        return
    end

    local AttachLocationRule = nil
    if EAttachLocation ~= nil then
        AttachLocationRule = EAttachLocation.SnapToTarget or EAttachLocation.KeepRelativeOffset
    end

    local Success, EffectComponent = false, nil
    if AttachLocationRule ~= nil then
        Success, EffectComponent = pcall(
            GameplayStatics.SpawnEmitterAttached,
            EffectTemplate,
            PlayerPawn.Mesh,
            FLY_EFFECT_SOCKET,
            FLY_EFFECT_OFFSET,
            FLY_EFFECT_ROTATION,
            FLY_EFFECT_SCALE,
            AttachLocationRule,
            false
        )
    end

    if not Success or EffectComponent == nil then
        Success, EffectComponent = pcall(
            GameplayStatics.SpawnEmitterAttached,
            EffectTemplate,
            PlayerPawn.Mesh,
            FLY_EFFECT_SOCKET
        )
    end

    if Success and EffectComponent ~= nil then
        self.FlyEffectComponent = EffectComponent
        ugcprint("[Fei] Fly effect spawned")
    else
        ugcprint("[Fei] Fly effect spawn failed")
    end
end

function Fei:DestroyFlyEffect()
    local EffectComponent = self.FlyEffectComponent
    self.FlyEffectComponent = nil

    if EffectComponent == nil then
        return
    end

    if EffectComponent.DeactivateSystem ~= nil then
        pcall(EffectComponent.DeactivateSystem, EffectComponent)
    elseif EffectComponent.Deactivate ~= nil then
        pcall(EffectComponent.Deactivate, EffectComponent)
    end

    if EffectComponent.K2_DestroyComponent ~= nil then
        pcall(EffectComponent.K2_DestroyComponent, EffectComponent, EffectComponent)
    elseif EffectComponent.DestroyComponent ~= nil then
        pcall(EffectComponent.DestroyComponent, EffectComponent)
    end
end

function Fei:ApplyFlyMovement(InDeltaTime)
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil then
        return
    end

    self:SetFlyMovementMode(true)

    local ForwardVector = self:GetViewForwardVector(PlayerPawn)
    if ForwardVector == nil then
        return
    end

    self:MovePawnByDirection(PlayerPawn, ForwardVector, InDeltaTime)

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        UnrealNetwork.CallUnrealRPC(
            PlayerController,
            PlayerController,
            "Server_FlyMove",
            ForwardVector.X or 0,
            ForwardVector.Y or 0,
            ForwardVector.Z or 0,
            InDeltaTime or 0.016
        )
    end
end

function Fei:GetViewForwardVector(PlayerPawn)
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)

    if PlayerController ~= nil and PlayerController.PlayerCameraManager ~= nil
        and PlayerController.PlayerCameraManager.GetCameraRotation ~= nil then
        local Success, CameraRotation =
            pcall(PlayerController.PlayerCameraManager.GetCameraRotation, PlayerController.PlayerCameraManager)
        if Success and CameraRotation ~= nil and KismetMathLibrary ~= nil
            and KismetMathLibrary.GetForwardVector ~= nil then
            return KismetMathLibrary.GetForwardVector(CameraRotation)
        end
    end

    if PlayerController ~= nil and PlayerController.GetControlRotation ~= nil then
        local Success, ControlRotation = pcall(PlayerController.GetControlRotation, PlayerController)
        if Success and ControlRotation ~= nil and KismetMathLibrary ~= nil
            and KismetMathLibrary.GetForwardVector ~= nil then
            return KismetMathLibrary.GetForwardVector(ControlRotation)
        end
    end

    if PlayerPawn ~= nil and PlayerPawn.GetActorForwardVector ~= nil then
        local Success, ForwardVector = pcall(PlayerPawn.GetActorForwardVector, PlayerPawn)
        if Success then
            return ForwardVector
        end
    end

    return Vector.New(1, 0, 0)
end

function Fei:SetFlyMovementMode(bFlying)
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil then
        return
    end

    local MovementComponent = PlayerPawn.CharacterMovement or PlayerPawn.MovementComponent
    if MovementComponent ~= nil and MovementComponent.SetMovementMode ~= nil then
        if bFlying then
            if self.CacheGravityScale == nil then
                self.CacheGravityScale = MovementComponent.GravityScale
            end
            pcall(MovementComponent.SetMovementMode, MovementComponent, 5)
            if MovementComponent.GravityScale ~= nil then
                MovementComponent.GravityScale = 0
            end
            if MovementComponent.Velocity ~= nil then
                MovementComponent.Velocity = Vector.New(0, 0, 0)
            end
        else
            if self.CacheGravityScale ~= nil and MovementComponent.GravityScale ~= nil then
                MovementComponent.GravityScale = self.CacheGravityScale
            end
            self.CacheGravityScale = nil
            pcall(MovementComponent.SetMovementMode, MovementComponent, 1)
        end
    end
end

function Fei:MovePawnByDirection(PlayerPawn, Direction, DeltaTime)
    if PlayerPawn == nil or Direction == nil or PlayerPawn.K2_GetActorLocation == nil
        or PlayerPawn.K2_SetActorLocation == nil then
        return
    end

    DeltaTime = tonumber(DeltaTime) or 0.016
    if DeltaTime <= 0 or DeltaTime > 0.1 then
        DeltaTime = 0.016
    end

    local Success, Location = pcall(PlayerPawn.K2_GetActorLocation, PlayerPawn)
    if not Success or Location == nil then
        return
    end

    local Distance = FLY_SPEED * DeltaTime
    local NewLocation = Vector.New(
        Location.X + (Direction.X or 0) * Distance,
        Location.Y + (Direction.Y or 0) * Distance,
        Location.Z + (Direction.Z or 0) * Distance
    )

    pcall(PlayerPawn.K2_SetActorLocation, PlayerPawn, NewLocation, true, nil, true)
end

function Fei:SetNativeControlBlocked(bBlocked)
    local MainControlUI = nil
    if UGCWidgetManagerSystem ~= nil and UGCWidgetManagerSystem.GetMainControlUI ~= nil then
        MainControlUI = UGCWidgetManagerSystem.GetMainControlUI()
    end

    if MainControlUI == nil then
        return
    end

    if bBlocked then
        self.HiddenControlWidgets = {}
        for _, WidgetName in ipairs(BlockedControlWidgetNames) do
            self:HideControlWidget(MainControlUI[WidgetName])
        end
        return
    end

    if self.HiddenControlWidgets == nil then
        return
    end

    for _, Item in ipairs(self.HiddenControlWidgets) do
        if Item.Widget ~= nil and Item.Widget.SetVisibility ~= nil then
            Item.Widget:SetVisibility(Item.Visibility or ESlateVisibility.Visible)
        end
    end
    self.HiddenControlWidgets = nil
end

function Fei:HideControlWidget(Widget)
    if Widget == nil or Widget.SetVisibility == nil then
        return
    end

    local Visibility = ESlateVisibility.Visible
    if Widget.GetVisibility ~= nil then
        local Success, Result = pcall(Widget.GetVisibility, Widget)
        if Success and Result ~= nil then
            Visibility = Result
        end
    end

    table.insert(self.HiddenControlWidgets, {
        Widget = Widget,
        Visibility = Visibility,
    })
    Widget:SetVisibility(ESlateVisibility.Collapsed)
end

-- function Fei:Destruct()

-- end

return Fei
