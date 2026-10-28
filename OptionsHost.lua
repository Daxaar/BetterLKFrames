-- One settings tree, moved between UIParent and the native AddOns category.
local addon=BetterLKFrames
local function escapeRegistration(enabled)
    for i=#UISpecialFrames,1,-1 do
        if UISpecialFrames[i]=="BetterLKFramesOptions" then table.remove(UISpecialFrames,i) end
    end
    if enabled then table.insert(UISpecialFrames,"BetterLKFramesOptions") end
end
local function hideInterface()
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
        if HideUIPanel then HideUIPanel(InterfaceOptionsFrame) else InterfaceOptionsFrame:Hide() end
    end
end
function addon:CloseOptions()
    if self.optionsContext=="embedded" then hideInterface() end
    if self.options then self.options:Hide() end
end
function addon:ShowStandaloneOptions()
    if not self.options then self:BuildOptions() end
    self.options:Hide();hideInterface();CloseDropDownMenus()
    local f=self.options
    self.optionsContext="standalone";f:SetParent(UIParent);f:SetScale(1)
    f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    f:SetFrameStrata("DIALOG");f:SetFrameLevel(1);f:SetMovable(true)
    f:SetBackdrop(self.optionsBackdrop);f:SetBackdropColor(.08,.08,.08,.98)
    self.optionsClose:Show();escapeRegistration(true)
    f:Show();if f.Raise then f:Raise() end
    self:RefreshOptions();self:ThemeOptions()
end
function addon:FitEmbeddedOptions()
    if self.optionsContext~="embedded" then return end
    local width=self.optionsScroll:GetWidth()
    if width<=1 then width=self.optionsCategory:GetWidth()-28 end
    width=math.max(1,width)
    local scale=math.min(1,width/640)
    self.options:SetScale(scale)
    self.optionsScrollChild:SetWidth(width);self.optionsScrollChild:SetHeight(610*scale)
end
function addon:ShowEmbeddedOptions()
    local f=self.options
    f:Hide();CloseDropDownMenus()
    self.optionsContext="embedded";f:SetParent(self.optionsScrollChild)
    f:ClearAllPoints();f:SetPoint("TOPLEFT",self.optionsScrollChild,"TOPLEFT",0,0)
    f:SetMovable(false);f:SetBackdrop(nil)
    f:SetFrameStrata(self.optionsCategory:GetFrameStrata())
    f:SetFrameLevel(self.optionsScrollChild:GetFrameLevel()+1)
    self.optionsClose:Hide();escapeRegistration(false)
    self:FitEmbeddedOptions();self.optionsScroll:SetVerticalScroll(0)
    f:Show();self:RefreshOptions();self:ThemeOptions()
end
function addon:BuildEmbeddedOptions()
    if not InterfaceOptions_AddCategory or self.optionsCategory then return end
    local panel=CreateFrame("Frame","BetterLKFramesInterfaceOptions",InterfaceOptionsFramePanelContainer or UIParent)
    panel.name="BetterLKFrames";panel:Hide();self.optionsCategory=panel
    local scroll=CreateFrame("ScrollFrame","BetterLKFramesOptionsScroll",panel,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",panel,"TOPLEFT",0,-4);scroll:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-28,4)
    local child=CreateFrame("Frame",nil,scroll);child:SetWidth(640);child:SetHeight(610)
    scroll:SetScrollChild(child);self.optionsScroll=scroll;self.optionsScrollChild=child
    scroll:HookScript("OnSizeChanged",function() addon:FitEmbeddedOptions() end)
    panel:SetScript("OnShow",function() addon:ShowEmbeddedOptions() end)
    panel:SetScript("OnHide",function()
        if addon.optionsContext=="embedded" then addon.options:Hide() end
    end)
    InterfaceOptions_AddCategory(panel)
end
