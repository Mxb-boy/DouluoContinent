---@class UI_PlayerTitle_C:UUserWidget
---@field Btn_Title_10 UButton
---@field Btn_Title_11 UButton
---@field Btn_Title_12 UButton
---@field Btn_Title_13 UButton
---@field Btn_Title_14 UButton
---@field Btn_Title_15 UButton
---@field Btn_Title_01 UButton
---@field Btn_Title_02 UButton
---@field Btn_Title_03 UButton
---@field Btn_Title_04 UButton
---@field Btn_Title_05 UButton
---@field Btn_Title_06 UButton
---@field Btn_Title_07 UButton
---@field Btn_Title_08 UButton
---@field Btn_Title_09 UButton
--Edit Below--
local UI_PlayerTitle = {}

function UI_PlayerTitle:GetNamedWidget(widgetName)
    local widget = self[widgetName]
        or UGCWidgetManagerSystem.GetWidgetFromName(self, widgetName)
    self[widgetName] = widget
    return widget
end

function UI_PlayerTitle:SetWidgetHidden(widget)
    if widget ~= nil then
        widget:SetVisibility(ESlateVisibility.Hidden)
        if widget.SetRenderOpacity ~= nil then
            widget:SetRenderOpacity(0)
        end
    end
end

function UI_PlayerTitle:SetWidgetShown(widget)
    if widget ~= nil then
        widget:SetVisibility(ESlateVisibility.Visible)
        if widget.SetRenderOpacity ~= nil then
            widget:SetRenderOpacity(1)
        end
    end
end

function UI_PlayerTitle:HideAllTitles()
    for id = 1, 15 do
        self:SetWidgetHidden(self:GetNamedWidget(
            string.format("Btn_Title_%02d", id)
        ))
    end
end

function UI_PlayerTitle:SetTitle(titleID)
    titleID = tonumber(titleID) or 0
    self:HideAllTitles()
    if titleID <= 0 then
        return
    end

    local titleButton = self:GetNamedWidget(
        string.format("Btn_Title_%02d", titleID)
    )
    if titleButton == nil then
        ugcprint("[UI_PlayerTitle] Show title failed, button nil: "
            .. tostring(titleID))
        return
    end

    self:SetWidgetShown(titleButton)
end

function UI_PlayerTitle:ClearTitle()
    self:HideAllTitles()
end

return UI_PlayerTitle
