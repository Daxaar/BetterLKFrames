local addon=BetterLKFrames
-- Store snapshots without the shared library: never embed profiles inside profiles.
local function snapshot(settings)
    local result={}
    for key,value in pairs(settings) do if key~="profiles" then result[key]=addon.Copy(value) end end
    return result
end
local function library(self,scope)
    if scope=="account" then return self.accountDB.profiles end
    if scope=="character" then return BetterLKFramesCharDB.profiles end
end
function addon:InitSettings()
    BetterLKFramesDB=self.Normalize(BetterLKFramesDB)
    if type(BetterLKFramesCharDB)~="table" then BetterLKFramesCharDB={} end
    if type(BetterLKFramesCharDB.profiles)~="table" then BetterLKFramesCharDB.profiles={} end
    self.accountDB=BetterLKFramesDB
    local selected=BetterLKFramesCharDB.activeProfile
    local saved=type(selected)=="table" and library(self,selected.scope)
    saved=saved and saved[selected.name]
    if type(saved)=="table" then
        self.db=self.Normalize(snapshot(saved));self.db.profiles=self.accountDB.profiles
    else
        BetterLKFramesCharDB.activeProfile=nil
        if BetterLKFramesCharDB.useCharacter and type(BetterLKFramesCharDB.settings)=="table" then
            self.db=self.Normalize(BetterLKFramesCharDB.settings)
            self.db.profiles=self.accountDB.profiles
            BetterLKFramesCharDB.settings=self.db
        else BetterLKFramesCharDB.useCharacter=false;self.db=self.accountDB end
    end
end
function addon:CommitSettings()
    local selected=BetterLKFramesCharDB and BetterLKFramesCharDB.activeProfile
    if selected then
        library(self,selected.scope)[selected.name]=snapshot(self.db)
    elseif BetterLKFramesCharDB and BetterLKFramesCharDB.useCharacter then
        self.db.profiles=self.accountDB.profiles
        BetterLKFramesCharDB.settings=self.db
    else BetterLKFramesDB=self.db;self.accountDB=self.db end
end
function addon:ProfileLabel(name,scope)
    if scope=="character" then return (UnitName("player") or "Character").." - "..name.." (character)" end
    return name.." (account)"
