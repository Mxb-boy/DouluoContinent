---@class NewUGCWidgetBlueprint2_C:UUserWidget
---@field Button_74 UButton
---@field CanvasPanel_0 UCanvasPanel
---@field Image_58 UImage
---@field Image_194 UImage
---@field TextBlock_0 UTextBlock
---@field TextBlock_77 UTextBlock
---@field TextBlock_262 UTextBlock
---@field TextBlock_263 UTextBlock
--Edit Below--
local NewUGCWidgetBlueprint2 = {}
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")

local RECOMMENDED_POWER_RED = { R = 1.0, G = 0.0, B = 0.0, A = 1.0 }

local function SetImageTexture(image, relativePath)
    if image == nil or relativePath == nil then
        return
    end

    local texturePath = UGCGameSystem.GetUGCResourcesFullPath(relativePath)
    local texture = UGCObjectUtility.LoadObject(texturePath)
    if texture == nil then
        ugcprint("[NewItem] Image texture load failed: " .. tostring(texturePath))
        return
    end
    image:SetBrushFromTexture(texture, true)
end

local function SetTextBlockColor(textBlock, color)
    if textBlock == nil or color == nil then
        return
    end

    local slateColor = {
        SpecifiedColor = {
            R = color.R,
            G = color.G,
            B = color.B,
            A = color.A,
        },
    }
    if textBlock.SetColorAndOpacity ~= nil then
        pcall(textBlock.SetColorAndOpacity, textBlock, slateColor)
    end
    if textBlock.ColorAndOpacity ~= nil and textBlock.ColorAndOpacity.SpecifiedColor ~= nil then
        textBlock.ColorAndOpacity.SpecifiedColor.R = color.R
        textBlock.ColorAndOpacity.SpecifiedColor.G = color.G
        textBlock.ColorAndOpacity.SpecifiedColor.B = color.B
        textBlock.ColorAndOpacity.SpecifiedColor.A = color.A
    end
end

function NewUGCWidgetBlueprint2:Construct()
end

--- 配置列表项显示
---@param index       number   区域序号（1-based）
---@param name        string   区域名称，如 "第一块区域"
---@param powerText   string   战力限制文本，如 "(1234550战力限制)"
---@param enabled     boolean  是否可点击
---@param onTeleport  function 点击回调 function(index)
---@param recommendedPowerText string 推荐战力文本，如 "（推荐战力123万）"
---@param meetsRecommendedPower boolean 是否达到推荐战力
---@param imagePath string Image_194 的纹理资源路径
function NewUGCWidgetBlueprint2:Setup(index, name, powerText, enabled, onTeleport, recommendedPowerText,
                                      meetsRecommendedPower, imagePath)
    ugcprint("[NewItem] Setup called: index=" .. tostring(index) .. " name=" .. tostring(name))
    self.TeleportIndex = index
    self.OnTeleport = onTeleport

    SetImageTexture(self.Image_194, imagePath)

    ugcprint("[NewItem] TextBlock_77=" .. tostring(self.TextBlock_77) .. " TextBlock_262=" .. tostring(self.TextBlock_262) .. " Button_74=" .. tostring(self.Button_74))

    if self.TextBlock_77 then
        self.TextBlock_77:SetText(name)
    end

    if self.TextBlock_262 then
        self.TextBlock_262:SetText(powerText)
    end

    if self.TextBlock_0 then
        self.TextBlock_0:SetText(recommendedPowerText)
        if not meetsRecommendedPower then
            SetTextBlockColor(self.TextBlock_0, RECOMMENDED_POWER_RED)
        end
    end

    if self.Button_74 then
        self.Button_74:SetIsEnabled(enabled)
        UIEffectUtil.SetButtonStateBrushSameAsNormal(self.Button_74)
        UIEffectUtil.BindPressScale(self, self.Button_74, self.Button_74, 1.06, 1.0)
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
