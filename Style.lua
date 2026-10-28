-- Original v1.1 appearance; all art is generated locally, never copied from BBF.
local addon=BetterLKFrames
local media="Interface\\AddOns\\BetterLKFrames\\Media\\"
local originals=setmetatable({}, {__mode="k"})
local buttonSkins=setmetatable({}, {__mode="k"})
local function tint(region,on)
    if not region or not region.SetVertexColor then return end
    if not originals[region] then originals[region]={region:GetVertexColor()} end
    local c=originals[region];local f=on and addon.db.darkness or 1
    region:SetVertexColor(c[1]*f,c[2]*f,c[3]*f,c[4] or 1)
end
function addon:StyleBar(f,power,big)
    local prefix=power and "Power" or "Health"
    if not f.roundedBackground then
        f.roundedBackground=f:CreateTexture(nil,"BACKGROUND");f.roundedBackground:SetAllPoints(f)
        f.roundedBorder=f:CreateTexture(nil,"OVERLAY");f.roundedBorder:SetAllPoints(f)
    end
    if self.db.roundedBars and big then
        f:SetBackdrop(nil)
        f.roundedBackground:SetTexture(media..prefix.."Flat");f.roundedBackground:SetVertexColor(.035,.04,.045,1)
        f.roundedBorder:SetTexture(media..prefix.."Edge")
        f.roundedBackground:Show();f.roundedBorder:Show()
        f:SetStatusBarTexture(media..prefix..(self.db.flatBars and "Flat" or "Gradient"))
    else
        f.roundedBackground:Hide();f.roundedBorder:Hide()
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        f:SetBackdropColor(.025,.025,.025,1);f:SetBackdropBorderColor(0,0,0,1)
    end
end
function addon:LayoutName(e)
    local above=self.db.enabled and self.db.namesAbove and self.db.bigBars and not e.minor
    if e.name then
        if e.nameAlpha==nil then e.nameAlpha=e.name:GetAlpha() end
        e.name:SetAlpha(above and 0 or e.nameAlpha)
    end
    if e.owner.nameBackground then
        if e.nameBackgroundAlpha==nil then e.nameBackgroundAlpha=e.owner.nameBackground:GetAlpha() end
        e.owner.nameBackground:SetAlpha(above and 0 or e.nameBackgroundAlpha)
    end
    if above then
        if not e.displayName then e.displayName=e.health:CreateFontString(nil,"OVERLAY") end
        e.displayName:ClearAllPoints();e.displayName:SetPoint("BOTTOM",e.health,"TOP",0,4)
        e.displayName:SetFont(STANDARD_TEXT_FONT,self.db.fontSize+1,"OUTLINE")
        e.displayName:SetWidth(e.health:GetWidth()+20);e.displayName:Show()
    elseif e.displayName then e.displayName:Hide() end
end
function addon:PaintName(e,u)
    if e.displayName and self.db.namesAbove and self.db.bigBars and not e.minor then
        e.displayName:SetText(UnitName(u) or "")
        if e.name then e.displayName:SetTextColor(e.name:GetTextColor()) end
    end
end
local function skinButton(button,enabled,micro)
    if not button then return end
    local skin=buttonSkins[button]
    if not skin and enabled and not InCombatLockdown() then
        skin=button:CreateTexture(nil,"OVERLAY");skin:SetTexture(media.."ButtonEdge")
        if micro then
            -- Legacy microbuttons contain icons in their normal textures: do not tint them.
            skin:SetPoint("BOTTOMLEFT",button,"BOTTOMLEFT",1,1);skin:SetWidth(26);skin:SetHeight(36)
        else
            skin:SetPoint("TOPLEFT",button,"TOPLEFT",-1,1);skin:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",1,-1)
        end
        buttonSkins[button]=skin
    end
    if skin then if enabled then skin:Show() else skin:Hide() end end
    if not micro then
        local normal=button.GetNormalTexture and button:GetNormalTexture()
        tint(normal,enabled)
    end
