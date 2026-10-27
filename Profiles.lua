local addon=BetterLKFrames
function addon:InitSettings()
    BetterLKFramesDB=self.Normalize(BetterLKFramesDB)
    if type(BetterLKFramesCharDB)~="table" then BetterLKFramesCharDB={} end
    self.accountDB=BetterLKFramesDB
    if BetterLKFramesCharDB.useCharacter and type(BetterLKFramesCharDB.settings)=="table" then
        self.db=self.Normalize(BetterLKFramesCharDB.settings)
        self.db.profiles=self.accountDB.profiles
        BetterLKFramesCharDB.settings=self.db
    else self.db=self.accountDB end
end
function addon:CommitSettings()
    if BetterLKFramesCharDB and BetterLKFramesCharDB.useCharacter then
        self.db.profiles=self.accountDB.profiles
        BetterLKFramesCharDB.settings=self.db
    else BetterLKFramesDB=self.db;self.accountDB=self.db end
end
function addon:CharacterProfile(mode)
    if InCombatLockdown() then self:Message("Switch character settings outside combat.");return false end
    if mode=="account" then
        BetterLKFramesCharDB.useCharacter=false;self.db=self.accountDB
    elseif mode=="resume" and type(BetterLKFramesCharDB.settings)=="table" then
        BetterLKFramesCharDB.useCharacter=true
        self.db=self.Normalize(BetterLKFramesCharDB.settings);self:CommitSettings()
    elseif mode=="copy" or mode=="defaults" or mode=="blizzard" then
        local settings=self.Copy(mode=="copy" and self.db or self.defaults)
        settings.profiles=self.accountDB.profiles
        if mode=="blizzard" then settings.enabled=false end
        BetterLKFramesCharDB.useCharacter=true;self.db=settings;self:CommitSettings()
    else self:Message("/blkf character account | copy | defaults | blizzard | resume");return false end
    self:Apply()
    self:Message(BetterLKFramesCharDB.useCharacter and "Character-only settings active." or "Shared account settings active.")
    return true
end
