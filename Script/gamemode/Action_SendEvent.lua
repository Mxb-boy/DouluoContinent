local Action_SendEvent = 
{
	SendEventName = "";
}


function Action_SendEvent:Execute()

    LuaQuickFireEvent(self.SendEventName, self);

    return true;
end


return Action_SendEvent