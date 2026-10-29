-- Restyle only the existing secure party/pet buttons, outside combat. No secure
-- attributes, raid widgets, unit assignments, visibility drivers or scripts change.
local addon=BetterLKFrames
local white="Interface\\Buttons\\WHITE8X8"
local originals={}
local active={}
local petViews={}
local function remember(obj,points)
    if not obj then return end
    local s=originals[obj]
    if not s then
        s={alpha=obj:GetAlpha(),w=obj:GetWidth(),h=obj:GetHeight()}
        if obj.GetHitRectInsets then s.hit={obj:GetHitRectInsets()} end
        originals[obj]=s
    end
    if points and not s.points then
        s.points={};for i=1,obj:GetNumPoints() do s.points[i]={obj:GetPoint(i)} end
    end
end
local function place(obj,relative,point,x,y,w,h)
    if not obj then return end
    remember(obj,true);obj:ClearAllPoints();obj:SetPoint(point,relative,point,x,y)
    if w then obj:SetWidth(w) end;if h then obj:SetHeight(h) end
end
local function hide(obj) if obj then remember(obj);obj:SetAlpha(0) end end
local function compactArt(name,owner)
    for _,suffix in ipairs({"Portrait","Texture","VehicleTexture","Flash","Name","HealthBarText","ManaBarText"}) do hide(_G[name..suffix]) end
    hide(owner.portrait)
end
function addon:RestoreCompactParty()
    -- Called before the ordinary Apply, so its bar/text/theme choices remain the
    -- baseline when compact mode is disabled or another profile is selected.
    if InCombatLockdown() then return end
    for obj,s in pairs(originals) do
        if s.points then obj:ClearAllPoints();for _,p in ipairs(s.points) do obj:SetPoint(unpack(p)) end end
        obj:SetWidth(s.w);obj:SetHeight(s.h);obj:SetAlpha(s.alpha)
        if s.hit then obj:SetHitRectInsets(unpack(s.hit)) end
    end
    originals={}
    for _,e in ipairs(active) do
        e.compact=nil;if e.compactName then e.compactName:Hide() end
        if e.compactPanel then e.compactPanel:Hide() end
        for _,v in pairs(e.compactIcons or {}) do v.copy:Hide() end
    end
    active={};self.compactPartyActive=false
    for _,v in pairs(petViews) do v:Hide() end
end
local function title(frame)
    local t=frame:CreateFontString(nil,"OVERLAY");t:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
    t:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-1);t:SetWidth(140);t:SetHeight(11);t:SetJustifyH("LEFT")
    return t
end
local iconOrder={"RaidTargetIcon","LeaderIcon","GuideIcon","MasterIcon","ReadyCheck","Disconnect","PVPIcon","Status"}
local function iconRegion(src)
    if src.GetObjectType and src:GetObjectType()=="Texture" then return src end
    if src.GetRegions then
        for _,r in ipairs({src:GetRegions()}) do if r.GetObjectType and r:GetObjectType()=="Texture" then return r end end
    end
end
local function member(e,name)
    local owner=e.owner;local w,h=addon.db.compactWidth,addon.db.compactHeight
    remember(owner);owner:SetWidth(w);owner:SetHeight(h);owner:SetHitRectInsets(0,0,0,0)
    compactArt(name,owner);hide(e.name);hide(e.portrait)
    if not e.compactPanel then
        local f=CreateFrame("Frame",nil,owner);e.compactPanel=f;f:EnableMouse(false)
        f:SetFrameLevel(owner:GetFrameLevel()+5);f:SetAllPoints(owner)
        f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
        f:SetBackdropColor(.025,.025,.025,1);f:SetBackdropBorderColor(0,0,0,1)
    end
    e.compactPanel:Show()
    place(e.health,owner,"TOPLEFT",0,-14,w,h-26)
    remember(e.health.text,true);e.health.text:ClearAllPoints();e.health.text:SetPoint("CENTER",e.health,"CENTER",0,0)
    e.health.text:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE");e.health.text:SetWidth(w-6);e.health.text:SetHeight(h-26)
    if e.power then
        place(e.power,owner,"TOPLEFT",0,-(h-11),w,11)
        remember(e.power.text,true);e.power.text:ClearAllPoints();e.power.text:SetPoint("CENTER",e.power,"CENTER",0,0)
        e.power.text:SetFont(STANDARD_TEXT_FONT,9,"OUTLINE");e.power.text:SetWidth(w-6);e.power.text:SetHeight(11)
    end
    if not e.compactName then e.compactName=title(e.health) end
    e.compactName:ClearAllPoints();e.compactName:SetPoint("TOPLEFT",owner,"TOPLEFT",3,-1)
    e.compactName:SetWidth(w-6);e.compactName:SetHeight(12)
    e.compactIcons=e.compactIcons or {}
    for i,suffix in ipairs(iconOrder) do
        local src=_G[name..suffix]
        local region=src and iconRegion(src)
        if region then
            local v=e.compactIcons[i]
            if not v then
                local copy=e.health:CreateTexture(nil,"OVERLAY");copy:SetWidth(13);copy:SetHeight(13)
                v={source=src,region=region,copy=copy,suffix=suffix};e.compactIcons[i]=v
            end
            hide(src) -- Mirror state/art above our panel without reparenting native UI.
        end
    end
    e.compact=true;e.compactName:Show();active[#active+1]=e
end
local function pet(owner,name,unit,memberOwner)
    local native=_G[name.."HealthBar"] or owner.healthbar
    if not native then return end
    local w,h=addon.db.compactWidth,addon.db.compactHeight
    remember(owner);owner:SetWidth(w-12);owner:SetHeight(h-21)
    -- Blizzard switches the pet anchor between -27/-43 in combat. Reserving this
    -- height keeps both native chains clear of the taller body and pet overlay.
    owner:SetHitRectInsets(-11,11,h-39,0)
    compactArt(name,owner);hide(native)
    local v=petViews[owner]
    if not v then
        v=CreateFrame("StatusBar",nil,owner);petViews[owner]=v;v:EnableMouse(false)
        v:SetFrameLevel(owner:GetFrameLevel()+10);v:SetStatusBarTexture(white)
        v:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1});v:SetBackdropColor(.025,.025,.025,1)
        v:SetBackdropBorderColor(0,0,0,1);v.name=title(v)
    end
    v:ClearAllPoints();v:SetPoint("TOPLEFT",memberOwner,"TOPLEFT",12,-h-4)
    v:SetWidth(w-12);v:SetHeight(18);v.name:SetWidth(w-18)
    v.unit=unit;v.nativeFlash=_G[name.."Flash"];v:Show()
    for i=1,3 do
        local d=_G[name.."Debuff"..i]
        if d then place(d,memberOwner,"TOPLEFT",w+4+(i-1)*18,-h-4) end
    end
