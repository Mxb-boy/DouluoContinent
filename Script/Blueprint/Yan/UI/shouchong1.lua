---@class shouchong1_C:UUserWidget
---@field Btn_Close UButton
---@field Button_7 UButton
---@field Button_8 UButton
---@field Button_9 UButton
---@field Button_10 UButton
---@field Button_39 UButton
---@field Image_10 UImage
---@field Image_35 UImage
---@field Image_52 UImage
---@field Image_56 UImage
---@field Image_145 UImage
---@field Image_146 UImage
---@field Image_147 UImage
---@field Image_148 UImage
---@field Image_149 UImage
---@field Image_150 UImage
---@field Image_151 UImage
---@field Image_152 UImage
---@field Image_180 UImage
---@field Image_248 UImage
---@field Image_249 UImage
---@field Image_301 UImage
---@field Image_302 UImage
---@field Image_303 UImage
---@field Image_304 UImage
---@field Image_305 UImage
---@field Image_306 UImage
---@field Image_307 UImage
---@field Image_308 UImage
---@field Image_309 UImage
---@field Image_310 UImage
---@field Image_311 UImage
---@field Image_312 UImage
---@field Image_313 UImage
---@field Image_314 UImage
---@field Image_315 UImage
---@field Image_316 UImage
---@field Image_317 UImage
---@field Image_318 UImage
---@field Image_319 UImage
---@field Image_320 UImage
---@field Image_321 UImage
---@field Image_322 UImage
---@field Image_323 UImage
---@field Image_324 UImage
---@field Image_325 UImage
---@field Image_326 UImage
---@field Image_327 UImage
---@field Image_328 UImage
---@field Image_329 UImage
---@field Image_330 UImage
---@field Image_331 UImage
---@field Image_332 UImage
---@field Image_333 UImage
---@field Image_334 UImage
---@field Image_335 UImage
---@field Image_336 UImage
---@field Image_337 UImage
---@field Image_338 UImage
---@field Image_339 UImage
---@field Image_340 UImage
---@field Image_341 UImage
---@field Image_342 UImage
---@field Image_343 UImage
---@field Image_344 UImage
---@field Image_345 UImage
---@field Image_346 UImage
---@field Image_347 UImage
---@field Image_348 UImage
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local DirectBundlePurchaseService = UGCGameSystem.UGCRequire("Script.Common.DirectBundlePurchaseService")

local shouchong1 = { bInitDoOnce = false }

local PURCHASE_BUTTONS = {
    {ButtonName = "Button_39", PackKey = "NewPlayer"},
    {ButtonName = "Button_7", PackKey = "Deluxe"},
    {ButtonName = "Button_8", PackKey = "Forge"},
    {ButtonName = "Button_9", PackKey = "Realm"},
    {ButtonName = "Button_10", PackKey = "SoulRing"},
}

function shouchong1:Construct()
    self:LuaInit()
end

function shouchong1:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    for _, Entry in ipairs(PURCHASE_BUTTONS) do
        local Button = self[Entry.ButtonName]
        if Button ~= nil then
            local PackKey = Entry.PackKey
            if UIEffectUtil ~= nil then
                UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
                UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
            end
            Button.OnClicked:Add(function()
                self:PurchaseBundle(PackKey)
            end, self)
        end
    end

    if self.Btn_Close ~= nil then
        if UIEffectUtil ~= nil then
            UIEffectUtil.SetButtonStateBrushSameAsNormal(self.Btn_Close)
            UIEffectUtil.BindPressScale(self, self.Btn_Close, self.Btn_Close, 1.06, 1.0)
        end
        self.Btn_Close.OnClicked:Add(self.Btn_Close_OnClicked, self)
    end

    if DirectBundlePurchaseService ~= nil then
        DirectBundlePurchaseService:RecoverPendingPurchases()
    end
end

function shouchong1:PurchaseBundle(PackKey)
    if DirectBundlePurchaseService ~= nil then
        DirectBundlePurchaseService:Purchase(PackKey)
    end
end

function shouchong1:Btn_Close_OnClicked()
    if self.SetVisibility ~= nil then
        self:SetVisibility(ESlateVisibility.Collapsed)
    end
end

-- function shouchong1:Tick(MyGeometry, InDeltaTime)

-- end

-- function shouchong1:Destruct()

-- end

return shouchong1