end
function addon:ListProfiles()
    local list={{scope="default",label="Default (account-wide)"}}
    if type(BetterLKFramesCharDB.settings)=="table" then
        list[#list+1]={scope="legacy-character",label=self:ProfileRefLabel({scope="legacy-character"})}
    end
    for _,scope in ipairs({"account","character"}) do
        for name,data in pairs(library(self,scope)) do
            if type(name)=="string" and type(data)=="table" then
                list[#list+1]={name=name,scope=scope,label=self:ProfileLabel(name,scope)}
            end
        end
    end
    table.sort(list,function(a,b) return a.label<b.label end)
    return list
end
function addon:ActiveProfileLabel()
    return self:ProfileRefLabel(self:ActiveProfileRef())
end
function addon:Profile(mode,name,scope)
    if mode=="load" and scope=="default" then return self:CharacterProfile("account") end
    if mode=="load" and scope=="legacy-character" then return self:CharacterProfile("resume") end
    if InCombatLockdown() then self:Message("Switch or save profiles outside combat.");return false end
    name=type(name)=="string" and name or ""
    if mode=="save" then name=name:match("^%s*(.-)%s*$") end
    scope=scope or "account"
    local profiles=library(self,scope)
    if name=="" or (mode=="save" and #name>40) or not profiles then self:Message("Use /bf profile save NAME or /bf profile load NAME (account-wide).");return false end
    if mode=="save" then
        local active=BetterLKFramesCharDB.activeProfile
        if profiles[name] and not (active and active.name==name and active.scope==scope) then
            self:Message("That profile already exists in this scope. Select it to edit it, or use a new name.");return false
        end
        profiles[name]=snapshot(self.db)
    elseif mode~="load" then return false end
    if type(profiles[name])~="table" then self:Message("Unknown profile: "..name);return false end
    self:CommitSettings()
    BetterLKFramesCharDB.activeProfile={name=name,scope=scope}
    self.db=self.Normalize(snapshot(profiles[name]));self.db.profiles=self.accountDB.profiles
    self:CommitSettings();self:Apply()
    if self.RefreshOptions then self:RefreshOptions() end
    self:Message("Active profile: "..self:ProfileLabel(name,scope))
    return true
end
function addon:ResetSettings()
    if InCombatLockdown() then self:Message("Reset is unavailable during combat.");return false end
    local profiles=self.accountDB.profiles
    local named=BetterLKFramesCharDB.activeProfile
    self.db=self.Copy(self.defaults)
    if named or BetterLKFramesCharDB.useCharacter then self.db.profiles=profiles end
    self:CommitSettings();self:Apply()
    if self.RefreshOptions then self:RefreshOptions() end
    self:Message("Defaults restored for the active settings scope.")
    return true
end
function addon:CharacterProfile(mode)
    if InCombatLockdown() then self:Message("Switch character settings outside combat.");return false end
    if mode~="account" and mode~="copy" and mode~="defaults" and mode~="blizzard" and
        not (mode=="resume" and type(BetterLKFramesCharDB.settings)=="table") then
        self:Message("/bf character account | copy | defaults | blizzard | resume");return false
    end
    self:CommitSettings()
    local settings
    if mode=="copy" or mode=="defaults" or mode=="blizzard" then
        settings=self.Normalize(snapshot(mode=="copy" and self.db or self.defaults))
        if mode=="blizzard" then settings.enabled=false end
    end
    BetterLKFramesCharDB.activeProfile=nil
    if mode=="account" then
        BetterLKFramesCharDB.useCharacter=false;self.db=self.accountDB
    elseif mode=="resume" then
        BetterLKFramesCharDB.useCharacter=true;self.db=self.Normalize(BetterLKFramesCharDB.settings)
    else BetterLKFramesCharDB.useCharacter=true;self.db=settings end
    self:CommitSettings();self:Apply()
    if self.RefreshOptions then self:RefreshOptions() end
    self:Message(BetterLKFramesCharDB.useCharacter and "Character-only settings active." or "Shared account settings active.")
    return true
end

-- References identify the protected account configuration separately from named profiles.
function addon:ActiveProfileRef()
    local active=BetterLKFramesCharDB.activeProfile
    if active then return {scope=active.scope,name=active.name} end
    return {scope=BetterLKFramesCharDB.useCharacter and "legacy-character" or "default"}
end
function addon:SameProfile(a,b)
    return a and b and a.scope==b.scope and a.name==b.name
end
function addon:GetProfile(ref)
    if type(ref)~="table" then return end
    if ref.scope=="default" then return self.accountDB end
    if ref.scope=="legacy-character" then return BetterLKFramesCharDB.settings end
    local profiles=library(self,ref.scope)
    if profiles and type(ref.name)=="string" then return profiles[ref.name] end
end
function addon:ProfileRefLabel(ref)
    if ref.scope=="default" then return "Default (account-wide)" end
    if ref.scope=="legacy-character" then return (UnitName("player") or "Character").." - Previous settings (character)" end
    return self:ProfileLabel(ref.name,ref.scope)
end
function addon:PrepareProfileAction(action,subject)
    if InCombatLockdown() then self:Message("Manage profiles outside combat.");return end
    if action~="copy" and action~="delete" and action~="reset" then return end
    if action=="delete" and (not subject or subject.scope=="default") then
        self:Message("The default account profile cannot be deleted.");return
    end
    self:CommitSettings()
    local active=self:ActiveProfileRef()
    if action=="copy" and self:SameProfile(active,subject) then return end
    local object=subject and self:GetProfile(subject)
    if action~="reset" and type(object)~="table" then self:Message("Profile no longer exists.");return end
    return {action=action,character=BetterLKFramesCharDB,target=active,targetObject=self:GetProfile(active),
        subject=subject and {scope=subject.scope,name=subject.name},subjectObject=object}
end
function addon:ConfirmProfileAction(request)
    if type(request)~="table" or request.used then return false end
    request.used=true
    if InCombatLockdown() or request.character~=BetterLKFramesCharDB then
        self:Message("Profile context changed; reopen the confirmation outside combat.");return false
    end
    local action=request.action
    if action~="copy" and action~="delete" and action~="reset" then return false end
    if action~="reset" then
        if not request.subject or self:GetProfile(request.subject)~=request.subjectObject or type(request.subjectObject)~="table" then
            self:Message("Profile changed; reopen the confirmation.");return false
        end
    end
    if action=="delete" then
        local ref=request.subject
        if ref.scope=="default" then self:Message("The default account profile cannot be deleted.");return false end
        if self:SameProfile(self:ActiveProfileRef(),ref) and not self:CharacterProfile("account") then return false end
        if ref.scope=="legacy-character" then BetterLKFramesCharDB.settings=nil
        else
            local profiles=library(self,ref.scope)
            if not profiles then return false end
            profiles[ref.name]=nil
        end
        self:Message("Deleted "..self:ProfileRefLabel(ref)..".")
    else
        if not self:SameProfile(self:ActiveProfileRef(),request.target) or self:GetProfile(request.target)~=request.targetObject then
            self:Message("Active profile changed; reopen the confirmation.");return false
        end
        local profiles=self.accountDB.profiles
        self.db=self.Normalize(snapshot(action=="copy" and request.subjectObject or self.defaults))
        self.db.profiles=profiles
        self:CommitSettings();self:Apply()
        self:Message(action=="copy" and "Settings copied into the current profile." or "Current profile reset to defaults.")
    end
    if self.RefreshOptions then self:RefreshOptions() end
    return true
end
