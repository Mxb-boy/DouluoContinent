L_Event =L_Event or{
    Events={};
};

function  L_Event:AddListener(EventType,Func,Object)
    if EventType==nil or Func==nil then
        return;
    end

    local FuncData={};
    FuncData.Object=Object;
    FuncData.Func=Func;

    if self.Events[EventType]==nil then
        local NewEventFuncs={};
        table.insert(NewEventFuncs,FuncData);
        self.Events[EventType] =NewEventFuncs;
        return true
    else    
        table.insert(self.Events[EventType],FuncData)
        return true
    end
end

function  L_Event:RemoveListener(EventType,Func,Object)
    if EventType==nil or Func==nil then
        return;
    end
    local EventFuncs=self.Events[EventType];
    if EventFuncs ~=nil then
        for i, FuncData in pairs(EventFuncs) do
            if FuncData.Func==Func and FuncData.Object==Object then
                EventFuncs[i]=nil;
                break
            end
            
        end
    end
    
end

function L_Event:RemoveAll()
    for k, EventFuncs in pairs(self.Events) do
        for i, FuncData in pairs(EventFuncs) do
            FuncData.Func=nil
            FuncData.Object=nil
        end
    end
    self.Events={}
end

function L_Event:SendEvent(EventType, ...)
    if EventType ~=nil then
        local EventFuncs=self.Events[EventType];
        if EventFuncs ~=nil then
            for i, FuncData in pairs(EventFuncs) do
                if FuncData.Object ~=nil then
                    FuncData.Func(FuncData.Object, ...);
                else    
                    FuncData.Func(...);

                end
            end
        end
    end
end


return L_Event
