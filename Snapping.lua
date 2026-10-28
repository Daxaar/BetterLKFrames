local addon=BetterLKFrames
local abs=math.abs
-- All calculations use UIParent coordinates, independent of per-frame scale.
local function rect(frame)
    local ratio=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local left,bottom=frame:GetLeft(),frame:GetBottom()
    if not left or not bottom then return end
    return {x=left*ratio,y=bottom*ratio,w=frame:GetWidth()*ratio,h=frame:GetHeight()*ratio}
end
addon.FrameRect=rect
function addon:MoveEntry(name)
    return name=="PartyGroup" and self.partyGroup or self.frames[name]
end
function addon:ComputeSnap(name,r,bypass)
    if bypass or not self.db.snapFrames then return r.x,r.y end
    local bestX,bestY=self.db.snapDistance+.001,self.db.snapDistance+.001
    local x,y,gx,gy=r.x,r.y,nil,nil
    local function candidate(axis,delta,line)
        local d=abs(delta)
        if axis=="x" and d<bestX then bestX=d;x=r.x+delta;gx=line
        elseif axis=="y" and d<bestY then bestY=d;y=r.y+delta;gy=line end
    end
    -- Screen centre and edges. Compare each frame's centre, not just its left edge.
    local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
    candidate("x",sw/2-(r.x+r.w/2),sw/2);candidate("y",sh/2-(r.y+r.h/2),sh/2)
    candidate("x",-r.x,0);candidate("x",sw-r.x-r.w,sw)
    candidate("y",-r.y,0);candidate("y",sh-r.y-r.h,sh)
    local entries={}
    for other,e in pairs(self.frames) do
        if not other:match("^PartyMemberFrame%d$") then entries[other]=e end
    end
    if self.partyGroup then entries.PartyGroup=self.partyGroup end
    for other,e in pairs(entries) do
        if other~=name and e.owner:IsShown() then
            local o=rect(e.owner)
            if o then
                for _,a in ipairs({0,.5,1}) do
                    -- Match corresponding edges/centres; also allow edge-to-edge abutment.
                    candidate("x",o.x+o.w*a-r.x-r.w*a,o.x+o.w*a)
                    candidate("y",o.y+o.h*a-r.y-r.h*a,o.y+o.h*a)
                end
                local mirror=sw-(o.x+o.w/2)
                candidate("x",mirror-(r.x+r.w/2),mirror)
                candidate("x",o.x-r.x-r.w,o.x);candidate("x",o.x+o.w-r.x,o.x+o.w)
                candidate("y",o.y-r.y-r.h,o.y);candidate("y",o.y+o.h-r.y,o.y+o.h)
            end
        end
    end
    if self.db.snapGrid then
        local grid=self.db.gridSize
        -- Grid is fallback only: explicit alignment gets priority.
        if not gx then gx=sw/2+math.floor((r.x+r.w/2-sw/2)/grid+.5)*grid;x=gx-r.w/2 end
        if not gy then gy=sh/2+math.floor((r.y+r.h/2-sh/2)/grid+.5)*grid;y=gy-r.h/2 end
    end
    return x,y,gx,gy
end
function addon:ShowMoveGuides(show)
    if show and ((not self.db.showGuides and not self.db.showGrid) or InCombatLockdown()) then
        if self.guides then self.guides:Hide() end;return
    end
    if show and not self.guides then
        local f=CreateFrame("Frame",nil,UIParent);f:SetAllPoints(UIParent);f:SetFrameStrata("DIALOG");f:EnableMouse(false)
        self.guides=f
        local function line(vertical,r,g,b)
            local t=f:CreateTexture(nil,"OVERLAY");t:SetTexture("Interface\\Buttons\\WHITE8X8");t:SetVertexColor(r,g,b,.7)
            if vertical then t:SetWidth(1);t:SetHeight(UIParent:GetHeight())
            else t:SetHeight(1);t:SetWidth(UIParent:GetWidth()) end
            return t
        end
        f.cx=line(true,.3,.8,.8);f.cy=line(false,.3,.8,.8)
        f.cx:SetPoint("CENTER",UIParent,"CENTER",0,0);f.cy:SetPoint("CENTER",UIParent,"CENTER",0,0)
        f.x=line(true,1,.8,.2);f.y=line(false,1,.8,.2)
    end
    if self.guides then
        if show then
            self:BuildMoveGrid()
            self.guides:Show();self.guides.x:Hide();self.guides.y:Hide()
            if self.db.showGuides then self.guides.cx:Show();self.guides.cy:Show() else self.guides.cx:Hide();self.guides.cy:Hide() end
        else self.guides:Hide() end
    end
end
function addon:PreviewSnap(name)
    if InCombatLockdown() then self:ShowMoveGuides(false);return end
    local e=self:MoveEntry(name);local r=rect(e.owner);if not r then return end
    local _,_,gx,gy=self:ComputeSnap(name,r,IsShiftKeyDown())
    local f=self.guides;if not f or not self.db.showGuides then return end
    if gx then f.x:ClearAllPoints();f.x:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",gx,0);f.x:Show() else f.x:Hide() end
    if gy then f.y:ClearAllPoints();f.y:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,gy);f.y:Show() else f.y:Hide() end
end
function addon:FinishSnap(name)
    if InCombatLockdown() then return end
    local e=self:MoveEntry(name);local r=rect(e.owner);if not r then return end
    local x,y=self:ComputeSnap(name,r,IsShiftKeyDown())
    local ratio=e.owner:GetEffectiveScale()/UIParent:GetEffectiveScale()
    e.owner:ClearAllPoints();e.owner:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x/ratio,y/ratio)
end

function addon:BuildMoveGrid()
    local f=self.guides;if not f then return end
    f.grid=f.grid or {};f.gridLabels=f.gridLabels or {}
    local w,h,g=UIParent:GetWidth(),UIParent:GetHeight(),self.db.gridSize
    local key=w..":"..h..":"..g..":"..tostring(self.db.showGrid)
    if f.gridKey==key then return end
    f.gridKey=key
    for _,t in ipairs(f.grid) do t:Hide() end
    for _,t in ipairs(f.gridLabels) do t:Hide() end
    if not self.db.showGrid then return end
    local n,labels=0,0
    local function line(vertical,index)
        n=n+1;local t=f.grid[n]
        if not t then t=f:CreateTexture(nil,"BACKGROUND");f.grid[n]=t;t:SetTexture("Interface\\Buttons\\WHITE8X8") end
        t:ClearAllPoints()
        if vertical then
            t:SetWidth(1);t:SetHeight(h);t:SetPoint("CENTER",UIParent,"CENTER",index*g,0)
        else t:SetWidth(w);t:SetHeight(1);t:SetPoint("CENTER",UIParent,"CENTER",0,index*g) end
        local major=index%4==0;t:SetVertexColor(.65,.75,.8,major and .35 or .16);t:Show()
        if major and index~=0 then
            labels=labels+1;local text=f.gridLabels[labels]
            if not text then text=f:CreateFontString(nil,"OVERLAY");f.gridLabels[labels]=text;text:SetFont(STANDARD_TEXT_FONT,10,"OUTLINE") end
            text:ClearAllPoints()
            if vertical then text:SetPoint("CENTER",UIParent,"CENTER",index*g,12)
            else text:SetPoint("CENTER",UIParent,"CENTER",14,index*g) end
            text:SetText(tostring(index));text:SetTextColor(.8,.85,.9);text:Show()
        end
    end
    for i=-math.floor(w/2/g),math.floor(w/2/g) do line(true,i) end
    for i=-math.floor(h/2/g),math.floor(h/2/g) do line(false,i) end
end
