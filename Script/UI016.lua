---@class UI016_C:UUserWidget
---@field Button_0 UButton
---@field Button_71 UButton
---@field Button_100 UButton
---@field Button_105 UButton
---@field Button_106 UButton
---@field Button_107 UButton
---@field Button_108 UButton
---@field Button_109 UButton
---@field Button_110 UButton
---@field Button_111 UButton
---@field Button_112 UButton
---@field Button_113 UButton
---@field Button_114 UButton
---@field Button_115 UButton
---@field CanvasPanel_45 UCanvasPanel
---@field Image_0 UImage
---@field Image_1 UImage
---@field Image_2 UImage
---@field Image_3 UImage
---@field Image_31 UImage
---@field Image_32 UImage
---@field Image_33 UImage
---@field Image_181 UImage
---@field Image_190 UImage
---@field Image_200 UImage
---@field Image_201 UImage
---@field Image_202 UImage
---@field Image_203 UImage
---@field Image_204 UImage
---@field Image_205 UImage
---@field Image_206 UImage
---@field Image_207 UImage
---@field Image_208 UImage
---@field Image_209 UImage
---@field Image_210 UImage
---@field Image_211 UImage
---@field Image_212 UImage
---@field Image_213 UImage
---@field Image_214 UImage
---@field Image_215 UImage
---@field Image_216 UImage
---@field Image_217 UImage
---@field Image_218 UImage
---@field Image_219 UImage
---@field Image_220 UImage
---@field Image_221 UImage
---@field Image_269 UImage
---@field Image_270 UImage
---@field Image_271 UImage
---@field Image_272 UImage
---@field TextBlock_162 UTextBlock
---@field TextBlock_165 UTextBlock
---@field TextBlock_166 UTextBlock
--Edit Below--
local UI016 = { bInitDoOnce = false }

local TJ_CONFIG_TABLE_PATH = "Data/Table/Customized/TjConfig"
local TJ_CONFIG_FULL_PATH = "Asset/Data/Table/Customized/TjConfig.TjConfig"

local TJ_BUTTON_ROWS = {
    { ButtonName = "Button_100", RowName = "001" },
    { ButtonName = "Button_105", RowName = "002" },
    { ButtonName = "Button_106", RowName = "003" },
    { ButtonName = "Button_107", RowName = "004" },
    { ButtonName = "Button_108", RowName = "005" },
    { ButtonName = "Button_109", RowName = "006" },
    { ButtonName = "Button_110", RowName = "007" },
    { ButtonName = "Button_111", RowName = "008" },
    { ButtonName = "Button_112", RowName = "009" },
    { ButtonName = "Button_113", RowName = "010" },
    { ButtonName = "Button_114", RowName = "011" },
    { ButtonName = "Button_115", RowName = "012" },
}

local DETAIL_ICON_NAMES = { "Image_271" }
local DETAIL_NAME_TEXT_NAMES = { "TextBlock_162" }
local DETAIL_DESC_TEXT_NAMES = { "TextBlock_165" }
local DETAIL_GET_TEXT_NAMES = { "TextBlock_166" }

function UI016:Construct()
    self:LuaInit()
end

function UI016:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    self:HideTjDetail()

    if self.Button_0 ~= nil then
        self.Button_0.OnClicked:Add(self.Button_0_OnClicked, self)
    end
    if self.Button_71 ~= nil then
        self.Button_71.OnClicked:Add(self.Button_71_OnClicked, self)
    end

    for _, ButtonInfo in ipairs(TJ_BUTTON_ROWS) do
        local Button = self[ButtonInfo.ButtonName]
        if Button ~= nil then
            local RowName = ButtonInfo.RowName
            Button.OnClicked:Add(function()
                self:OpenTjDetail(RowName)
            end)
        end
    end
end

function UI016:Button_0_OnClicked()
    self:HideTjDetail()
end

function UI016:Button_71_OnClicked()
    self:CloseSelf()
end

