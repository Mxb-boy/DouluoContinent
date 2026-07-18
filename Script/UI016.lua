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
--Edit Below--
local UI016 = { bInitDoOnce = false } 

function UI016:Construct()
    self:LuaInit()
end

function UI016:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    if self.Button_0 ~= nil then
        self.Button_0.OnClicked:Add(self.Button_0_OnClicked, self)
    end
end

function UI016:Button_0_OnClicked()
    if self.RemoveFromParent ~= nil then
        self:RemoveFromParent()
    elseif self.SetVisibility ~= nil then
        self:SetVisibility(ESlateVisibility.Collapsed)
    end
end

-- function UI016:Tick(MyGeometry, InDeltaTime)

-- end

-- function UI016:Destruct()

-- end

return UI016
