-- Original implementation. No BetterBlizzFrames code or assets are included.
local addon = CreateFrame("Frame")
BetterLKFrames = addon
local white = "Interface\\Buttons\\WHITE8X8"
local stock = "Interface\\TargetingFrame\\UI-StatusBar"
local defaults = {
    enabled = true, bigBars = true, classHealth = true, classNames = true,
    reactionHealth = true, healthGradient = false, flatBars = false,
    darkFrames = true, darkActionBars = true, darkMinimap = true, darkTooltip = false,
    classPortraits = false, hideCombatFlash = false, hidePvp = false,
    healthText = true, powerText = true, castTimers = true, partyCastbars = true,
    auraTimers = true, auraSpirals = true, auraWarnings = true,
    healthHeight = 22, powerHeight = 11, darkness = 0.28, frameScale = 1,
    castScale = 1, fontSize = 11, warningSeconds = 5,
    darkWindows = true, showGrid = true, auraOffset = 4,
    roundedBars = true, namesAbove = true, darkButtons = true, darkAuras = true,
    snapFrames = true, snapGrid = false, showGuides = true, snapDistance = 10, gridSize = 32,
    positions = {}, importantSpells = {}, profiles = {}, version = 3,
}
addon.defaults = defaults
addon.frames, addon.castbars, addon.auras = {}, {}, {}
local regions = setmetatable({}, {__mode = "k"})
local alphas = setmetatable({}, {__mode = "k"})
local dirty, elapsed, auraElapsed = true, 0, 0
local importantNames = {}
local function copy(t)
    if type(t) ~= "table" then return t end
    local r = {}; for k, v in pairs(t) do r[k] = copy(v) end; return r
end
addon.Copy = copy
local function normalize(db)
    if type(db) ~= "table" then db = {} end
    if db.version == 1 then
        -- One-time adoption of the requested v1.1 visual defaults. Keep layout/profiles.
        db.flatBars=false;db.classNames=true;db.version=2
    end
    if db.version == 2 then
        if db.powerHeight==8 then db.powerHeight=11 end
        if db.gridSize==8 then db.gridSize=32 end
        db.version=3
    end
    for k, v in pairs(defaults) do
        if type(db[k]) ~= type(v) then db[k] = copy(v) end
    end
    local ranges = {healthHeight={16,30},powerHeight={4,12},darkness={0.1,1},
        frameScale={0.65,1.6},castScale={0.6,2},fontSize={9,16},warningSeconds={0,10},snapDistance={2,24},gridSize={8,128},auraOffset={0,12}}
    for k, r in pairs(ranges) do
        if db[k] ~= db[k] then db[k] = defaults[k] end
        db[k] = math.max(r[1], math.min(r[2], db[k]))
    end
    return db
end
addon.Normalize = normalize
function addon:Message(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff7fddd0BetterLKFrames:|r " .. text)
end
local function unitOf(entry) return entry.owner.unit or entry.unit end
local function rememberAlpha(obj, hide)
    if not obj or not obj.SetAlpha then return end
    if alphas[obj] == nil then alphas[obj] = obj:GetAlpha() end
    obj:SetAlpha(hide and 0 or alphas[obj])
end
local function tint(texture, enabled)
    if not texture or not texture.SetVertexColor then return end
    if not regions[texture] then regions[texture] = {texture:GetVertexColor()} end
    local c = regions[texture]
    local f = enabled and addon.db.darkness or 1
    texture:SetVertexColor((c[1] or 1)*f, (c[2] or 1)*f, (c[3] or 1)*f, c[4] or 1)
end
local function border(frame)
    frame:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1,
        insets={left=1,right=1,top=1,bottom=1}})
    frame:SetBackdropColor(0.025,0.025,0.025,1)
    frame:SetBackdropBorderColor(0,0,0,1)
    frame:EnableMouse(false)
end
local function text(parent, size)
    local f = parent:CreateFontString(nil,"OVERLAY")
    f:SetFont(STANDARD_TEXT_FONT,size,"OUTLINE"); f:SetPoint("CENTER")
    f:SetTextColor(1,1,1); return f
end
local function short(n)
    if n >= 1000000 then return string.format("%.1fm",n/1000000) end
    if n >= 10000 then return string.format("%.1fk",n/1000) end
    return tostring(math.floor(n))