end
function addon:ThemeButtons()
    local enabled=self.db.enabled and self.db.darkButtons
    for _,prefix in ipairs({"ActionButton","MultiBarBottomLeftButton","MultiBarBottomRightButton",
        "MultiBarLeftButton","MultiBarRightButton","BonusActionButton","PetActionButton","ShapeshiftButton"}) do
        for i=1,12 do skinButton(_G[prefix..i],enabled) end
    end
    for i=0,3 do skinButton(_G["CharacterBag"..i.."Slot"],enabled) end
    skinButton(MainMenuBarBackpackButton,enabled)
    for _,name in ipairs({"CharacterMicroButton","SpellbookMicroButton","TalentMicroButton","AchievementMicroButton",
        "QuestLogMicroButton","SocialsMicroButton","PVPMicroButton","LFDMicroButton","MainMenuMicroButton","HelpMicroButton"}) do
        skinButton(_G[name],enabled,true)
    end
    -- Weapon enchants have native duration/tooltip logic; add only the common edge.
    for i=1,2 do skinButton(_G["TempEnchant"..i],self.db.enabled and self.db.darkAuras,false) end
end
function addon:SkinAura(button,f)
    local enabled=self.db.enabled and self.db.darkAuras
    if f.mainPlayerAura then
        if not f.mainTrim and button and enabled and not InCombatLockdown() then
            local t=CreateFrame("Frame",nil,f);f.mainTrim=t;t:EnableMouse(false)
            t:SetPoint("TOPLEFT",button,"TOPLEFT",-2,2);t:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",2,-2)
            t:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        end
        if f.mainTrim then
            local k=self.db.darkness*.25;f.mainTrim:SetBackdropBorderColor(k,k,k,1)
            if enabled then f.mainTrim:Show() else f.mainTrim:Hide() end
        end
        if f.skin then f.skin:Hide() end
    else
        if not f.skin and button and enabled and not InCombatLockdown() then
            f.skin=f:CreateTexture(nil,"OVERLAY");f.skin:SetTexture(media.."ButtonEdge")
            f.skin:SetPoint("TOPLEFT",button,"TOPLEFT",-1,1);f.skin:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",1,-1)
        end
        if f.skin then if enabled then f.skin:Show() else f.skin:Hide() end end
    end
    -- The thin outer main-aura trim leaves native debuff-type/alert colours visible.
end
function addon:ManagePlayerAuraSpiral(f)
    if not f.mainPlayerAura then return end
    local cd=f.cooldown or f.nativeCooldown;if not cd then return end
    local hide=self.db.enabled and self.db.hidePlayerAuraSpirals
    if not cd.blkSpiralState then
        cd.blkSpiralState={alpha=cd:GetAlpha(),hidden=false}
        -- Do not hide/clear the cooldown: timer consumers still receive its data.
        -- Legacy OmniCC draws its text on the cooldown's parent, independently.
        hooksecurefunc(cd,"SetAlpha",function(_,alpha)
            local s=cd.blkSpiralState
            if not s.setting then
                s.alpha=alpha
                if s.hidden and alpha~=0 then s.setting=true;cd:SetAlpha(0);s.setting=nil end
            end
        end)
    end
    local state=cd.blkSpiralState
    if hide then
        if not state.hidden then state.alpha=cd:GetAlpha() end
        state.hidden=true;state.setting=true;cd:SetAlpha(0);state.setting=nil
    elseif state.hidden then
        state.hidden=false;state.setting=true;cd:SetAlpha(state.alpha);state.setting=nil
    end
end

-- Suppress only the resting badge; let Blizzard own level text, combat and vehicles.
function addon:UpdateRestBadge()
    if not self.db then return end
    if self.db.enabled and self.db.hideResting then
        self.restBadgeHidden=true
        if PlayerRestIcon then PlayerRestIcon:Hide() end
        if PlayerRestGlow then PlayerRestGlow:Hide() end
        if PlayerLevelText and not (UnitHasVehicleUI and UnitHasVehicleUI("player")) then PlayerLevelText:Show() end
    elseif self.restBadgeHidden then
        self.restBadgeHidden=nil
        if PlayerFrame_UpdateStatus then PlayerFrame_UpdateStatus() end
    end
end
if type(PlayerFrame_UpdateStatus)=="function" then
    hooksecurefunc("PlayerFrame_UpdateStatus",function() addon:UpdateRestBadge() end)
end
