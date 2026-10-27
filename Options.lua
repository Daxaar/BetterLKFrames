local addon=BetterLKFrames
local white="Interface\\Buttons\\WHITE8X8"
local serial=0
local function label(parent,value,x,y,size)
    local t=parent:CreateFontString(nil,"OVERLAY")
    t:SetFont(STANDARD_TEXT_FONT,size or 12,"OUTLINE");t:SetPoint("TOPLEFT",x,y)
    t:SetText(value);t:SetTextColor(0.9,0.95,0.95);return t
end
local function button(parent,value,x,y,width,callback)
    local f=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    f:SetWidth(width or 110);f:SetHeight(24);f:SetPoint("TOPLEFT",x,y);f:SetText(value)
    f:SetScript("OnClick",callback);addon:RegisterOptionsArt(f);return f
end
function addon:BuildOptions()
    if self.options then return end
    local f=CreateFrame("Frame","BetterLKFramesOptions",UIParent)
    self.options=f;f:SetWidth(640);f:SetHeight(610);f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG");f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
    f:SetBackdropColor(.08,.08,.08,.98)
    label(f,"BetterLKFrames",18,-16,18)
    label(f,"Original Wrath frame styling | /blkf | Layout changes wait until combat ends.",18,-43,11)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3)
    addon:RegisterOptionsArt(close)
    close:SetScript("OnClick",function() f:Hide() end)
    table.insert(UISpecialFrames,"BetterLKFramesOptions")
    local pages,controls={},{}
    local function page(title)
        local p=CreateFrame("Frame",nil,f);p:SetPoint("TOPLEFT",18,-100);p:SetWidth(605);p:SetHeight(470);p:Hide()
        pages[#pages+1]=p
        button(f,title,18+(#pages-1)*151,-67,145,function()
            for _,v in ipairs(pages) do v:Hide() end;p:Show()
        end)
        return p
    end
    local function check(parent,key,title,x,y)
        serial=serial+1
        local c=CreateFrame("CheckButton","BetterLKFramesCheck"..serial,parent,"UICheckButtonTemplate")
        c:SetWidth(24);c:SetHeight(24);c:SetPoint("TOPLEFT",x,y)
        _G[c:GetName().."Text"]:SetText(title)
        addon:RegisterOptionsArt(c)
        c:SetScript("OnClick",function(self) addon:Set(key,self:GetChecked() and true or false) end)
        controls[#controls+1]=function() c:SetChecked(addon.db[key]) end
        return c
    end
    local function slider(parent,key,title,x,y,lo,hi,step,format)
        serial=serial+1
        local c=CreateFrame("Slider","BetterLKFramesSlider"..serial,parent,"OptionsSliderTemplate")
        c:SetPoint("TOPLEFT",x,y);c:SetWidth(250);c:SetMinMaxValues(lo,hi);c:SetValueStep(step)
        _G[c:GetName().."Low"]:SetText(tostring(lo));_G[c:GetName().."High"]:SetText(tostring(hi))
        addon.optionsSliders=addon.optionsSliders or {};table.insert(addon.optionsSliders,c)
        local updating=false
        c:SetScript("OnValueChanged",function(self,value)
            value=math.floor(value/step+0.5)*step
            _G[c:GetName().."Text"]:SetText(title..": "..string.format(format or "%.0f",value))
            if not updating then addon:Set(key,value) end
        end)
        controls[#controls+1]=function() updating=true;c:SetValue(addon.db[key]);updating=false end
    end
    local appearance=page("Appearance")
    local entries={{"enabled","Enable BetterLKFrames"},{"bigBars","Thicker player/target/focus bars"},
        {"classHealth","Class-coloured player health"},{"classNames","Class-coloured player names"},
        {"reactionHealth","NPC reaction health colours"},{"healthGradient","Health gradient (non-class bars)"},
        {"flatBars","Flat bar texture"},{"classPortraits","Class-icon portraits"},
        {"darkFrames","Dark unit-frame decoration"},{"darkActionBars","Dark action-bar decoration"},
        {"darkMinimap","Dark minimap border"},{"darkTooltip","Dark tooltip background"},
        {"hideCombatFlash","Hide unit-frame combat flash"},{"hidePvp","Hide unit-frame PvP icons"},
        {"darkButtons","Dark action/bag/menu button borders"},{"darkAuras","Dark buff/debuff borders"},{"darkWindows","Dark standard window trim"}}
    for i,e in ipairs(entries) do local col=math.floor((i-1)/9);local row=(i-1)%9
        check(appearance,e[1],e[2],col*300,-row*32)
    end
    slider(appearance,"darkness","Decoration brightness",10,-325,0.1,1,0.05,"%.2f")
    label(appearance,"Lower brightness is darker. Portraits, icons and bar colours stay untinted.",0,-385,11)
    local frames=page("Frames")
    check(frames,"healthText","Health values and percentage",0,0)
    check(frames,"powerText","Power values",300,0)
    slider(frames,"healthHeight","Large health-bar height",10,-65,16,30,1)
    slider(frames,"powerHeight","Large power-bar height",315,-65,4,12,1)
    slider(frames,"frameScale","Unit-frame scale",10,-140,0.65,1.6,0.05,"%.2f")
    slider(frames,"fontSize","Bar text size",315,-140,9,16,1)
    button(frames,"Unlock frames",0,-210,140,function() addon:SetUnlocked(true);f:Hide() end)
    button(frames,"Lock frames",150,-210,140,function() addon:SetUnlocked(false) end)
    check(frames,"namesAbove","Names above large bars",0,-245)
    check(frames,"roundedBars","Rounded large-bar edges",300,-245)
    check(frames,"snapFrames","Snap edges / centres on release",0,-280)
    check(frames,"showGuides","Show alignment guides",300,-280)
    check(frames,"snapGrid","Snap centres to visible grid",0,-315)
    check(frames,"showGrid","Show screen-centred grid",300,-315)
    slider(frames,"snapDistance","Snap tolerance",10,-365,2,24,1)
    slider(frames,"gridSize","Grid spacing",315,-365,8,128,8)
    label(frames,"Grid labels count squares from screen centre. Hold Shift to bypass snapping.",0,-415,11)
    local casts=page("Casts / auras")
    check(casts,"castTimers","Native cast-bar time remaining",0,0)
    check(casts,"partyCastbars","Party-member cast bars",300,0)
    check(casts,"auraTimers","Aura time remaining",0,-40)
    check(casts,"auraSpirals","Add missing aura cooldown spirals",300,-40)
    check(casts,"auraWarnings","Expiring-aura red border",0,-80)
    slider(casts,"castScale","Native cast-bar scale",10,-145,0.6,2,0.05,"%.2f")
    slider(casts,"warningSeconds","Aura warning seconds",315,-145,0,10,1)
    slider(casts,"auraOffset","Target/focus aura gap",10,-225,0,12,1)
    label(casts,"Gold borders mark important spell IDs: /blkf aura SPELLID\nRun the same command again to remove an ID.\nNative cooldown spirals are preserved. No aura filtering or secure reordering.\nParty casting information depends on what the Wrath client can see.",0,-290,12)
    local profiles=page("Profiles / help")
    label(profiles,"Profile name",0,-4,12)
    local edit=CreateFrame("EditBox",nil,profiles,"InputBoxTemplate")
    edit:SetWidth(260);edit:SetHeight(25);edit:SetPoint("TOPLEFT",10,-30);edit:SetAutoFocus(false);edit:SetMaxLetters(40)
    edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    button(profiles,"Save profile",290,-30,130,function() addon:Profile("save",edit:GetText());edit:ClearFocus() end)
    button(profiles,"Load profile",430,-30,130,function() addon:Profile("load",edit:GetText());edit:ClearFocus();f:Hide();f:Show() end)
    label(profiles,"Saved profiles",0,-85,12)
    local names=label(profiles,"",0,-110,12);names:SetWidth(580);names:SetJustifyH("LEFT")
    controls[#controls+1]=function()
        local list={};for name in pairs(addon.db.profiles) do list[#list+1]=name end
        table.sort(list);names:SetText(#list>0 and table.concat(list,", ") or "No profiles saved yet.")
    end
    local scope=label(profiles,"",0,-155,12)
    controls[#controls+1]=function()
        scope:SetText(BetterLKFramesCharDB.useCharacter and "Active: this character only" or "Active: shared account settings")
    end
    local function changeScope(mode) addon:CharacterProfile(mode);f:Hide();f:Show() end
    button(profiles,"Use account",0,-185,140,function() changeScope("account") end)
    button(profiles,"Copy to character",150,-185,160,function() changeScope("copy") end)
    button(profiles,"Resume character",320,-185,160,function() changeScope("resume") end)
    button(profiles,"Character: defaults",0,-220,180,function() changeScope("defaults") end)
    button(profiles,"Character: Blizzard",190,-220,180,function() changeScope("blizzard") end)
    button(profiles,"Reset active scope",0,-265,180,function() StaticPopup_Show("BETTERLKFRAMES_RESET") end)
    label(profiles,"Character: defaults starts fresh addon settings for only this character.\nCharacter: Blizzard restores the native appearance for only this character.\nAccount settings and shared named profiles remain available.\nCopy/default/Blizzard replaces this character's previous local settings.\n\n/blkf character account | copy | defaults | blizzard | resume\n/blkf profile save NAME | /blkf profile load NAME\n/blkf on | off | unlock | lock | aura SPELLID",0,-310,12)
    StaticPopupDialogs.BETTERLKFRAMES_RESET={text="Reset the active scope? Account reset also clears named profiles; character reset preserves them.",button1=ACCEPT,button2=CANCEL,
        OnAccept=function() addon:Reset();f:Hide() end,timeout=0,whileDead=true,hideOnEscape=true}
    f:SetScript("OnShow",function() for _,refresh in ipairs(controls) do refresh() end end)
    pages[1]:Show();f:Hide()
    addon:ThemeOptions()
    if InterfaceOptions_AddCategory then
        local panel=CreateFrame("Frame");panel.name="BetterLKFrames"
        label(panel,"BetterLKFrames",16,-16,18)
        button(panel,"Open settings",16,-55,150,function() addon:OpenOptions() end)
        InterfaceOptions_AddCategory(panel)
    end
end
function addon:OpenOptions()
    if not self.options then self:BuildOptions() end
    if self.options:IsShown() then self.options:Hide() else self.options:Show() end
end