end
addon.Short = short
local function colour(unit)
    local db = addon.db
    if db.classHealth and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit); local c = RAID_CLASS_COLORS[class]
        if c then return c.r,c.g,c.b end
    end
    if db.healthGradient then
        local f = UnitHealth(unit)/math.max(1,UnitHealthMax(unit)); return 1-f,f,0.12
    end
    if db.reactionHealth and not UnitIsPlayer(unit) then return UnitSelectionColor(unit) end
    return 0.15,0.85,0.2
end
local function portrait(entry)
    local t = entry.portrait; if not t then return end
    local unit = unitOf(entry)
    if addon.db.enabled and addon.db.classPortraits and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
        if coords then
            t:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            t:SetTexCoord(unpack(coords)); entry.classPortrait = true; return
        end
    end
    if entry.classPortrait and UnitExists(unit) then
        t:SetTexCoord(0,1,0,1); SetPortraitTexture(t,unit); entry.classPortrait = false
    end
end
local function paint(entry)
    if not addon.db or not addon.db.enabled then return end
    local u = unitOf(entry)
    if not UnitExists(u) then return end
    local hp, maxhp = UnitHealth(u), math.max(1,UnitHealthMax(u))
    entry.health:SetMinMaxValues(0,maxhp); entry.health:SetValue(hp)
    entry.health:SetStatusBarColor(colour(u))
    if addon.db.healthText then
        if UnitIsDeadOrGhost(u) then entry.health.text:SetText(DEAD or "Dead")
        else
            local percent=math.floor(100*hp/maxhp+0.5)
            entry.health.text:SetText(entry.minor and (percent.."%") or (short(hp).." / "..short(maxhp).." ("..percent.."%)"))
        end
    else entry.health.text:SetText("") end
    if entry.power then
        local val, maximum = UnitMana(u), math.max(1,UnitManaMax(u))
        local token, kind = UnitPowerType(u); local c = PowerBarColor[kind] or PowerBarColor[token] or {r=0.2,g=0.45,b=1}
        if entry.originalPower:IsShown() then entry.power:Show() else entry.power:Hide() end
        entry.power:SetMinMaxValues(0,maximum); entry.power:SetValue(val)
        entry.power:SetStatusBarColor(c.r,c.g,c.b)
        entry.power.text:SetText(addon.db.powerText and (short(val).." / "..short(maximum)) or "")
    end
    if entry.name then
        if addon.db.classNames and UnitIsPlayer(u) then
            local _, class = UnitClass(u); local c = RAID_CLASS_COLORS[class]
            if c then entry.name:SetTextColor(c.r,c.g,c.b) end
        elseif entry.nameColour then entry.name:SetTextColor(unpack(entry.nameColour)) end
    end
    if addon.PaintName then addon:PaintName(entry,u) end
    portrait(entry)
    rememberAlpha(entry.flash,addon.db.hideCombatFlash)
    rememberAlpha(entry.pvp,addon.db.hidePvp)
end
function addon:Refresh()
    for _, entry in pairs(self.frames) do paint(entry) end
end
local function bar(parent, anchor)
    local f = CreateFrame("StatusBar",nil,parent); f:SetFrameLevel(parent:GetFrameLevel()+10)
    f:SetStatusBarTexture(stock); border(f)
    f:SetPoint("TOPLEFT",anchor,"TOPLEFT",0,0); f:SetWidth(anchor:GetWidth()); f:SetHeight(anchor:GetHeight())
    f.text = text(f,11); return f
