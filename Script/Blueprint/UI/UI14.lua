---@class UI14_C:UUserWidget
---@field Btn_Close UButton
---@field Btn_FHSY UButton
---@field Btn_Title UButton
---@field Btn_Weapon UButton
---@field Btn_Wing UButton
---@field Image_0 UImage
---@field Image_19 UImage
---@field Image_26 UImage
---@field Image_45 UImage
---@field Image_126 UImage
---@field Image_358 UImage
---@field Image_544 UImage
---@field Img_Award UImage
---@field kj01 kj01_C
---@field kj01_C_0 kj01_C
---@field kj01_C_1 kj01_C
---@field kj01_C_2 kj01_C
---@field kj01_C_3 kj01_C
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")

local UI14 = { bInitDoOnce = false }

local LotteryType = {
    Title = 1,
    Weapon = 2,
    Wing = 3,
}

local LotteryConfigs = {
    [LotteryType.Title] = {
        Name = "Title",
        Awards = {},
    },
    [LotteryType.Weapon] = {
        Name = "Weapon",
        Awards = {},
    },
    [LotteryType.Wing] = {
        Name = "Wing",
        Awards = {},
    },
}

function UI14:Construct()
    self:LuaInit()
end

function UI14:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true
    self.SelectedLotteryType = LotteryType.Weapon

    self:BindButton(self.Btn_Close, self.Btn_Close_OnClicked)
    self:BindButton(self.Btn_FHSY, self.Btn_FHSY_OnClicked)
    self:BindButton(self.Btn_Title, self.Btn_Title_OnClicked)
    self:BindButton(self.Btn_Weapon, self.Btn_Weapon_OnClicked)
    self:BindButton(self.Btn_Wing, self.Btn_Wing_OnClicked)
    self:BindAwardSlots()
    self:Refresh()
end

function UI14:BindButton(Button, Callback)
    if Button == nil then
        return
    end

    Button.OnClicked:Add(Callback, self)
    UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
    UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
end

function UI14:Open()
    self:SetBattleUIVisible(false)
    self:Refresh()
    self:SetVisibility(ESlateVisibility.Visible)
end

function UI14:Btn_Close_OnClicked()
    self:Close()
end

function UI14:Btn_FHSY_OnClicked()
    self:Close()
end

function UI14:Btn_Title_OnClicked()
    self:SelectLotteryType(LotteryType.Title)
end

function UI14:Btn_Weapon_OnClicked()
    self:SelectLotteryType(LotteryType.Weapon)
end

function UI14:Btn_Wing_OnClicked()
    self:SelectLotteryType(LotteryType.Wing)
end

function UI14:Close()
    self:SetBattleUIVisible(true)
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UI14:SelectLotteryType(Type)
    if LotteryConfigs[Type] == nil then
        return
    end

    self.SelectedLotteryType = Type
    self:Refresh()
end

function UI14:Refresh()
    self:RefreshAwardSlots()
    self:RefreshAwardPreview(nil)
end

function UI14:GetAwardSlots()
    return {
        self.kj01,
        self.kj01_C_0,
        self.kj01_C_1,
        self.kj01_C_2,
        self.kj01_C_3,
    }
end

function UI14:BindAwardSlots()
    for Index, Slot in ipairs(self:GetAwardSlots()) do
        if Slot ~= nil and Slot.Btn_Summon ~= nil then
            Slot.LotterySlotIndex = Index
            Slot.Btn_Summon.OnClicked:Add(function()
                self:RequestLottery(Index)
            end, self)
            UIEffectUtil.SetButtonStateBrushSameAsNormal(Slot.Btn_Summon)
            UIEffectUtil.BindPressScale(self, Slot.Btn_Summon, Slot.Btn_Summon, 1.06, 1.0)
        end
    end
end

function UI14:RefreshAwardSlots()
    local Config = LotteryConfigs[self.SelectedLotteryType]
    local Awards = Config and Config.Awards or {}

    for Index, Slot in ipairs(self:GetAwardSlots()) do
        local Award = Awards[Index]
        if Slot ~= nil then
            Slot.LotteryAwardData = Award
            self:SetWidgetVisible(Slot, true)
            if Award ~= nil then
                self:SetAwardSlotImage(Slot, Award.IconPath)
            end
        end
    end
end

function UI14:SetAwardSlotImage(Slot, IconPath)
    if Slot == nil or IconPath == nil or IconPath == "" then
        return
    end

    local Texture = UE.LoadObject(IconPath)
    if Texture == nil then
        ugcprint("[UI14:SetAwardSlotImage] load failed: " .. tostring(IconPath))
        return
    end

    local Images = { Slot.Img_Best, Slot.Img1, Slot.Img2, Slot.Img3, Slot.Img4, Slot.Img5, Slot.Img6 }
    for _, Image in ipairs(Images) do
        if Image ~= nil then
            Image:SetBrushFromTexture(Texture)
        end
    end
end

function UI14:RefreshAwardPreview(Award)
    if Award == nil or self.Img_Award == nil then
        return
    end

    local Texture = UE.LoadObject(Award.IconPath)
    if Texture ~= nil then
        self.Img_Award:SetBrushFromTexture(Texture)
    end
end

function UI14:RequestLottery(SlotIndex)
    local Config = LotteryConfigs[self.SelectedLotteryType]
    local Award = Config and Config.Awards[SlotIndex] or nil
    if Award == nil then
        return
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        ugcprint("[UI14:RequestLottery] PlayerController is nil")
        return
    end

    UnrealNetwork.CallUnrealRPC(
        PlayerController,
        PlayerController,
        "Server_RequestLottery",
        self.SelectedLotteryType,
        SlotIndex
    )
end

function UI14:OnLotteryResult(LotteryTypeValue, SlotIndex, AwardItemID, AwardCount)
    if LotteryTypeValue ~= nil then
        self.SelectedLotteryType = tonumber(LotteryTypeValue) or self.SelectedLotteryType
    end

    local Config = LotteryConfigs[self.SelectedLotteryType]
    local Award = Config and Config.Awards[tonumber(SlotIndex) or 0] or nil
    self:Refresh()
    self:RefreshAwardPreview(Award)

    ugcprint("[UI14:OnLotteryResult] type="
        .. tostring(self.SelectedLotteryType)
        .. ", slot=" .. tostring(SlotIndex)
        .. ", item=" .. tostring(AwardItemID)
        .. ", count=" .. tostring(AwardCount))
end

function UI14:SetWidgetVisible(Widget, bVisible)
    if Widget ~= nil then
        Widget:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    end
end

function UI14:SetBattleUIVisible(isVisible)
    if isVisible then
        if self.HiddenBattleWidgets == nil then
            return
        end
        for _, Item in ipairs(self.HiddenBattleWidgets) do
            if Item.Widget ~= nil then
                Item.Widget:SetVisibility(Item.Visibility)
            end
        end
        self.HiddenBattleWidgets = nil
        return
    end

    self.HiddenBattleWidgets = {}
    local function HideWidget(Widget)
        if Widget == nil then
            return
        end
        table.insert(self.HiddenBattleWidgets, {
            Widget = Widget,
            Visibility = Widget:GetVisibility(),
        })
        Widget:SetVisibility(ESlateVisibility.Collapsed)
    end

    HideWidget(UGCWidgetManagerSystem.GetMainUI())
    HideWidget(UGCWidgetManagerSystem.GetMainControlUI())
    HideWidget(UGCWidgetManagerSystem.GetShootingUIPanel())
    HideWidget(UGCWidgetManagerSystem.GetSkillRootPanel())
end

function UI14:Destruct()
    self:SetBattleUIVisible(true)
end

return UI14