function UI016:CloseSelf()
    self:HideTjDetail()
    if self.SetVisibility ~= nil then
        self:SetVisibility(ESlateVisibility.Collapsed)
    elseif self.RemoveFromParent ~= nil then
        self:RemoveFromParent()
    end
end

function UI016:HideTjDetail()
    if self.CanvasPanel_45 ~= nil then
        self.CanvasPanel_45:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UI016:OpenTjDetail(RowName)
    local RowData = self:GetTjConfigRow(RowName)
    if RowData == nil then
        ugcprint(string.format("[UI016:OpenTjDetail] TjConfig row not found: %s", tostring(RowName)))
        return
    end

    self:RefreshTjDetail(RowData)

    if self.CanvasPanel_45 ~= nil then
        self.CanvasPanel_45:SetVisibility(ESlateVisibility.Visible)
    end
end

function UI016:GetTjConfigRow(RowName)
    local RowData = nil

    if UGCGameSystem.GetTableDataByRowName ~= nil then
        RowData = UGCGameSystem.GetTableDataByRowName(TJ_CONFIG_TABLE_PATH, RowName)
        if RowData ~= nil then
            return RowData
        end

        local FullPath = UGCGameSystem.GetUGCResourcesFullPath(TJ_CONFIG_FULL_PATH)
        RowData = UGCGameSystem.GetTableDataByRowName(FullPath, RowName)
        if RowData ~= nil then
            return RowData
        end
    end

    if UGCGameSystem.GetTableData ~= nil then
        local TableData = UGCGameSystem.GetTableData(TJ_CONFIG_TABLE_PATH)
        if TableData ~= nil then
            return TableData[RowName] or TableData[tonumber(RowName)]
        end
    end

    return nil
end

function UI016:RefreshTjDetail(RowData)
    self:SetTextByNames(DETAIL_NAME_TEXT_NAMES, RowData.Name or "")
    self:SetTextByNames(DETAIL_DESC_TEXT_NAMES, RowData.JS or "")
    self:SetTextByNames(DETAIL_GET_TEXT_NAMES, RowData.HQTJ or "")
    self:SetImageByNames(DETAIL_ICON_NAMES, RowData.tp)
end

function UI016:SetTextByNames(WidgetNames, Text)
    for _, WidgetName in ipairs(WidgetNames) do
        local Widget = self[WidgetName]
        if Widget ~= nil and Widget.SetText ~= nil then
            Widget:SetText(tostring(Text or ""))
            return true
        end
    end
    return false
end

function UI016:SetImageByNames(WidgetNames, ImagePath)
    local Texture = self:LoadTjTexture(ImagePath)
    if Texture == nil then
        return false
    end

    for _, WidgetName in ipairs(WidgetNames) do
        local Widget = self[WidgetName]
        if Widget ~= nil and Widget.SetBrushFromTexture ~= nil then
            Widget:SetBrushFromTexture(Texture)
            return true
        end
    end
    return false
end

function UI016:LoadTjTexture(ImagePath)
    local RealPath = self:NormalizeTjAssetPath(ImagePath)
    if RealPath == nil or RealPath == "" or UE.LoadObject == nil then
        return nil
    end

    return UE.LoadObject(RealPath)
end

function UI016:NormalizeTjAssetPath(ImagePath)
    if ImagePath == nil then
        return nil
    end

    local PathString = tostring(ImagePath)
    local ResourcePath = string.match(PathString, "GetUGCResourcesFullPath%(['\"]([^'\"]+)['\"]%)")
    if ResourcePath ~= nil then
        return UGCGameSystem.GetUGCResourcesFullPath(ResourcePath)
    end

    if string.sub(PathString, 1, 5) == "/Game" then
        return PathString
    end

    return UGCGameSystem.GetUGCResourcesFullPath(PathString)
end

-- function UI016:Tick(MyGeometry, InDeltaTime)
-- end
-- function UI016:Destruct()
-- end
return UI016