end
local function register(name, unit, minor)
    if addon.frames[name] then return end
    local owner = _G[name]; if not owner then return end
    local h = owner.healthbar or _G[name.."HealthBar"]
    local m = owner.manabar or _G[name.."ManaBar"]
    if not h then return end
    local e = {owner=owner,unit=unit,originalHealth=h,originalPower=m,minor=minor,
        originalScale=owner:GetScale(),healthAlpha=h:GetAlpha(),powerAlpha=m and m:GetAlpha()}
    e.points = {}
    for i=1,owner:GetNumPoints() do e.points[i]={owner:GetPoint(i)} end
    e.nativeTexts = {}
    for _, obj in pairs({h.TextString or false,m and m.TextString or false,
        _G[name.."HealthBarText"] or false,_G[name.."ManaBarText"] or false,
        _G[name.."TextureFrameHealthBarText"] or false,_G[name.."TextureFrameManaBarText"] or false}) do
        if obj and obj.SetAlpha then e.nativeTexts[obj]=obj:GetAlpha() end
    end
    e.portrait = owner.portrait or _G[name.."Portrait"] or (name=="PlayerFrame" and PlayerPortrait)
    e.name = owner.name or _G[name.."Name"] or _G[name.."TextureFrameName"] or (name=="PlayerFrame" and PlayerName)
    if e.name and not e.name.GetTextColor then e.name = nil end
    if e.name then e.nameColour = {e.name:GetTextColor()} end
    e.flash = _G[name.."Flash"]; e.pvp = owner.pvpIcon or _G[name.."PVPIcon"] or (name=="PlayerFrame" and PlayerPVPIcon)
    e.health = bar(owner,h); if m then e.power = bar(owner,m) end
    addon.frames[name] = e
    h:HookScript("OnValueChanged",function() if addon.db and addon.db.enabled then paint(e) end end)
    if m then m:HookScript("OnValueChanged",function() if addon.db and addon.db.enabled then paint(e) end end) end
    owner:HookScript("OnShow",function() dirty = true end)
end
function addon:Discover()
    register("PlayerFrame","player"); register("TargetFrame","target"); register("FocusFrame","focus")
    register("PetFrame","pet",true); register("TargetFrameToT","targettarget",true)
    register("FocusFrameToT","focustarget",true)
    for i=1,4 do register("PartyMemberFrame"..i,"party"..i,true); register("Boss"..i.."TargetFrame","boss"..i,true) end
    for i=1,5 do register("ArenaEnemyFrame"..i,"arena"..i,true) end
end
local frameDecor = {"PlayerFrameTexture","PlayerFrameVehicleTexture","TargetFrameTextureFrameTexture",
    "FocusFrameTextureFrameTexture","PetFrameTexture","TargetFrameToTTextureFrameTexture","FocusFrameToTTextureFrameTexture"}
local actionDecor = {"MainMenuBarTexture0","MainMenuBarTexture1","MainMenuBarTexture2","MainMenuBarTexture3",
    "MainMenuBarLeftEndCap","MainMenuBarRightEndCap","SlidingActionBarTexture0","SlidingActionBarTexture1",
    "StanceBarLeft","StanceBarMiddle","StanceBarRight","BonusActionBarTexture0","BonusActionBarTexture1"}
function addon:Theme()
    for _, n in ipairs(frameDecor) do tint(_G[n],self.db.enabled and self.db.darkFrames) end
    for i=1,4 do
        tint(_G["PartyMemberFrame"..i.."Texture"],self.db.enabled and self.db.darkFrames)
        tint(_G["Boss"..i.."TargetFrameTextureFrameTexture"],self.db.enabled and self.db.darkFrames)
    end
    for _, n in ipairs(actionDecor) do tint(_G[n],self.db.enabled and self.db.darkActionBars) end
    if self.ThemeButtons then self:ThemeButtons() end
    if self.ThemeWindows then self:ThemeWindows() end
    if self.ThemeOptions then self:ThemeOptions() end
    tint(MinimapBorder,self.db.enabled and self.db.darkMinimap)
    tint(MinimapBorderTop,self.db.enabled and self.db.darkMinimap)
    for _, n in ipairs({"CastingBarFrameBorder","PetCastingBarFrameBorder","TargetFrameSpellBarBorder","FocusFrameSpellBarBorder"}) do
        tint(_G[n],self.db.enabled and self.db.darkFrames)
    end
end
local function savePosition(name)
    local e = addon.frames[name]; local f = e.owner
    local ratio = f:GetEffectiveScale()/UIParent:GetEffectiveScale()
    addon.db.positions[name] = {x=f:GetLeft()*ratio,y=f:GetBottom()*ratio}
