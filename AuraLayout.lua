-- Move only an aura row rooted directly on the native unit frame.
-- Later rows/icons follow Blizzard's existing anchor chain without a custom layout.
local addon=BetterLKFrames
local changed=setmetatable({}, {__mode="k"})
local function offset(self,name)
    if InCombatLockdown() then self.auraLayoutPending=true;return end
    for _,prefix in ipairs({"Buff","Debuff"}) do
        local button=_G[name..prefix.."1"]
        if button then
            local point,relative,relativePoint,x,y=button:GetPoint(1)
            local old=changed[button]
            if old and point==old.point and relative==old.relative and relativePoint==old.relativePoint and x==old.x and y==old.y-old.amount then
                y=old.y -- Undo only our own offset; never accumulate it.
            end
            local amount=self.db.enabled and self.db.bigBars and self.db.auraOffset or 0
            if relative==_G[name] or relative==name then
                if point and amount>0 then
                    button:ClearAllPoints();button:SetPoint(point,relative,relativePoint,x,y-amount)
                    changed[button]={point=point,relative=relative,relativePoint=relativePoint,x=x,y=y,amount=amount}
                elseif old and point then
                    button:ClearAllPoints();button:SetPoint(point,relative,relativePoint,x,y);changed[button]=nil
                end
            else changed[button]=nil end
        end
    end
end
function addon:RefreshAuraOffset()
    if not self.db then return end
    offset(self,"TargetFrame");offset(self,"FocusFrame");self.auraLayoutPending=InCombatLockdown() or nil
end
if type(TargetFrame_UpdateAuras)=="function" then
    hooksecurefunc("TargetFrame_UpdateAuras",function(frame)
        if addon.db and frame and (frame==TargetFrame or frame==FocusFrame) then addon:RefreshAuraOffset() end
    end)
end
