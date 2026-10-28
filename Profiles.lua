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
        else self.db=self.accountDB end
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
    local list={{scope="default",label="Shared account settings (default account-wide)"}}
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
    local p=BetterLKFramesCharDB.activeProfile
    if p then return self:ProfileLabel(p.name,p.scope) end
    return BetterLKFramesCharDB.useCharacter and "Unnamed character settings" or "Shared account settings"
end
function addon:Profile(mode,name,scope)
    if mode=="load" and scope=="default" then return self:CharacterProfile("account") end
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