end
function addon:CreateMover(name,e)
    if e.mover then return end
    local m = CreateFrame("Frame",nil,UIParent); m:SetAllPoints(e.owner); m:SetFrameStrata("DIALOG")
    m:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
    m:SetBackdropColor(0.12,0.6,0.5,0.65); m:SetBackdropBorderColor(0.5,1,0.8,1)
    m.label = text(m,11); m.label:SetText(name); m:EnableMouse(true); m:RegisterForDrag("LeftButton")
    m:SetScript("OnDragStart",function()
        if not InCombatLockdown() then
            e.owner:SetMovable(true);e.owner:StartMoving();e.dragging=true
            if addon.ShowMoveGuides then addon:ShowMoveGuides(true) end
        end
    end)
    m:SetScript("OnUpdate",function(_,dt)
        if e.dragging and addon.PreviewSnap then addon:PreviewSnap(name) end
    end)
    m:SetScript("OnDragStop",function()
        if InCombatLockdown() then e.stopPending=true;e.dragging=nil;addon.pending=true;return end
        e.owner:StopMovingOrSizing();e.dragging=nil
        if addon.FinishSnap then addon:FinishSnap(name) end
        savePosition(name);e.positionApplied=true
        if addon.ShowMoveGuides then addon:ShowMoveGuides(addon.unlocked and not InCombatLockdown()) end
    end)
    m:SetScript("OnHide",function()
        if e.dragging then m:GetScript("OnDragStop")(m) end
    end)
    m:Hide(); e.mover = m
end
function addon:SetUnlocked(value)
    if InCombatLockdown() then self:Message("Frame movement is unavailable during combat."); return false end
    if value and not self.db.enabled then self:Message("Enable the addon before moving frames.");return false end
    self.unlocked = value
    for name,e in pairs(self.frames) do
        self:CreateMover(name,e)
        if value and e.owner:IsShown() then e.mover:Show() else e.mover:Hide() end
    end
    if self.ShowMoveGuides then self:ShowMoveGuides(value) end
    self:Message(value and "Drag green handles; snap on release. Hold Shift to bypass. /blkf lock when finished." or "Frames locked.")
    return true
end
function addon:Apply()
    if not self.db then return end
    if InCombatLockdown() then
        self.pending = true
        if not self.warned then self:Message("Layout changes saved; they will apply after combat."); self.warned=true end
        return false
    end
    self.pending,self.warned = false,false
    self:Discover(); importantNames = {}
    for id, enabled in pairs(self.db.importantSpells) do
        if enabled and type(id)=="number" then local n = GetSpellInfo(id); if n then importantNames[n]=true end end
    end
    for name,e in pairs(self.frames) do
        if e.stopPending then e.owner:StopMovingOrSizing();e.stopPending=nil;e.dragging=nil end
        if e.positionApplied and (not self.db.enabled or not self.db.positions[name]) then
            e.owner:ClearAllPoints()
            for _,point in ipairs(e.points) do e.owner:SetPoint(unpack(point)) end
            e.positionApplied=nil
        end
        for obj,alpha in pairs(e.nativeTexts) do obj:SetAlpha(self.db.enabled and 0 or alpha) end
        e.owner:SetScale(e.originalScale*(self.db.enabled and self.db.frameScale or 1))
        if self.db.enabled then
            local big = self.db.bigBars and not e.minor
            e.health:ClearAllPoints(); e.health:SetPoint("TOPLEFT",e.originalHealth,"TOPLEFT",0,big and 16 or 0)
            e.health:SetWidth(e.originalHealth:GetWidth()); e.health:SetHeight(big and self.db.healthHeight or e.originalHealth:GetHeight())
            e.health:SetStatusBarTexture(self.db.flatBars and white or stock);e.health.text:SetFont(STANDARD_TEXT_FONT,e.minor and math.max(8,self.db.fontSize-2) or self.db.fontSize,"OUTLINE")
            e.originalHealth:SetAlpha(0); e.health:Show()
            if e.power then
                e.power:ClearAllPoints()
                if big then e.power:SetPoint("TOPLEFT",e.health,"BOTTOMLEFT",0,-1)
                else e.power:SetPoint("TOPLEFT",e.originalPower,"TOPLEFT",0,0) end
                e.power:SetWidth(e.originalPower:GetWidth());e.power:SetHeight(big and self.db.powerHeight or e.originalPower:GetHeight())
                e.power:SetStatusBarTexture(self.db.flatBars and white or stock);e.power.text:SetFont(STANDARD_TEXT_FONT,math.max(8,self.db.fontSize-2),"OUTLINE")
                e.originalPower:SetAlpha(0);e.power:Show()
            end
            if self.StyleBar then self:StyleBar(e.health,false,big);if e.power then self:StyleBar(e.power,true,big) end end
            local pos = self.db.positions[name]
            if type(pos)=="table" and type(pos.x)=="number" and type(pos.y)=="number" then
                local ratio=e.owner:GetEffectiveScale()/UIParent:GetEffectiveScale()
                e.owner:ClearAllPoints();e.owner:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",pos.x/ratio,pos.y/ratio)
                e.positionApplied=true
            end
        else
            e.originalHealth:SetAlpha(e.healthAlpha);e.health:Hide()
            if e.power then e.originalPower:SetAlpha(e.powerAlpha);e.power:Hide() end
            rememberAlpha(e.flash,false);rememberAlpha(e.pvp,false)
            if e.name and e.nameColour then e.name:SetTextColor(unpack(e.nameColour)) end
            portrait(e)
        end
        if self.LayoutName then self:LayoutName(e) end
    end
    if not self.db.enabled and self.unlocked then self:SetUnlocked(false) end
    if self.unlocked and self.ShowMoveGuides then self:ShowMoveGuides(true) end
    self:Theme();self:SetupCasts();self:Refresh()
    if self.RefreshAuraOffset then self:RefreshAuraOffset() end
    dirty = false
    return true
