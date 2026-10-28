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
    f.blkBrightButton=true
    f:SetScript("OnClick",callback);addon:RegisterOptionsArt(f);return f
end
function addon:BuildOptions()
    if self.options then return end
    local f=CreateFrame("Frame","BetterLKFramesOptions",UIParent)
    self.options=f;f:SetWidth(640);f:SetHeight(610);f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG");f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
    self.optionsContext="standalone"
    f:SetScript("OnDragStart",function(self) if addon.optionsContext=="standalone" then self:StartMoving() end end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    self.optionsBackdrop={bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}}
    f:SetBackdrop(self.optionsBackdrop)
    f:SetBackdropColor(.08,.08,.08,.98)
    label(f,"BetterLKFrames",18,-16,18)
    label(f,"Original Wrath frame styling | /bf | Layout changes wait until combat ends.",18,-43,11)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-3,-3)
    addon:RegisterOptionsArt(close)
    self.optionsClose=close
    close:SetScript("OnClick",function() addon:CloseOptions() end)
    table.insert(UISpecialFrames,"BetterLKFramesOptions")
    local pages,controls={},{}
    self.optionsNavigation={}
    self.optionsPages=pages
    function addon:SelectOptionsPage(index)
        for i,p in ipairs(pages) do
            if i==index then p:Show() else p:Hide() end
        end
        self.optionsPage=index;PanelTemplates_SetTab(f,index)
        for _,nav in ipairs(self.optionsNavigation) do if nav.blkFit then nav.blkFit() end end
        if self.optionsScroll then self.optionsScroll:SetVerticalScroll(0) end
    end
    local function page(title)
        local p=CreateFrame("Frame",nil,f);p:SetPoint("TOPLEFT",18,-100);p:SetWidth(605);p:SetHeight(470);p:Hide()
        pages[#pages+1]=p
        local index=#pages
        local nav=CreateFrame("Button","BetterLKFramesOptionsTab"..index,f,"OptionsFrameTabButtonTemplate")
        nav:SetID(index);nav:SetText(title)
        local function fit()
            local cap=_G[nav:GetName().."Left"]:GetWidth()
            -- The template's inherited OnShow otherwise resizes from a previously
            -- constrained FontString. Always measure the actual label instead.
            _G[nav:GetName().."Text"]:SetWidth(0)
            PanelTemplates_TabResize(nav,0,math.ceil(nav:GetTextWidth())+cap*2+8)
        end
        nav.blkFit=fit;nav:SetScript("OnShow",fit);fit()
        if index==1 then nav:SetPoint("TOPLEFT",18,-67)
        else nav:SetPoint("TOPLEFT",self.optionsNavigation[index-1],"TOPRIGHT",2,0) end
        nav:SetScript("OnClick",function() addon:SelectOptionsPage(index) end)
        nav.blkNavigation=true;nav.blkPage=p
        self.optionsNavigation[#self.optionsNavigation+1]=nav
        return p
    end
    local function check(parent,key,title,x,y)
        serial=serial+1
        local c=CreateFrame("CheckButton","BetterLKFramesCheck"..serial,parent,"UICheckButtonTemplate")
        c:SetWidth(24);c:SetHeight(24);c:SetPoint("TOPLEFT",x,y)
        _G[c:GetName().."Text"]:SetText(title)
        addon:RegisterOptionsArt(c)
        c:SetScript("OnClick",function(self)
            if key=="showTestAuras" then addon:SetTestAuras(self:GetChecked() and true or false)
            else addon:Set(key,self:GetChecked() and true or false) end
        end)
        controls[#controls+1]=function()
            if key=="showTestAuras" then c:SetChecked(addon.testAuras and true or false) else c:SetChecked(addon.db[key]) end
        end
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
        {"classHealth","Class-coloured other unit health"},{"classNames","Class-coloured player names"},
        {"reactionHealth","NPC reaction health colours"},{"healthGradient","Health gradient (non-class bars)"},
        {"flatBars","Flat bar texture"},{"classPortraits","Class-icon portraits"},
        {"darkFrames","Dark unit-frame decoration"},{"darkActionBars","Dark action-bar decoration"},
        {"darkMinimap","Dark minimap border"},{"darkTooltip","Dark tooltip background"},
        {"hideCombatFlash","Hide unit-frame combat flash"},{"hidePvp","Hide unit-frame PvP icons"},
        {"darkButtons","Dark action/bag/menu button borders"},{"darkAuras","Dark buff/debuff borders"},{"darkWindows","Dark standard window trim"},{"hideResting","Hide resting Zzz indicator"}}
    for i,e in ipairs(entries) do local col=math.floor((i-1)/9);local row=(i-1)%9
        check(appearance,e[1],e[2],col*300,-row*32)
    end
    check(appearance,"targetClassHealth","Colour target health bar by class",0,-290)
    check(appearance,"compactParty","Use compact party frames",300,-290)
    slider(appearance,"darkness","Decoration brightness",10,-325,0.1,1,0.05,"%.2f")
    label(appearance,"Lower brightness is darker. Portraits, icons and bar colours stay untinted.",0,-385,11)
    label(appearance,"Target class colour is independent of the class-colour option for other units.",0,-410,11)
    label(appearance,"Compact party mode retains native pet visibility; layout changes wait until combat ends.",0,-430,11)
    local frames=page("Frames")
    check(frames,"healthText","Health values and percentage",0,0)
    check(frames,"powerText","Power values",300,0)
    slider(frames,"healthHeight","Large health-bar height",10,-65,16,30,1)
    slider(frames,"powerHeight","Large power-bar height",315,-65,4,12,1)
    slider(frames,"frameScale","All unit-frame scale",10,-140,0.65,1.6,0.05,"%.2f")
    slider(frames,"fontSize","Bar text size",315,-140,9,16,1)
    label(frames,"Scale includes player, target, focus, pet, party and other supported unit frames.",0,-185,11)
    button(frames,"Unlock frames",0,-210,140,function() if addon:SetUnlocked(true) then addon:CloseOptions() end end)
    button(frames,"Lock frames",150,-210,140,function() addon:SetUnlocked(false) end)
    button(frames,"Reset frames",300,-210,140,function() StaticPopup_Show("BETTERLKFRAMES_RESET_FRAMES") end)
    StaticPopupDialogs.BETTERLKFRAMES_RESET_FRAMES={
        text="Restore all movable frames in the active configuration to Blizzard positions? Frames will be locked. Other settings and profiles are preserved.",
        button1=ACCEPT,button2=CANCEL,OnAccept=function(dialog)
            -- Hide before layout work, so an error cannot leave a stale confirmation.
            if dialog then dialog:Hide() end
            addon:ResetFrames()
        end,
        timeout=0,whileDead=true,hideOnEscape=true}
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
    self.auraTimerCheck=check(casts,"auraTimers","Aura time remaining",0,-40)
    check(casts,"auraSpirals","Add missing aura cooldown spirals",300,-40)
    check(casts,"auraWarnings","Expiring-aura red border",0,-80)
    check(casts,"showTestAuras","Show test auras",300,-80)
    self.omniCCWarning=label(casts,"OmniCC detected — OmniCC is managing aura countdown text. BetterLKFrames countdown text is disabled.",300,-108,10)
    self.omniCCWarning:SetWidth(290);self.omniCCWarning:SetHeight(54)
    self.omniCCWarning:SetJustifyH("LEFT");self.omniCCWarning:SetJustifyV("TOP")
    self.omniCCWarning:SetTextColor(1,.8,.2);self.omniCCWarning:Hide()
    self.auraOptionsPage=casts
    casts:SetScript("OnHide",function() addon:SetTestAuras(false) end)
    slider(casts,"castScale","Native cast-bar scale",10,-185,0.6,2,0.05,"%.2f")
    slider(casts,"warningSeconds","Aura warning seconds",315,-185,0,10,1)
    check(casts,"hidePlayerAuraSpirals","Hide main player aura spirals",300,-245)
    slider(casts,"auraOffset","Target/focus aura gap",10,-255,0,12,1)
    label(casts,"Gold borders mark important spell IDs: /bf aura SPELLID\nRun the same command again to remove an ID.\nTarget/focus spirals stay separate from main player auras. No filtering.\nParty casting information depends on what the Wrath client can see.\nTest samples: gold border uses /bf aura 21562. Preview stops in combat.",0,-305,11)
    self.auraPreviewStatus=label(casts,"",0,-370,10)
    self.auraPreviewStatus:SetWidth(590);self.auraPreviewStatus:SetJustifyH("LEFT");self.auraPreviewStatus:Hide()
    local profiles=page("Profiles / help")
    label(profiles,"Manage the current profile, or select another account/character profile.",0,-4,11)
    local current=label(profiles,"",155,-42,12);current:SetWidth(430);current:SetJustifyH("LEFT")
    local function confirm(kind,entry)
        local data=addon:PrepareProfileAction(kind,entry)
        if not data then return end
        local subject=data.subject and addon:ProfileRefLabel(data.subject) or addon:ProfileRefLabel(data.target)
        StaticPopup_Show("BETTERLKFRAMES_PROFILE_"..string.upper(kind),subject,addon:ProfileRefLabel(data.target),data)
    end
    button(profiles,"Reset Profile",0,-35,140,function() confirm("reset") end)
    label(profiles,"New",0,-95,12);label(profiles,"Existing Profiles",300,-95,12)
    local edit=CreateFrame("EditBox",nil,profiles,"InputBoxTemplate")
    edit:SetWidth(260);edit:SetHeight(25);edit:SetPoint("TOPLEFT",10,-120);edit:SetAutoFocus(false);edit:SetMaxLetters(40)
    self.profileNameEdit=edit
    edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    local function dropdown(name,x,y,width,populate)
        local menu=CreateFrame("Frame",name,profiles,"UIDropDownMenuTemplate")
        menu:SetPoint("TOPLEFT",x,y);UIDropDownMenu_SetWidth(menu,width)
        UIDropDownMenu_Initialize(menu,populate);return menu
    end
    local selector=dropdown("BetterLKFramesProfileSelect",285,-118,280,function()
        for _,entry in ipairs(addon:ListProfiles()) do
            local ref={name=entry.name,scope=entry.scope}
            local info=UIDropDownMenu_CreateInfo();info.text=entry.label
            info.checked=addon:SameProfile(addon:ActiveProfileRef(),ref)
            info.func=function() addon:Profile("load",ref.name,ref.scope);CloseDropDownMenus() end
            UIDropDownMenu_AddButton(info)
        end
    end)
    self.profileSelector=selector
    local newScope="account"
    local scopeMenu
    scopeMenu=dropdown("BetterLKFramesProfileScope",-15,-153,155,function()
        for _,scope in ipairs({"account","character"}) do
            local selected=scope
            local info=UIDropDownMenu_CreateInfo();info.text=scope=="account" and "Account-wide" or "This character"
            local text=info.text;info.checked=newScope==scope
            info.func=function() newScope=selected;UIDropDownMenu_SetText(scopeMenu,text);CloseDropDownMenus() end
            UIDropDownMenu_AddButton(info)
        end
    end)
    self.profileScopeMenu=scopeMenu;UIDropDownMenu_SetText(scopeMenu,"Account-wide")
    button(profiles,"Create",175,-155,105,function()
        if addon:Profile("save",edit:GetText(),newScope) then edit:SetText("") end
        edit:ClearFocus()
    end)
    label(profiles,"Copy another profile's settings into the current profile.",0,-212,11)
    label(profiles,"Copy From",0,-237,12)
    self.profileCopyMenu=dropdown("BetterLKFramesProfileCopy",-15,-260,265,function()
        for _,entry in ipairs(addon:ListProfiles()) do
            local ref={name=entry.name,scope=entry.scope}
            if not addon:SameProfile(addon:ActiveProfileRef(),ref) then
                local info=UIDropDownMenu_CreateInfo();info.text=entry.label;info.notCheckable=true
                info.func=function() CloseDropDownMenus();confirm("copy",ref) end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    label(profiles,"Delete an unused profile. Default is always protected.",0,-315,11)
    label(profiles,"Delete a Profile",0,-340,12)
    self.profileDeleteMenu=dropdown("BetterLKFramesProfileDelete",-15,-363,265,function()
        for _,entry in ipairs(addon:ListProfiles()) do
            if entry.scope~="default" then
                local ref={name=entry.name,scope=entry.scope}
                local info=UIDropDownMenu_CreateInfo();info.text=entry.label;info.notCheckable=true
                info.func=function() CloseDropDownMenus();confirm("delete",ref) end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
    label(profiles,"Reset, copy and delete ask for confirmation. Cancel changes nothing.",0,-418,11)
    controls[#controls+1]=function()
        local active=addon:ActiveProfileLabel()
        current:SetText("Current profile: "..active);UIDropDownMenu_SetText(selector,active)
        UIDropDownMenu_SetText(addon.profileCopyMenu,"Choose a source...")
        UIDropDownMenu_SetText(addon.profileDeleteMenu,"Choose a profile...")
    end
    local prompts={reset="Reset profile %s to defaults? Other profiles are preserved.",
        copy="Copy settings from %s into %s? This replaces the current profile's settings.",
        delete="Delete profile %s? If active, Default will be selected. This cannot be undone."}
    for kind,prompt in pairs(prompts) do
        StaticPopupDialogs["BETTERLKFRAMES_PROFILE_"..string.upper(kind)]={text=prompt,button1=ACCEPT,button2=CANCEL,
            OnAccept=function(dialog,data) if dialog then dialog:Hide() end;addon:ConfirmProfileAction(data) end,
            OnCancel=function(_,data) if data then data.used=true end end,
            timeout=0,whileDead=true,hideOnEscape=true}
    end
    function addon:RefreshOptions()
        for _,refresh in ipairs(controls) do refresh() end
        self:RefreshAuraCounterUI()
    end
    f:SetScript("OnShow",function() addon:RefreshOptions() end)
    f:SetScript("OnHide",function()
        addon:SetTestAuras(false)
        if StaticPopup_Hide then for _,kind in ipairs({"RESET","COPY","DELETE"}) do StaticPopup_Hide("BETTERLKFRAMES_PROFILE_"..kind) end end
    end)
    PanelTemplates_SetNumTabs(f,#pages);self:SelectOptionsPage(1);f:Hide()
    addon:ThemeOptions()
    self:BuildEmbeddedOptions()
end
function addon:OpenOptions()
    if not self.options then self:BuildOptions() end
    if self.optionsContext=="standalone" and self.options:IsShown() and not (InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown()) then self:CloseOptions()
    else self:ShowStandaloneOptions() end
end

function addon:RefreshAuraCounterUI()
    if not self.omniCCWarning then return end
    local loaded=self:HasOmniCC()
    if loaded then self.omniCCWarning:Show() else self.omniCCWarning:Hide() end
    _G[self.auraTimerCheck:GetName().."Text"]:SetText(loaded and "Aura time remaining (saved preference)" or "Aura time remaining")
end
