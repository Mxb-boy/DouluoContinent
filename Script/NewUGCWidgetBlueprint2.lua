---@class NewUGCWidgetBlueprint2_C:UUserWidget
---@field Button_74 UButton
---@field CanvasPanel_0 UCanvasPanel
---@field Image_58 UImage
---@field Image_194 UImage
---@field TextBlock_77 UTextBlock
---@field TextBlock_262 UTextBlock
---@field TextBlock_263 UTextBlock
--Edit Below--
local NewUGCWidgetBlueprint2 = {}

function NewUGCWidgetBlueprint2:Construct()
end

--- 配置列表项显示
---@param index       number   区域序号（1-based）
---@param name        string   区域名称，如 "第一块区域"
---@param powerText   string   战力限制文本，如 "(1234550战力限制)"
---@param enabled     boolean  是否可点击
---@param onTeleport  function 点击回调 function(index)
function NewUGCWidgetBlueprint2:Setup(index, name, powerText, enabled, onTeleport)
    ugcprint("[NewItem] Setup called: index=" .. tostring(index) .. " name=" .. tostring(name))
    self.TeleportIndex = index
    self.OnTeleport = onTeleport

    ugcprint("[NewItem] TextBlock_77=" .. tostring(self.TextBlock_77) .. " TextBlock_262=" .. tostring(self.TextBlock_262) .. " Button_74=" .. tostring(self.Button_74))

    if self.TextBlock_77 then
        self.TextBlock_77:SetText(name)
    end

    if self.TextBlock_262 then
        self.TextBlock_262:SetText(powerText)
    end

    if self.Button_74 then
        self.Button_74:SetIsEnabled(enabled)
        -- 不调用 Clear()，UnLua 中可能不存在该方法
        -- 直接 Add 即可，因为 widget 是每次新建的
        self.Button_74.OnClicked:Add(self.OnButtonClicked, self)
    end
    ugcprint("[NewItem] Setup done: index=" .. tostring(index))
end

function NewUGCWidgetBlueprint2:OnButtonClicked()
    if self.OnTeleport then
        self.OnTeleport(self.TeleportIndex)
    end
end

return NewUGCWidgetBlueprint2
