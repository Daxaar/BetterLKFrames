local function castInfo(unit)
    local n,_,display,icon,startMs,endMs,_,_,blocked=UnitCastingInfo(unit)
    if n then return display or n,icon,startMs/1000,endMs/1000,false,blocked end
    local cn,_,ct,ci,cs,ce,_,cb=UnitChannelInfo(unit)
    if cn then return ct or cn,ci,cs/1000,ce/1000,true,cb end
end
function addon:UpdateCasts()
    for _,name in ipairs({"CastingBarFrame","PetCastingBarFrame","TargetFrameSpellBar","FocusFrameSpellBar"}) do
        local f=_G[name]
        if f and f.blkTime then
            local u=f.unit or (name=="CastingBarFrame" and "player") or (name=="PetCastingBarFrame" and "pet")
            local n,_,start,finish=castInfo(u or "target")
            f.blkTime:SetText(self.db.enabled and self.db.castTimers and n and string.format("%.1f",math.max(0,finish-GetTime())) or "")
        end
    end
    for _,f in pairs(self.castbars) do
        local n,icon,start,finish,channel,blocked=castInfo(f.unit)
        if self.db.enabled and self.db.partyCastbars and n and UnitExists(f.unit) then
            f:SetMinMaxValues(0,math.max(0.01,finish-start));f:SetValue(channel and math.max(0,finish-GetTime()) or math.max(0,GetTime()-start))
            if blocked then f:SetStatusBarColor(0.5,0.5,0.5)
            elseif channel then f:SetStatusBarColor(0.3,0.65,1) else f:SetStatusBarColor(1,0.75,0.15) end
            f.name:SetText(n);f.time:SetText(string.format("%.1f",math.max(0,finish-GetTime())));f:Show()
        else f:Hide() end
    end
end
