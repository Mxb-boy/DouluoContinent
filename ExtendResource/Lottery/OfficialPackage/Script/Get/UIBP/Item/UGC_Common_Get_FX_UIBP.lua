---@class UGC_Common_Get_FX_UIBP_C:UUserWidget
---@field DX_Flip UWidgetAnimation
---@field Button_ItemGet_Item UButton
---@field CanvasPanel_Name UCanvasPanel
---@field Image_Fragments UImage
---@field Image_ItemGet_Item_GoodsLogo UImage
---@field Image_ItemGet_Item_GoodsQualityBg UImage
---@field Image_ItemGet_Item_GoodsQualityLight UImage
---@field ItemSlot UCanvasPanel
---@field TextBlock_ItemGet_Item_GoodsAmount UTextBlock
---@field TextBlock_ItemGet_Item_GoodsDays UTextBlock
---@field TextBlock_ItemGet_Item_GoodsName UTextBlock
--Edit Below--
local LotteryConfig = UGCGameSystem.UGCRequire("Script.Common.LotteryConfig")
local UGC_Common_Get_FX_UIBP = { bInitDoOnce = false } 

local function SetItemIcon(Image, IconPath)
    if Image == nil or IconPath == nil or IconPath == "" then
        return
    end

    local Texture = IconPath
    if type(IconPath) == "string" then
        Texture = UE.LoadObject(IconPath)
    end
    if Texture ~= nil then
        Image:SetBrushFromTexture(Texture)
    end
end

function UGC_Common_Get_FX_UIBP:Construct()
	
end


-- function UGC_Common_Get_FX_UIBP:Tick(MyGeometry, InDeltaTime)

-- end

-- function UGC_Common_Get_FX_UIBP:Destruct()

-- end

function UGC_Common_Get_FX_UIBP:InitUI(ItemID, ItemNum)
    local ItemInfo = LotteryManager:GetItemConfigData(ItemID);
    local LotteryAward = LotteryConfig.GetAwardByItemID(ItemID)
    if ItemInfo then
        if ItemInfo.ItemIcon then
            SetItemIcon(self.Image_ItemGet_Item_GoodsLogo, ItemInfo.ItemIcon);
        end

        if ItemInfo.ItemName then
            self.TextBlock_ItemGet_Item_GoodsName:SetText(ItemInfo.ItemName);
        end
    end
    if LotteryAward ~= nil then
        if LotteryAward.IconPath ~= nil and LotteryAward.IconPath ~= "" then
            SetItemIcon(self.Image_ItemGet_Item_GoodsLogo, LotteryAward.IconPath);
        end
        if LotteryAward.Name ~= nil then
            self.TextBlock_ItemGet_Item_GoodsName:SetText(LotteryAward.Name);
        end
    end
    self.TextBlock_ItemGet_Item_GoodsAmount:SetText(tostring(ItemNum));
end

return UGC_Common_Get_FX_UIBP
