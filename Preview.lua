-- Visual-only samples. Native layout routines receive ONLY our scratch frames.
local addon=BetterLKFrames
local white="Interface\\Buttons\\WHITE8X8"
local samples={
    {name="Fortitude sample",icon="Spell_Holy_WordFortitude",id=21562,duration=60,remaining=45},
    {name="Expiring debuff sample",icon="Spell_Frost_FrostBolt02",id=116,duration=8,remaining=2},
    {name="Permanent debuff sample",icon="Spell_Shadow_AbominationExplosion",id=172,duration=0,remaining=0},
}
local contexts={{name="PlayerFrame",unit="player"},{name="TargetFrame",unit="target"},{name="FocusFrame",unit="focus"}}
local function group(context,index,fallback)
    local f=CreateFrame("Frame",nil,UIParent);f:Hide();f:EnableMouse(false);f:SetFrameStrata("DIALOG")
    f.context=context;f.index=index;f.samples={};f.slots={Buff={},Debuff={}};f.fallback=fallback
    f.title=f:CreateFontString(nil,"OVERLAY");f.title:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
    f.title:SetPoint("TOPLEFT",5,-4);f.title:SetText("TEST player (fallback)");f.title:SetTextColor(1,.85,.25)
    if fallback then
        f:SetWidth(180);f:SetHeight(72)
        f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
        f:SetBackdropColor(.035,.045,.055,.95);f:SetBackdropBorderColor(.7,.6,.2,1)
    else
        f.title:Hide()
        f.buffs=CreateFrame("Frame",nil,f);f.buffs:Hide()
        f.debuffs=CreateFrame("Frame",nil,f);f.debuffs:Hide()
    end
    return f
end
local function slot(g,kind,index)
    local b=g.slots[kind][index]
    if b then return b end
    local name=not g.fallback and "BetterLKFramesPreview"..g.context.name..kind..index or nil
    b=CreateFrame("Frame",name,g);b:EnableMouse(false);b:Hide()
    if name and kind=="Debuff" then
        local border=CreateFrame("Frame",name.."Border",b);border:EnableMouse(false);border:Hide()
    end
    g.slots[kind][index]=b
    return b
end
local function visual(button,data)
    button.data=data
    if button.visual then return end
    button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetAllPoints(button)
    local f=CreateFrame("Frame",nil,button);f:SetAllPoints(button);f:EnableMouse(false)
    f.time=f:CreateFontString(nil,"OVERLAY");f.time:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
    addon:PositionAuraTimer(f.time,button)
    f.edge=CreateFrame("Frame",nil,f);f.edge:SetAllPoints(button);f.edge:EnableMouse(false)
    f.edge:SetBackdrop({edgeFile=white,edgeSize=2});f.edge:Hide()
    f.cooldown=CreateFrame("Cooldown",nil,button,"CooldownFrameTemplate")
    f.cooldown:SetAllPoints(button);f.cooldown:EnableMouse(false);f.cooldown:Hide()
    f:SetFrameLevel(f.cooldown:GetFrameLevel()+2)
    f.testLabel=f:CreateFontString(nil,"OVERLAY");f.testLabel:SetFont(STANDARD_TEXT_FONT,8,"OUTLINE")
    f.testLabel:SetPoint("BOTTOM",button,"TOP",0,1);f.testLabel:SetText("TEST");f.testLabel:SetTextColor(1,.85,.25)
    button.visual=f
end
local function resetGroup(g,clearExpiry)
    if clearExpiry then g:Hide() end
    g.mode=nil;g.samples={}
    for _,list in pairs(g.slots) do for _,b in pairs(list) do
        b.previewShown=false;b.nativeSlot=nil
        if not clearExpiry then b:ClearAllPoints() end
        if clearExpiry then
            b:Hide();b.expires=nil
            if b.visual then b.visual:Hide();b.visual.cooldown:Hide();b.visual.cooldownExpiry=nil end
        end
    end end
end
local function occupied(context,kind,index)
    local fn=kind=="Buff" and UnitBuff or UnitDebuff
    return fn(context.unit,index)~=nil