end
function addon:ApplyCompactParty()
    if InCombatLockdown() or not self.db.enabled or not self.db.compactParty then return end
    if GetNumRaidMembers and GetNumRaidMembers()>0 then return end
    self.compactPartyActive=true
    for i=1,4 do
        local name="PartyMemberFrame"..i;local e=self.frames[name]
        if e then
            member(e,name)
            for j=1,4 do
                local d=_G[name.."Debuff"..j]
                if d then place(d,e.owner,"TOPLEFT",self.db.compactWidth+4+(j-1)*18,-17) end
            end
            local cast=self.castbars[i]
            if cast then place(cast,e.owner,"TOPLEFT",self.db.compactWidth+4,-35,105,12) end
            local p=_G[name.."PetFrame"];if p then pet(p,name.."PetFrame","partypet"..i,e.owner) end

        end
    end
    -- The owner's pet keeps its own native position/interaction, adjacent to the
    -- player frame. Do not add a duplicate player button to the party group.
    local size=GetNumPartyMembers and GetNumPartyMembers() or (UnitExists("party1") and 1 or 0)
    if size>0 and self.frames.PetFrame then member(self.frames.PetFrame,"PetFrame") end
    self:RefreshCompactParty()
end
local function valueText(label,full,brief,width)
    label:SetText(full)
    if label.GetStringWidth and label:GetStringWidth()>width then label:SetText(brief) end
end
function addon:PaintCompactMember(e,u)
    if not e.compact then return end
    local w=self.db.compactWidth
    if e.name then e.name:SetAlpha(0) end
    if e.portrait then e.portrait:SetAlpha(0) end
    if e.flash then e.flash:SetAlpha(0) end
    e.compactName:SetText(UnitName(u) or "")
    local current,maximum=UnitHealth(u),math.max(1,UnitHealthMax(u))
    local percent=math.floor(100*current/maximum+.5)
    local status
    if UnitIsConnected and not UnitIsConnected(u) then status="Offline"
    elseif UnitIsDeadOrGhost(u) then status=DEAD or "Dead" end
    if status then e.health.text:SetText(status)
    elseif self.db.healthText then
        valueText(e.health.text,self.Short(current).." / "..self.Short(maximum).." ("..percent.."%)",self.Short(current).." ("..percent.."%)",w-6)
    else e.health.text:SetText("") end
    if e.power then
        if self.db.powerText then
            local value,max=UnitMana(u),UnitManaMax(u)
            valueText(e.power.text,self.Short(value).." / "..self.Short(max),self.Short(value),w-6)
        else e.power.text:SetText("") end
    end
    local count=0
    for i=1,#iconOrder do
        local v=e.compactIcons and e.compactIcons[i]
        if v then
            local source,region=v.source,v.region
            if source:IsShown() and region:IsShown() and region:GetTexture() and not (v.suffix=="PVPIcon" and self.db.hidePvp) then
                count=count+1;local copy=v.copy
                copy:SetTexture(region:GetTexture());copy:SetTexCoord(region:GetTexCoord())
                copy:SetVertexColor(region:GetVertexColor())
                if not InCombatLockdown() then
                    copy:ClearAllPoints()
                    -- First three fit in the header; overflow adjoins its edge.
                    if count<=3 then copy:SetPoint("TOPLEFT",e.owner,"TOPLEFT",w-14*count,-1)
                    else copy:SetPoint("TOPLEFT",e.owner,"TOPLEFT",w+4+(count-4)*14,-1) end
                end
                copy:Show()
            else v.copy:Hide() end
            source:SetAlpha(0)
        end
    end
    e.compactName:SetWidth(math.max(40,w-6-math.min(count,3)*14))
end
function addon:RefreshCompactParty()
    for _,e in ipairs(active) do self:PaintCompactMember(e,e.owner.unit or e.unit) end
    for _,v in pairs(petViews) do
        if v:IsShown() then
            if v.nativeFlash then v.nativeFlash:SetAlpha(0) end
            local u=v.unit;local maximum=math.max(1,UnitHealthMax(u))
            v:SetMinMaxValues(0,maximum);v:SetValue(UnitHealth(u));v:SetStatusBarColor(.2,.8,.3)
            local state=UnitIsDeadOrGhost(u) and (DEAD or "Dead") or (math.floor(100*UnitHealth(u)/maximum+.5).."%")
            v.name:SetText((UnitName(u) or "Pet").." "..state)
        end
    end
end
