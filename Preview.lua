-- Visual-only aura samples. No native aura buttons or SavedVariables are changed.
local addon=BetterLKFrames
local white="Interface\\Buttons\\WHITE8X8"
local samples={
    {name="Fortitude sample",icon="Spell_Holy_WordFortitude",id=21562,duration=60,remaining=45},
    {name="Expiring debuff sample",icon="Spell_Frost_FrostBolt02",id=116,duration=8,remaining=2},
    {name="Permanent debuff sample",icon="Spell_Shadow_AbominationExplosion",id=172,duration=0,remaining=0},
}
local contexts={{name="PlayerFrame",unit="player"},{name="TargetFrame",unit="target"},{name="FocusFrame",unit="focus"}}
local function makeGroup(context,index)
    local group=CreateFrame("Frame",nil,UIParent);group:Hide();group:EnableMouse(false)
    group:SetWidth(180);group:SetHeight(72);group:SetFrameStrata("DIALOG")
    group:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
    group:SetBackdropColor(.035,.045,.055,.95);group:SetBackdropBorderColor(.7,.6,.2,1)
    group.title=group:CreateFontString(nil,"OVERLAY");group.title:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
    group.title:SetPoint("TOPLEFT",5,-4);group.title:SetText("TEST "..context.unit..": buff / debuffs")
    group.title:SetTextColor(1,.85,.25);group.samples={};group.context=context;group.index=index
    for i,data in ipairs(samples) do
        local button=CreateFrame("Frame",nil,group);button:SetWidth(26);button:SetHeight(26);button:EnableMouse(false)
        button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetAllPoints(button)
        button.icon:SetTexture("Interface\\Icons\\"..data.icon)
        local visual=CreateFrame("Frame",nil,button);visual:SetAllPoints(button);visual:EnableMouse(false)
        visual.time=visual:CreateFontString(nil,"OVERLAY");visual.time:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
        if context.unit=="player" then visual.time:SetPoint("TOP",button,"BOTTOM",0,-1);visual.time:SetTextColor(1,.85,.15)
        else visual.time:SetPoint("BOTTOM",button,"BOTTOM",0,0) end
        visual.edge=CreateFrame("Frame",nil,visual);visual.edge:SetAllPoints(button)
        visual.edge:SetBackdrop({edgeFile=white,edgeSize=2});visual.edge:EnableMouse(false);visual.edge:Hide()
        visual.cooldown=CreateFrame("Cooldown",nil,button,"CooldownFrameTemplate")
        visual.cooldown:SetAllPoints(button);visual.cooldown:EnableMouse(false);visual.cooldown:Hide()
        visual:SetFrameLevel(visual.cooldown:GetFrameLevel()+2)
        button.visual=visual;button.data=data;group.samples[i]=button
    end
    return group
end
local function position(group)
    local context=group.context
    local owner=_G[context.name]
    group:ClearAllPoints()
    if owner and owner:IsShown() and UnitExists(context.unit) and owner:GetLeft() and owner:GetBottom() then
        -- Stay below genuine icons instead of covering/reanchoring native aura rows.
        local ratio=owner:GetEffectiveScale()/UIParent:GetEffectiveScale()
        local left,bottom=owner:GetLeft()*ratio,owner:GetBottom()*ratio
        local prefixes=context.unit=="player" and {"BuffButton","DebuffButton"} or {context.name.."Buff",context.name.."Debuff"}
        for _,prefix in ipairs(prefixes) do
            for i=1,40 do
                local b=_G[prefix..i]
                if b and b:IsShown() and b:GetBottom() then
                    bottom=math.min(bottom,b:GetBottom()*b:GetEffectiveScale()/UIParent:GetEffectiveScale())
                end
            end
        end
        left=math.max(0,math.min(left,UIParent:GetWidth()-180))
        bottom=math.max(76,math.min(bottom-12,UIParent:GetHeight()))
        group:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,bottom)
    else
        -- No live target/focus is needed: show a labelled representative group in settings.
        group:SetPoint("TOPLEFT",addon.auraOptionsPage,"TOPLEFT",(group.index-1)*200,-365)
    end
    for i,button in ipairs(group.samples) do
        button:ClearAllPoints()
        local gap=context.unit~="player" and addon.db.bigBars and addon.db.auraOffset or 0
        button:SetPoint("TOPLEFT",group,"TOPLEFT",8+(i-1)*50,-22-gap)
    end
end
function addon:SetTestAuras(value)
    if value and (InCombatLockdown() or not self.db.enabled or not self.options or not self.options:IsShown() or
        not self.auraOptionsPage or not self.auraOptionsPage:IsShown()) then
        self:Message("Aura previews require enabled settings on Casts / auras outside combat.");value=false
    end
    self.testAuras=value and true or false
    if self.testAuras then self:UpdateTestAuras()
    else
        for _,group in ipairs(self.auraPreviews or {}) do
            group:Hide()
            for _,button in ipairs(group.samples) do
                button.visual:Hide();button.visual.cooldown:Hide()
                button.visual.cooldownExpiry=nil;button.expires=nil
            end
        end
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
        for i,context in ipairs(contexts) do self.auraPreviews[i]=makeGroup(context,i) end
    end
    for _,group in ipairs(self.auraPreviews) do
        position(group);group:Show()
        for _,button in ipairs(group.samples) do
            local data=button.data
            if not button.expires or button.expires<=GetTime() then button.expires=GetTime()+data.remaining end
            self:PaintAura(button,button.visual,data.name,data.duration,button.expires,data.id)
        end
    end
end
