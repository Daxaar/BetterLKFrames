-- Conservative decorative-rim copies. Never tint an entire mixed parchment/icon atlas.
local addon=BetterLKFrames
local originals=setmetatable({}, {__mode="k"})
local own=setmetatable({}, {__mode="k"})
local copies=setmetatable({}, {__mode="k"})
local hooked=setmetatable({}, {__mode="k"})
local function tint(texture,on)
    if not texture or not texture.SetVertexColor then return end
    if not originals[texture] then originals[texture]={texture:GetVertexColor()} end
    local c=originals[texture];local f=on and addon.db.darkness or 1
    texture:SetVertexColor(c[1]*f,c[2]*f,c[3]*f,c[4] or 1)
end
function addon:RegisterOptionsArt(button)
    self.optionsArt=self.optionsArt or {};self.optionsArt[#self.optionsArt+1]=button
end
function addon:ThemeOptions()
    if not self.options then return end
    local on=self.db.enabled and self.db.darkWindows
    local factor=on and self.db.darkness or 1
    self.options:SetBackdropBorderColor(factor,factor,factor,1)
    for _,slider in ipairs(self.optionsSliders or {}) do
        if not slider.blkBorderColour then slider.blkBorderColour={slider:GetBackdropBorderColor()} end
        local c=slider.blkBorderColour
        slider:SetBackdropBorderColor(c[1]*factor,c[2]*factor,c[3]*factor,c[4] or 1)
    end
    for _,b in ipairs(self.optionsArt or {}) do
        tint(b.GetNormalTexture and b:GetNormalTexture(),on)
        tint(b.GetPushedTexture and b:GetPushedTexture(),on)
        -- Check marks, labels, highlights and slider thumbs remain bright.
    end
end
local function edges(path)
    if type(path)~="string" then return end
    path=string.lower(path):gsub("/","\\"):gsub("%.tga$","")
    local base=path:match("([^\\]+)$")
    if path:find("interface\\paperdollinfoframe\\ui%-character%-general%-") or path:find("interface\\spellbook\\ui%-spellbookpanel%-") then
        if base:find("topleft$") then return "LT" end
        if base:find("topright$") then return "RT" end
        if base:find("botleft$") or base:find("bottomleft$") then return "LB" end
        if base:find("botright$") or base:find("bottomright$") then return "RB" end
    end
    if path=="interface\\questframe\\ui-questlogdualpane-left" then return "LTB" end
    if path=="interface\\questframe\\ui-questlogdualpane-right" then return "RTB" end
    if path=="interface\\containerframe\\ui-bag-components" or path=="interface\\containerframe\\ui-bag-1slot" then return "LRTB" end
    if path:find("interface\\worldmap\\ui%-worldmap%-top") then return "T" end
    if path:find("interface\\worldmap\\ui%-worldmap%-bottom") then return "B" end
    if path:find("interface\\worldmap\\ui%-worldmap%-middle1$") then return "L" end
    if path:find("interface\\worldmap\\ui%-worldmap%-middle4$") then return "R" end
    if path=="interface\\worldmap\\ui-worldmapsmall-left" then return "LTB" end
    if path=="interface\\worldmap\\ui-worldmapsmall-right" then return "RTB" end
end
addon.WindowEdges=edges
local function uv(c,u,v)
    -- GetTexCoord returns UL, LL, UR, LR pairs (also handles flipped coordinates).
    return (1-u)*((1-v)*c[1]+v*c[3])+u*((1-v)*c[5]+v*c[7]),
           (1-u)*((1-v)*c[2]+v*c[4])+u*((1-v)*c[6]+v*c[8])
end
local function update(source)
    if own[source] then return end
    if source:GetObjectType()~="Texture" then return end
    local path=source:GetTexture();local which=edges(path)
    local old=copies[source]
    if not which then if old then for _,t in pairs(old) do t:Hide() end end;return end
    local enabled=addon.db.enabled and addon.db.darkWindows and source:IsShown()
    if not enabled then if old then for _,t in pairs(old) do t:Hide() end end;return end
    local w,h=source:GetWidth(),source:GetHeight();if not w or not h or w<=0 or h<=0 then return end
    local c={source:GetTexCoord()};if #c~=8 then return end
    if not old then old={};copies[source]=old end
    local boxes={L={0,0,math.min(16,w),h},R={math.max(0,w-16),0,math.min(16,w),h},
        T={0,0,w,math.min(12,h)},B={0,math.max(0,h-12),w,math.min(12,h)}}
    for key,box in pairs(boxes) do
        local t=old[key]
        if which:find(key) then
            if not t and not InCombatLockdown() then
                t=source:GetParent():CreateTexture(nil,"ARTWORK");old[key]=t;own[t]=true
            end
            if t then
                local geometry=path..":"..w..":"..h..":"..table.concat(c,":")
                if not InCombatLockdown() and t.blkGeometry~=geometry then
                    t.blkGeometry=geometry
                    local x,y,bw,bh=unpack(box)
                    t:ClearAllPoints();t:SetPoint("TOPLEFT",source,"TOPLEFT",x,-y);t:SetWidth(bw);t:SetHeight(bh)
                    t:SetTexture(path)
                    local a,b=uv(c,x/w,y/h);local d,e=uv(c,x/w,(y+bh)/h)
                    local f,g=uv(c,(x+bw)/w,y/h);local i,j=uv(c,(x+bw)/w,(y+bh)/h)
                    t:SetTexCoord(a,b,d,e,f,g,i,j)
                end
                local r,g,b,a=source:GetVertexColor();local k=addon.db.darkness
                t:SetVertexColor(r*k,g*k,b*k,a or 1);t:SetAlpha(source:GetAlpha());t:Show()
            end
        elseif t then t:Hide() end
    end
end
local roots={"QuestLogFrame","QuestLogDetailFrame","SpellBookFrame","CharacterFrame","PlayerTalentFrame",
    "WorldMapFrame","MerchantFrame","BankFrame","FriendsFrame","GossipFrame","QuestFrame","TradeFrame","MailFrame","AuctionFrame"}
local function scan(frame,depth)
    if not frame or not frame.GetRegions then return end
    for _,r in ipairs({frame:GetRegions()}) do update(r) end
    if depth>0 and frame.GetChildren then for _,f in ipairs({frame:GetChildren()}) do scan(f,depth-1) end end
end
function addon:ThemeWindows()
    if not self.db.enabled or not self.db.darkWindows then
        for _,list in pairs(copies) do for _,t in pairs(list) do t:Hide() end end
        return
    end
    local function visit(frame)
        if not frame then return end
        if not hooked[frame] then
            frame:HookScript("OnShow",function() if addon.db then scan(frame,1) end end);hooked[frame]=true
        end
        if frame:IsShown() then scan(frame,1) end
    end
    for _,name in ipairs(roots) do visit(_G[name]) end
    for i=1,13 do visit(_G["ContainerFrame"..i]) end
end