end
function addon:Set(key,value)
    self.db[key]=value;self.db=normalize(self.db);self:CommitSettings();self:Apply()
end
function addon:Reset()
    if InCombatLockdown() then self:Message("Reset is unavailable during combat.");return end
    local profiles=self.db.profiles
    self.db=copy(defaults)
    if BetterLKFramesCharDB and BetterLKFramesCharDB.useCharacter then self.db.profiles=profiles end
    self:CommitSettings();self:Apply()
    self:Message("Defaults restored for the active settings scope.")
end
function addon:Profile(mode,name)
    if not name or name=="" then self:Message("Use /blkf profile save NAME or /blkf profile load NAME.");return end
    if mode=="save" then
        local d=copy(self.db);d.profiles=nil;self.db.profiles[name]=d;self:Message("Saved profile "..name)
    elseif mode=="load" then
        local profile=self.db.profiles[name]
        if not profile then self:Message("Unknown profile: "..name);return end
        local profiles=self.db.profiles;self.db=normalize(copy(profile));self.db.profiles=profiles
        self:CommitSettings();self:Apply();self:Message("Loaded profile "..name)
    end
end
function addon:SetupCasts()
    for _,name in ipairs({"CastingBarFrame","PetCastingBarFrame","TargetFrameSpellBar","FocusFrameSpellBar"}) do
        local f=_G[name]
        if f then
            if not f.blkTime then f.blkTime=text(f,11);f.blkTime:ClearAllPoints();f.blkTime:SetPoint("RIGHT",f,"RIGHT",-3,0) end
            local label=f.Text or _G[name.."Text"]
            if label and label.GetFont then
                local font,size,flags=label:GetFont()
                if font then f.blkTime:SetFont(font,size,flags) end
                f.blkTime:ClearAllPoints();f.blkTime:SetPoint("RIGHT",label,"RIGHT",0,0)
                f.blkTime:SetJustifyV("MIDDLE")
            end
            if not f.blkOriginalScale then f.blkOriginalScale=f:GetScale() end
            f:SetScale(f.blkOriginalScale*(self.db.enabled and self.db.castScale or 1))
        end
    end
    for i=1,4 do
        local owner=_G["PartyMemberFrame"..i]
        if owner and not self.castbars[i] then
            local f=CreateFrame("StatusBar",nil,owner);border(f);f:SetStatusBarTexture(stock)
            f:SetPoint("TOPLEFT",owner,"BOTTOMLEFT",14,1);f:SetWidth(105);f:SetHeight(12)
            f.name=text(f,9);f.time=text(f,9);f.name:ClearAllPoints();f.name:SetPoint("LEFT",f,"LEFT",2,0);f.name:SetWidth(75);f.name:SetJustifyH("LEFT")
            f.time:ClearAllPoints();f.time:SetPoint("RIGHT",f,"RIGHT",-2,0);f.unit="party"..i;f:Hide();self.castbars[i]=f
        end
    end
