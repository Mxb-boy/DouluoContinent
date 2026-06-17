---@class TestButton_C:UUserWidget
---@field AddButton UButton
---@field ClearButton UButton
---@field ItemIDTextBox UEditableTextBox
---@field OpenButton UButton
---@field RemoveButton UButton
---@field ShowNumButton UButton
---@field TextBox UEditableTextBox
--Edit Below--
local TestButton = { bInitDoOnce = false } 

function TestButton:Construct()
	
    self.OpenButton.OnClicked:Add(self.OnOpenClick, self);
    self.ClearButton.OnClicked:Add(self.OnClearClick, self);
    self.AddButton.OnClicked:Add(self.OnAddClick, self);
    self.RemoveButton.OnClicked:Add(self.OnRemoveClick, self);
    self.ShowNumButton.OnClicked:Add(self.OnShowClick, self);
end

function TestButton:OnOpenClick()
    
    SignInEventManager:OpenMainUI();
end

function TestButton:OnClearClick()
    
    SignInEventManager:ClearData();
end

function TestButton:OnAddClick()

    if self.TextBox.Text == nil or self.TextBox.Text == "" then
        return;
    end
    
    local Table = {};
    local Sep = string.format("([^ ]+)");
    for Str in string.gmatch(self.TextBox.Text, Sep) do
        table.insert(Table, tonumber(Str)); 
    end

    local ItemID = Table[1];
    local Num = Table[2];

    if ItemID ~= nil and Num ~= nil then
        SignInEventManager:AddItem(ItemID, Num);
    end
end

function TestButton:OnRemoveClick()
    
    if self.TextBox.Text == nil or self.TextBox.Text == "" then
        return;
    end
    
    local Table = {};
    local Sep = string.format("([^ ]+)");
    for Str in string.gmatch(self.TextBox.Text, Sep) do
        table.insert(Table, tonumber(Str)); 
    end

    local ItemID = Table[1];
    local Num = Table[2];

    if ItemID ~= nil and Num ~= nil then
        SignInEventManager:RemoveItem(ItemID, Num);
    end
end

function TestButton:OnShowClick()
    
    if self.ItemIDTextBox.Text == nil or self.ItemIDTextBox.Text == "" then
        return;
    end

    local ItemID = tonumber(self.ItemIDTextBox.Text);

    if ItemID ~= nil then
        local Num = SignInEventManager:GetItemNum(ItemID);
        self.ItemIDTextBox:SetText(string.format("%d %d", ItemID, Num));
    end
end

-- function TestButton:Tick(MyGeometry, InDeltaTime)

-- end

-- function TestButton:Destruct()

-- end

return TestButton