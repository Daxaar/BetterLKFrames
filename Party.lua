-- One unprotected placement preview; native secure unit frames are never shown,
-- reparented or given fake units. Their pet-aware Blizzard anchor chain is retained.
local addon=BetterLKFrames
local white="Interface\\Buttons\\WHITE8X8"
local function partyName(i) return "PartyMemberFrame"..i end
local function first() return addon.frames.PartyMemberFrame1 end
local function finish()
    local g=addon.partyGroup;if not g then return end
    g.owner:StopMovingOrSizing();g.dragging=nil;g.stopPending=nil
    local e=first()
    if not e or g.dragDB~=addon.db or not addon.db.enabled then g.dragDB=nil;return end
    local f=g.owner;local ratio=e.owner:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x,y=f:GetLeft(),f:GetBottom()
    if not x or not y then g.dragDB=nil;return end
    if addon.FinishSnap then addon:FinishSnap("PartyGroup");x,y=f:GetLeft(),f:GetBottom() end
    addon.db.positions.PartyMemberFrame1={x=x,y=y+f:GetHeight()-e.owner:GetHeight()*ratio}
    -- A deliberate group move replaces any old individual party placements.
    -- Pet anchors keep their native offsets, including dynamic pet visibility.
    addon.db.partyGrouped=true
    for i=2,4 do addon.db.positions[partyName(i)]=nil end
    g.dragDB=nil;addon:CommitSettings()
end
function addon:ApplyPartyChain()
    if InCombatLockdown() or not self.db.enabled or not self.db.partyGrouped or not self.db.positions.PartyMemberFrame1 then return end
    for i=2,4 do
        local member=self.frames[partyName(i)]
        if member then
            local pet=_G[partyName(i-1).."PetFrame"]
            local anchor=pet or _G[partyName(i-1)]
            member.owner:ClearAllPoints()
            member.owner:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",pet and -23 or 0,-10)
            member.positionApplied=nil
        end
    end
end
function addon:FinishPendingPartyMove()
    if self.partyGroup and self.partyGroup.stopPending then finish() end
end
function addon:UpdatePartyMover(show)
    if InCombatLockdown() then return end
    local e=first();if not e then return end
    local g=self.partyGroup
    if not g then
        local f=CreateFrame("Frame",nil,UIParent)
        g={owner=f};self.partyGroup=g
        f:SetFrameStrata("DIALOG");f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
        f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
        f:SetBackdropColor(.12,.6,.5,.4);f:SetBackdropBorderColor(.5,1,.8,1)
        f.label=f:CreateFontString(nil,"OVERLAY");f.label:SetFont(STANDARD_TEXT_FONT,11,"OUTLINE")
        f.label:SetPoint("TOPLEFT",3,-3);f.label:SetWidth(122);f.label:SetHeight(34)
        f.label:SetText("Party group\nRelease to place")
        f.rows={}
        for i=1,4 do
            local row=f:CreateFontString(nil,"OVERLAY");row:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE")
            row:SetPoint("TOPLEFT",4,-37-(i-1)*53);row:SetText("Party slot "..i.." (preview)")
            f.rows[i]=row
        end
        f:SetScript("OnDragStart",function()
            if InCombatLockdown() or not addon.unlocked or not addon.db.enabled then return end
            g.dragDB=addon.db;g.dragging=true;f:StartMoving()
        end)
        f:SetScript("OnUpdate",function()
            if g.dragging and not InCombatLockdown() and addon.PreviewSnap then addon:PreviewSnap("PartyGroup") end
        end)
        f:SetScript("OnDragStop",function()
            if not g.dragging then return end
            -- This preview has no protected relatives: stop it immediately even
            -- in combat, but defer native anchoring and persistence until safe.
            f:StopMovingOrSizing()
            if InCombatLockdown() then g.dragging=nil;g.stopPending=true;addon.pending=true;return end
            finish();addon:Apply()
        end)
        f:SetScript("OnHide",function() if g.dragging then f:GetScript("OnDragStop")() end end)
        f:Hide()
    end
    if show==nil then show=self.unlocked and self.db.enabled end
    if not show then g.owner:Hide();return end
    if g.dragging then return end
    local native=e.owner;local ratio=native:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x,y=native:GetLeft(),native:GetBottom();if not x or not y then return end
    local w,h=native:GetWidth()*ratio,native:GetHeight()*ratio
    -- Reserve four slots even while solo. A preview, not a fabricated party.
    local height=math.max(h*4,249*ratio)
    for i=2,4 do
        local member=_G[partyName(i)]
        if member then
            local mr=member:GetEffectiveScale()/UIParent:GetEffectiveScale()
            local bottom=member:GetBottom()
            if bottom then height=math.max(height,(y+native:GetHeight())*ratio-bottom*mr) end
        end
    end
    local f=g.owner
    f:SetScale(1);f:SetWidth(math.max(w,140*ratio));f:SetHeight(height)
    f.label:SetWidth(f:GetWidth()-8)
    f:ClearAllPoints();f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x*ratio,(y+native:GetHeight())*ratio)
    for i,row in ipairs(f.rows) do
        row:ClearAllPoints();row:SetPoint("TOPLEFT",4,-37*ratio-(i-1)*53*ratio)
        if not UnitExists("party"..i) then row:Show() else row:Hide() end
    end
    f:Show()
end
function addon:HidePartyMoverForCombat()
    local g=self.partyGroup
    if g then g.owner:Hide() end -- Independent preview has no protected anchors.
end
