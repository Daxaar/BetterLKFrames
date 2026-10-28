-- Restyle only the existing secure party/pet buttons, outside combat. No secure
-- attributes, raid widgets, unit assignments, visibility drivers or scripts change.
local addon=BetterLKFrames
local white="Interface\\Buttons\\WHITE8X8"
local originals={}
local active={}
local petViews={}
local function remember(obj)
    if not obj or originals[obj] then return end
    local s={alpha=obj:GetAlpha(),points={},w=obj:GetWidth(),h=obj:GetHeight()}
    for i=1,obj:GetNumPoints() do s.points[i]={obj:GetPoint(i)} end
    if obj.GetHitRectInsets then s.hit={obj:GetHitRectInsets()} end
    originals[obj]=s
end
local function place(obj,relative,point,x,y,w,h)
    if not obj then return end
    remember(obj);obj:ClearAllPoints();obj:SetPoint(point,relative,point,x,y)
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
        obj:ClearAllPoints();for _,p in ipairs(s.points) do obj:SetPoint(unpack(p)) end
        obj:SetWidth(s.w);obj:SetHeight(s.h);obj:SetAlpha(s.alpha)
        if s.hit then obj:SetHitRectInsets(unpack(s.hit)) end
    end
    originals={}
    for _,e in ipairs(active) do
        e.compact=nil;if e.compactName then e.compactName:Hide() end
    end
    active={};self.compactPartyActive=false
    for _,v in pairs(petViews) do v:Hide() end
end
local function title(frame)
    local t=frame:CreateFontString(nil,"OVERLAY");t:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
    t:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-1);t:SetWidth(140);t:SetHeight(11);t:SetJustifyH("LEFT")
    return t
end
local function member(e,name)
    local owner=e.owner
    remember(owner);owner:SetWidth(146);owner:SetHeight(32);owner:SetHitRectInsets(0,0,0,0)
    compactArt(name,owner);hide(e.name);hide(e.portrait)
    place(e.health,owner,"TOPLEFT",0,0,146,26)
    remember(e.health.text)
    e.health.text:ClearAllPoints();e.health.text:SetPoint("BOTTOM",e.health,"BOTTOM",0,1)
    e.health.text:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
    if e.power then
        place(e.power,owner,"TOPLEFT",0,-27,146,5)
        e.power.text:SetText("") -- Resource amount is shown in the name line.
    end
    if not e.compactName then e.compactName=title(e.health) end
    e.compact=true;e.compactName:Show();active[#active+1]=e
end
local function pet(owner,name,unit)
    local native=_G[name.."HealthBar"] or owner.healthbar
    if not native then return end
    remember(owner);owner:SetWidth(123);owner:SetHitRectInsets(0,0,0,0)
    -- Keep native pet height and top-left anchor: Blizzard changes that anchor
    -- with pet visibility, and subsequent party members follow it in combat.
    compactArt(name,owner);hide(native)
    local v=petViews[owner]
    if not v then
        v=CreateFrame("StatusBar",nil,owner);petViews[owner]=v;v:EnableMouse(false)
        v:SetFrameLevel(owner:GetFrameLevel()+10);v:SetStatusBarTexture(white)
        v:SetPoint("TOPLEFT",owner,"TOPLEFT",0,0);v:SetWidth(123);v:SetHeight(18)
        v:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1});v:SetBackdropColor(.025,.025,.025,1)
        v:SetBackdropBorderColor(0,0,0,1);v.name=title(v);v.name:SetWidth(117)
    end
    v.unit=unit;v.nativeFlash=_G[name.."Flash"];v:Show()
    for i=1,3 do
        local d=_G[name.."Debuff"..i]
        if d then place(d,owner,"TOPLEFT",126+(i-1)*18,0) end
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
                if d then place(d,e.owner,"TOPLEFT",150+(j-1)*18,0) end
            end
            local cast=self.castbars[i]
            if cast then place(cast,e.owner,"TOPLEFT",150,-20,105,10) end
            local p=_G[name.."PetFrame"];if p then pet(p,name.."PetFrame","partypet"..i) end
            -- Keep native ready/leader/loot/status state, with readable anchors.
            for _,suffix in ipairs({"LeaderIcon","MasterIcon","GuideIcon","ReadyCheck","Status","Disconnect","PVPIcon","RaidTargetIcon"}) do
                local indicator=_G[name..suffix]
                if indicator then
                    local x=({LeaderIcon=220,GuideIcon=220,MasterIcon=236,ReadyCheck=252,Status=268,Disconnect=284,PVPIcon=300,RaidTargetIcon=316})[suffix]
                    place(indicator,e.owner,"TOPLEFT",x,0,14,14)
                end
            end
        end
    end
    -- The owner's pet keeps its own native position/interaction, adjacent to the
    -- player frame. Do not add a duplicate player button to the party group.
    local size=GetNumPartyMembers and GetNumPartyMembers() or (UnitExists("party1") and 1 or 0)
    if size>0 and self.frames.PetFrame then member(self.frames.PetFrame,"PetFrame") end
    self:RefreshCompactParty()
end
function addon:RefreshCompactParty()
    for _,e in ipairs(active) do
        local u=e.owner.unit or e.unit
        if e.name then e.name:SetAlpha(0) end
        if e.portrait then e.portrait:SetAlpha(0) end
        if e.flash then e.flash:SetAlpha(0) end
        local status
        if UnitIsConnected and not UnitIsConnected(u) then status="Offline"
        elseif UnitIsDeadOrGhost(u) then status=DEAD or "Dead" end
        local resource=e.power and self.db.powerText and ("  "..self:CompactResource(u)) or ""
        e.compactName:SetText((UnitName(u) or "")..resource)
        if status then e.health.text:SetText(status) end
        if e.power then e.power.text:SetText("") end
    end
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
function addon:CompactResource(u) return self.Short(UnitMana(u)) end