end
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
local function auraButton(button,unit,index,debuff)
    if not button or not button:IsShown() then return end
    local n,rank,icon,count,kind,duration,expiry,caster,steal,consolidate,spellId
    if debuff then n,rank,icon,count,kind,duration,expiry,caster,steal,consolidate,spellId=UnitDebuff(unit,index)
    else n,rank,icon,count,kind,duration,expiry,caster,steal,consolidate,spellId=UnitBuff(unit,index) end
    if not button.blkAura then
        if InCombatLockdown() then return end
        local f=CreateFrame("Frame",nil,button);f:SetAllPoints(button);f:SetFrameLevel(button:GetFrameLevel()+5);f:EnableMouse(false)
        f.time=text(f,10);f.time:ClearAllPoints()
        if unit=="player" then f.time:SetPoint("TOP",button,"BOTTOM",0,-1);f.time:SetTextColor(1,.85,.15)
        else f.time:SetPoint("BOTTOM",button,"BOTTOM",0,0) end
        f.edge=CreateFrame("Frame",nil,f);f.edge:SetAllPoints(button);f.edge:SetBackdrop({edgeFile=white,edgeSize=2});f.edge:EnableMouse(false);f.edge:Hide()
        local native=button.cooldown or (button:GetName() and _G[button:GetName().."Cooldown"])
        if not native then
            f.cooldown=CreateFrame("Cooldown",nil,button,"CooldownFrameTemplate")
            f.cooldown:SetAllPoints(button);f.cooldown:EnableMouse(false)
        end
        f.nativeDuration=button.duration or (button:GetName() and _G[button:GetName().."Duration"])
        button.blkAura=f;addon.auras[button]=f
    end
    local f=button.blkAura;local db=addon.db
    if addon.SkinAura then addon:SkinAura(button,f) end
    rememberAlpha(f.nativeDuration,db.enabled and db.auraTimers)
    local remaining=expiry and expiry-GetTime() or 0
    if not db.enabled or not n then f:Hide();if f.cooldown then f.cooldown:Hide();f.cooldownExpiry=nil end;return end
    if not f:IsShown() then f:Show() end
    if db.auraTimers and duration and duration>0 and remaining>0 then
        f.time:SetText(remaining>=60 and string.format("%dm",math.ceil(remaining/60)) or string.format("%d",math.ceil(remaining)))
    else f.time:SetText("") end
    if f.cooldown then
        if db.auraSpirals and duration and duration>0 and remaining>0 then
            if f.cooldownExpiry~=expiry or f.cooldownDuration~=duration or f.cooldownSpell~=n then
                f.cooldown:SetCooldown(expiry-duration,duration)
                f.cooldownExpiry=expiry;f.cooldownDuration=duration;f.cooldownSpell=n
            end
            if not f.cooldown:IsShown() then f.cooldown:Show() end
        else f.cooldown:Hide();f.cooldownExpiry=nil end
    end
    if spellId and db.importantSpells[spellId] or importantNames[n] then
        f.edge:SetBackdropBorderColor(1,0.8,0.1,1);f.edge:Show()
    elseif db.auraWarnings and duration and duration>0 and remaining>0 and remaining<=db.warningSeconds then
        f.edge:SetBackdropBorderColor(1,0.2,0.15,1);f.edge:Show()
    else f.edge:Hide() end
end
function addon:UpdateAuras()
    if not self.db.enabled then
        for _,f in pairs(self.auras) do f:Hide();if f.cooldown then f.cooldown:Hide();f.cooldownExpiry=nil end;rememberAlpha(f.nativeDuration,false);if self.SkinAura then self:SkinAura(nil,f) end end
        return
    end
    for _,pair in ipairs({{"TargetFrame","target"},{"FocusFrame","focus"}}) do
        for i=1,32 do
            local b=_G[pair[1].."Buff"..i];if b then auraButton(b,pair[2],b:GetID()>0 and b:GetID() or i,false) end
            local d=_G[pair[1].."Debuff"..i];if d then auraButton(d,pair[2],d:GetID()>0 and d:GetID() or i,true) end
        end
    end
    for i=1,40 do local b=_G["BuffButton"..i];if b then auraButton(b,PlayerFrame and PlayerFrame.unit or "player",b:GetID()>0 and b:GetID() or i,false) end end
    for i=1,16 do local b=_G["DebuffButton"..i];if b then auraButton(b,PlayerFrame and PlayerFrame.unit or "player",b:GetID()>0 and b:GetID() or i,true) end end