end
local function realButtons(context)
    local buttons={}
    for _,kind in ipairs({"Buff","Debuff"}) do
        local prefix=context.unit=="player" and (kind=="Buff" and "BuffButton" or "DebuffButton") or context.name..kind
        for i=1,40 do
            local b=_G[prefix..i]
            if b and b:IsShown() and occupied(context,kind,i) then buttons[#buttons+1]=b end
        end
    end
    return buttons
end
local function rect(frame)
    local x,y=frame:GetLeft(),frame:GetBottom()
    if not x or not y then return end
    local scale=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    return x*scale,y*scale,(x+frame:GetWidth())*scale,(y+frame:GetHeight())*scale
end
local function clearOfReal(button,actual)
    local x,y,r,t=rect(button);if not x then return false end
    for _,b in ipairs(actual) do
        local bx,by,br,bt=rect(b)
        if not bx or (x<br and r>bx and y<bt and t>by) then return false end
    end
    return true
end
local function addSample(g,b,data)
    visual(b,data);b.icon:SetTexture("Interface\\Icons\\"..data.icon)
    g.samples[#g.samples+1]=b
end
local function playerPositions(g)
    -- Player layout is a global-only routine (consolidation, enchants and row spacing).
    -- Mirror vacant slots with resolved native anchors, never substitute global buttons.
    g:ClearAllPoints();g:SetAllPoints(UIParent);g:SetScale(1)
    local used={}
    for i,data in ipairs(samples) do
        local kind=i==1 and "Buff" or "Debuff"
        local prefix=kind=="Buff" and "BuffButton" or "DebuffButton"
        local found
        for index=1,(kind=="Buff" and 32 or 16) do
            local b=_G[prefix..index]
            if b and not used[b] and not b:IsShown() and not occupied(g.context,kind,index) and
                b:GetNumPoints()>0 and b:GetLeft() and b:GetBottom() and b:GetWidth()>0 and b:GetHeight()>0 then
                found=b;break
            end
        end
        if not found then return false end
        used[found]=true
        local b=slot(g,kind,i)
        b:SetScale(found:GetEffectiveScale()/UIParent:GetEffectiveScale())
        b:SetWidth(found:GetWidth());b:SetHeight(found:GetHeight())
        b:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",found:GetLeft(),found:GetBottom())
        b.nativeSlot=found
        addSample(g,b,data)
    end
    return true
end
local function targetPositions(g,owner)
    if type(TargetFrame_UpdateAuraPositions)~="function" or type(TargetFrame_UpdateBuffAnchor)~="function" or
        type(TargetFrame_UpdateDebuffAnchor)~="function" then return false end
    if not owner:GetLeft() or not owner:GetBottom() then return false end
    -- Copy geometry into UIParent space; never join a protected native anchor family.
    g:ClearAllPoints();g:SetScale(owner:GetEffectiveScale()/UIParent:GetEffectiveScale())
    g:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",owner:GetLeft(),owner:GetBottom())
    g:SetWidth(owner:GetWidth());g:SetHeight(owner:GetHeight());g.unit=g.context.unit;g.auraRows=0
    local counts,large={},{}
    local caps={Buff=owner.maxBuffs or 32,Debuff=owner.maxDebuffs or 16}
    for _,kind in ipairs({"Buff","Debuff"}) do
        local count=0;large[kind]={}
        for i=1,caps[kind] do
            local native=_G[g.context.name..kind..i]
            if native and native:IsShown() and occupied(g.context,kind,i) then
                count=i;large[kind][i]=native:GetWidth()>=21
            end
        end
        local amount=math.min(caps[kind]-count,kind=="Buff" and 1 or 2)
        counts[kind]=count+amount
        for i=1,counts[kind] do slot(g,kind,i) end
        for i=1,amount do
            local b=slot(g,kind,count+i);b:SetScale(1)
            large[kind][count+i]=true
            addSample(g,b,samples[kind=="Buff" and 1 or i+1])
        end
    end
    if #g.samples==0 then return false end
    local tot=owner.totFrame and owner.totFrame:IsShown()
    local width=tot and (owner.TOT_AURA_ROW_WIDTH or 101) or 122
    local prefix="BetterLKFramesPreview"..g.context.name
    TargetFrame_UpdateAuraPositions(g,prefix.."Buff",counts.Buff,counts.Debuff,large.Buff,TargetFrame_UpdateBuffAnchor,width,3)
    width=tot and g.auraRows<2 and (owner.TOT_AURA_ROW_WIDTH or 101) or 122
    TargetFrame_UpdateAuraPositions(g,prefix.."Debuff",counts.Debuff,counts.Buff,large.Debuff,TargetFrame_UpdateDebuffAnchor,width,4)
    -- Apply our existing root-gap option to scratch anchors only, once per fresh layout.
    local gap=addon.db.bigBars and addon.db.auraOffset or 0
    if gap>0 then for _,kind in ipairs({"Buff","Debuff"}) do
        local b=g.slots[kind][1]
        if b then
            local p,relative,rp,x,y=b:GetPoint(1)
            if relative==g then b:ClearAllPoints();b:SetPoint(p,relative,rp,x,y-gap) end
        end
    end end
    return true
end
local function finishGroup(g)
    local count=0
    for _,list in pairs(g.slots) do for _,b in pairs(list) do
        if b.previewShown then count=count+1
        else
            b:Hide()
            if b.visual then b.visual:Hide();b.visual.cooldown:Hide();b.visual.cooldownExpiry=nil end
        end
    end end
    if count>0 then g:Show() else g:Hide() end
    return count
end
local function paint(g,actual)
    local shown=0
    for _,b in ipairs(g.samples) do
        if g.fallback or clearOfReal(b,actual) then
            local data=b.data
            if not b.expires or b.expires<=GetTime() then b.expires=GetTime()+data.remaining end
            b.previewShown=true;b:Show();addon:PaintAura(b,b.visual,data.name,data.duration,b.expires,data.id)
            if g.fallback then b.visual.testLabel:Hide() else b.visual.testLabel:Show() end
            shown=shown+1
        end
    end
    finishGroup(g)
    return shown
end
function addon:SetTestAuras(value)
    if value and (InCombatLockdown() or not self.db.enabled or not self.options or not self.options:IsShown() or
        not self.auraOptionsPage or not self.auraOptionsPage:IsShown()) then
        self:Message("Aura previews require enabled settings on Casts / auras outside combat.");value=false
    end
    self.testAuras=value and true or false
    if self.testAuras then self:UpdateTestAuras()
    else
        for _,g in ipairs(self.auraPreviews or {}) do resetGroup(g,true) end
        if self.auraPreviewFallback then resetGroup(self.auraPreviewFallback,true) end
        if self.auraPreviewStatus then self.auraPreviewStatus:Hide() end
    end
    if self.RefreshOptions then self:RefreshOptions() end
    return self.testAuras
end
function addon:UpdateTestAuras()
    if not self.testAuras then return end
    if InCombatLockdown() or not self.db.enabled or not self.options:IsShown() or not self.auraOptionsPage:IsShown() then
        self:SetTestAuras(false);return
    end
    if not self.auraPreviews then
        self.auraPreviews={}
        for i,c in ipairs(contexts) do self.auraPreviews[i]=group(c,i,false) end
        self.auraPreviewFallback=group(contexts[1],1,true)
    end
    local visible,playerVisible=0,0
    for _,g in ipairs(self.auraPreviews) do
        resetGroup(g,false)
        local owner=_G[g.context.name]
        if owner and owner:IsShown() and UnitExists(g.context.unit) then
            local positioned
            if g.context.unit=="player" then positioned=playerPositions(g) else positioned=targetPositions(g,owner) end
            if positioned then
                g.mode="native"
                local count=paint(g,realButtons(g.context));visible=visible+count
                if g.context.unit=="player" then playerVisible=count end
            end
        end
        finishGroup(g)
    end
    local fallback=self.auraPreviewFallback;resetGroup(fallback,false)
    if playerVisible==0 then
        fallback:ClearAllPoints();fallback:SetPoint("TOPLEFT",self.auraOptionsPage,"TOPLEFT",0,-395)
        for i,data in ipairs(samples) do
            local b=slot(fallback,"Buff",i);b:SetScale(1);b:SetWidth(26);b:SetHeight(26)
            b:SetPoint("TOPLEFT",fallback,"TOPLEFT",8+(i-1)*50,-22);addSample(fallback,b,data)
        end
        fallback.mode="fallback";paint(fallback,{})
    end
    finishGroup(fallback)
    if self.auraPreviewStatus then
        self.auraPreviewStatus:SetText("TEST: "..visible.." native-position samples. "..
            (playerVisible==0 and "Single player fallback: native slots unavailable; appearance only." or "Occupied real icons are left untouched."))
        self.auraPreviewStatus:Show()
    end
end
