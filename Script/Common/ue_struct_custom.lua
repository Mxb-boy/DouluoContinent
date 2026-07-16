-- auto exported UStruct while compiling 

-- sorted by struct name asc 

---@class FSignInEventData
---@field EventID int32
---@field DayNum int32
---@field NextDayTime int32
---@field SupplementDayNum int32

---@class FTaskTemplateConfig
---@field TaskLineName FString

---@class FSignInEventConfig
---@field EventID int32
---@field EventName FString
---@field Type ESignInEventType
---@field StartTime FDateTime
---@field EndTime FDateTime
---@field Desc FString
---@field SupplementDay int32
---@field SupplementItemID int32
---@field SupplementItemNum int32
---@field AwardTablePath FSoftObjectPath
---@field HighLight7thDay bool

---@class ShopV2_ItemQuality
---@field ItemID int32
---@field QualityRank int32

---@class GiftPackData
---@field ID int32
---@field ItemID int32
---@field GiftPackType EGiftPackType
---@field OpenWay EGiftPackOpenType
---@field DropID int32
---@field DropGroupID int32

---@class ProgressItem
---@field ItemID int32
---@field ItemCount int32

---@class ProgressReward
---@field Progress int32
---@field ItemList ProgressItem[]
---@field Desc FString

---@class LotteryData
---@field ID int32
---@field GiftProgressRewards ProgressReward[]
---@field LotteryRule FString
---@field DailyDrawLimit int32
---@field DailyDrawGroup int32
---@field OverrideDropID int32
---@field DropGroupID int32
---@field DrawCostID int32
---@field TenDrawCostNum int32
---@field OverrideGuarantDropID int32
---@field GuarantDropGroupID int32
---@field IsFirstDrawDiscountOpen bool
---@field FirstDrawDiscountCost int32
---@field FirstDrawDiscountResetType ELotteryResetType
---@field OverrideFirstDrawGuarantDropID int32
---@field FirstDrawGuarantDropGroupID int32
---@field FirstDrawGuarantResetType ELotteryResetType
---@field OneDrawCostNum int32
---@field Name FString
---@field Icon FSoftObjectPath

---@class FSignInAward
---@field ItemID int32
---@field ItemNum int32

---@class UGCTemplateRowStruct_HunHuanConfig
---@field HunHuanID int32
---@field Add_Health int32
---@field Add_MaxHealth int32
---@field Add_Attack int32

---@class UGCTemplateRowStruct_JingJieConfig
---@field Name FString
---@field AddMaxHp int32
---@field AddAtk int32

---@class UGCTemplateRowStruct_LotteryAwardConfig
---@field ItemID int32
---@field PoolID int32
---@field Weight int32
---@field IconPath UTexture2D
---@field AwardIndex int32
---@field ItemName FText
---@field Count int32

---@class UGCTemplateRowStruct_LotteryPoolConfig
---@field PoolID int32
---@field PoolName FText
---@field GrandPrizeRound int32
---@field IsOpen bool

---@class UGCTemplateRowStruct_WqLevelConfig
---@field ID int32
---@field Name FText
---@field Level int32
---@field Attack int32
---@field SuccessRate int32
---@field KeepRate int32
---@field DownRate int32
---@field DestroyRate int32
---@field CL_0 int32
---@field CL_1 int32

---@class UGCTemplateRowStruct_WuQiConfig
---@field Name FText
---@field WPID int32
---@field ID int32
---@field MaxLevel int32

---@class LotteryDrawItemInfo
---@field ID int32
---@field Num int32
---@field DropType FString
---@field IsDrawTenth bool

---@class LotteryRecord
---@field DrawItemInfo LotteryDrawItemInfo
---@field DrawTime int32

---@class LotteryDrawInfo
---@field LotteryID int32
---@field LotteryRecords LotteryRecord[]
---@field TotalDrawTimes int32

---@class LotteryExchangeItemInfo
---@field ExchangeNum int32
---@field ExchangeTime int32

---@class LotteryExchangeInfo
---@field ProductID int32
---@field ExchangeInfo LotteryExchangeItemInfo[]

---@class LotteryGiftProgressReciveState
---@field Progress int32
---@field State bool

---@class LotteryGiftProgressInfo
---@field LotteryID int32
---@field ProgressInfo LotteryGiftProgressReciveState[]

---@class LotteryInfo
---@field LotteryGroup bool
---@field Lottery bool
---@field LotteryExchangeInfo bool
---@field LotteryGiftProgress bool
---@field LotterySkipAnim bool

---@class ShopV2_TabInfo
---@field TabID int32
---@field TabName FString
---@field TabShopName FString
---@field TabShopDesc FString

---@class FEventTabInfo
---@field EventID int32
---@field TabName FString
---@field ShowPeriod bool

---@class FPlayerLevelConfigRow
---@field  int32
---@field  int32
---@field  float
---@field  float

---@class FWaveExpConfigRow
---@field  int32
---@field  int32

---@class FWaveExpConfigRow
---@field  int32
---@field  int32

---@class FPlayerLevelConfigRow_IntTest1
---@field  int32
---@field  int32
---@field  float
---@field  float

---@class FPlayerLevelConfigRow
---@field  int32
---@field  int32
---@field  int32
---@field  int32