end
function addon:Command(message)
    local cmd,rest=string.match(message or "","^(%S*)%s*(.-)$");cmd=string.lower(cmd or "")
    if cmd=="unlock" then self:SetUnlocked(true)
    elseif cmd=="lock" then self:SetUnlocked(false)
    elseif cmd=="reset" then self:Reset()
    elseif cmd=="off" or cmd=="on" then self:Set("enabled",cmd=="on")
    elseif cmd=="character" then self:CharacterProfile(rest)
    elseif cmd=="profile" then local mode,name=string.match(rest,"^(%S+)%s+(.+)$");self:Profile(mode,name)
    elseif cmd=="aura" then
        local id=tonumber(rest)
        if not id or not GetSpellInfo(id) then self:Message("Use /blkf aura SPELLID with a valid Wrath spell ID.");return end
        self.db.importantSpells[id]=not self.db.importantSpells[id];self:Apply();self:Message("Important-aura setting toggled for "..GetSpellInfo(id))
    elseif cmd=="help" then self:Message("/blkf options | unlock | lock | on | off | reset | aura SPELLID | profile save/load NAME")
    elseif self.OpenOptions then self:OpenOptions() end
end
addon:SetScript("OnEvent",function(self,event,arg1)
    if event=="ADDON_LOADED" and arg1=="BetterLKFrames" then
        self:InitSettings()
        SLASH_BETTERLKFRAMES1="/blkf";SLASH_BETTERLKFRAMES2="/betterlkframes"
        SlashCmdList.BETTERLKFRAMES=function(msg) self:Command(msg) end
        if self.BuildOptions then self:BuildOptions() end
    elseif event=="PLAYER_LOGIN" then
        self:InitSettings();self:Apply();self:Message("Loaded. /blkf for settings; /blkf unlock to move frames.")
    elseif event=="PLAYER_REGEN_ENABLED" then self:Apply()
    elseif event=="PLAYER_REGEN_DISABLED" and self.unlocked then
        for _,e in pairs(self.frames) do if e.mover then e.mover:Hide() end end
        self.unlocked=false
        if self.ShowMoveGuides then self:ShowMoveGuides(false) end
    elseif event=="ADDON_LOADED" and self.db then self:Apply() end
    dirty=true
end)
for _,ev in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED",
    "PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_MANA","UNIT_MAXMANA",
    "UNIT_RAGE","UNIT_FOCUS","UNIT_ENERGY","UNIT_HAPPINESS","UNIT_RUNIC_POWER",
    "UNIT_DISPLAYPOWER","UNIT_FACTION","UNIT_NAME_UPDATE","UNIT_AURA","PARTY_MEMBERS_CHANGED","UNIT_PET"}) do addon:RegisterEvent(ev) end
addon:SetScript("OnUpdate",function(self,dt)
    if not self.db then return end
    elapsed=elapsed+dt;auraElapsed=auraElapsed+dt
    if elapsed>=0.1 then
        elapsed=0;if dirty then self:Refresh();dirty=false end
        self:UpdateCasts()
    end
    if auraElapsed>=0.25 then auraElapsed=0;self:UpdateAuras();self:Theme() end
end)
for _,fn in ipairs({"UnitFramePortrait_Update","PlayerFrame_UpdateArt","TargetFrame_CheckClassification"}) do
    if type(_G[fn])=="function" then hooksecurefunc(fn,function() dirty=true end) end
end
if GameTooltip and GameTooltip.HookScript then
    local oldBackdrop,oldBorder
    GameTooltip:HookScript("OnShow",function(self)
        if not addon.db then return end
        if not oldBackdrop then oldBackdrop={self:GetBackdropColor()};oldBorder={self:GetBackdropBorderColor()} end
        if addon.db.enabled and addon.db.darkTooltip then
            self:SetBackdropColor(0.03,0.03,0.03,0.96);self:SetBackdropBorderColor(0.2,0.2,0.2,1)
        else self:SetBackdropColor(unpack(oldBackdrop));self:SetBackdropBorderColor(unpack(oldBorder)) end
    end)
end
