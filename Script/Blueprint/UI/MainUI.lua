---@class MainUI_C:UUserWidget
---@field Button_0 UButton
--Edit Below--
local MainUI = { bInitDoOnce = false } 
local L_Event = UGCGameSystem.UGCRequire('Script.Lin.L_Event')

function MainUI:Construct()
	self:LuaInit();
	
end


-- function MainUI:Tick(MyGeometry, InDeltaTime)

-- end

-- function MainUI:Destruct()

-- end

-- [Editor Generated Lua] function define Begin:
function MainUI:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	self.Button_0.OnClicked:Add(self.Button_0_OnClicked, self);
	-- [Editor Generated Lua] BindingEvent End;
end

function MainUI:Button_0_OnClicked()
	L_Event:SendEvent("OnStartPoint", 1)
end

-- [Editor Generated Lua] function define End;

return MainUI