local a=BetterLKFrames
local n=0
local function ok(v,name) assert(v,name);n=n+1;print("PASS followups "..name) end
local function button(page,title)
 for _,child in ipairs(page.children or {}) do if child:GetText()==title then return child end end
 error("Missing button: "..title)
end
local function openAuras()
 a:SelectOptionsPage(3);a.options:Show()
end
BetterLKFramesDB=nil;BetterLKFramesCharDB=nil;a:InitSettings();a:Apply()
-- #4: shared settings are a permanent selectable configuration, not a new snapshot.
a:Set("healthHeight",24);a.db.positions.PlayerFrame={x=321,y=123};a:CommitSettings()
local account=a.accountDB
ok(a:Profile("save","Private","character"),"create private profile before returning to default")
a:Set("healthHeight",27);a.db.positions.PlayerFrame={x=800,y=400};a:CommitSettings()
local menu=OpenTestMenu(a.profileSelector);local default
for _,entry in ipairs(menu) do if entry.text=="Shared account settings (default account-wide)" then default=entry end end
ok(default and not default.checked,"default account-wide entry remains available while private profile is active")
default.func()
ok(a.db==account and a.db.healthHeight==24 and a.db.positions.PlayerFrame.x==321,"default selection preserves original shared settings and layout")
ok(BetterLKFramesCharDB.activeProfile==nil and not BetterLKFramesCharDB.useCharacter,"default choice persists as shared account scope")
a:InitSettings();ok(a.db==account and a.db.healthHeight==24,"default survives reload initialization")
ok(a:Profile("load","Private","character") and a.db.healthHeight==27 and a.db.positions.PlayerFrame.x==800,"return to private profile retains its independent settings")
a:CharacterProfile("account");a:Reset()
menu=OpenTestMenu(a.profileSelector);local defaults=0
for _,entry in ipairs(menu) do if entry.text=="Shared account settings (default account-wide)" then defaults=defaults+1 end end
ok(defaults==1,"default entry survives profile-library reset without duplication")
-- #4/#5: all action buttons retain full native normal/pushed textures at minimum brightness.
a:Set("darkWindows",true);a:Set("darkness",.1)
for _,pageIndex in ipairs({2,4}) do
 for _,child in ipairs(a.optionsPages[pageIndex].children) do
  if child.blkBrightButton then
   ok(child:GetNormalTexture().colour[1]==1,"bright native button: "..child:GetText())
   child.pushedTexture=CreateFrame("Texture",nil,child);a:ThemeOptions()
   ok(child.pushedTexture.colour[1]==1,"pushed button texture stays bright: "..child:GetText())
  end
 end
end
-- #5: real popup click contract, cancellation, one-shot acceptance, persistence and error dismissal.
a.db.positions.PlayerFrame={x=900,y=500};a:CommitSettings();a:Apply()
button(a.optionsPages[2],"Reset frames"):GetScript("OnClick")()
local dialog=LAST_DIALOG;ClickTestPopup(dialog,2)
ok(not dialog:IsShown() and a.db.positions.PlayerFrame.x==900,"Cancel dismisses without resetting")
button(a.optionsPages[2],"Reset frames"):GetScript("OnClick")()
dialog=LAST_DIALOG
local resets=0;local reset=a.ResetFrames
a.ResetFrames=function(self) resets=resets+1;return reset(self) end
ClickTestPopup(dialog,1);ClickTestPopup(dialog,1)
ok(not dialog:IsShown() and resets==1 and next(a.db.positions)==nil,"Accept resets once and dismisses confirmation")
a:InitSettings();a:Apply();ok(next(a.db.positions)==nil and PlayerFrame.points[1][4]==-19,"accepted reset persists across initialization")
a.ResetFrames=function() error("simulated layout error") end
local failed=StaticPopup_Show("BETTERLKFRAMES_RESET_FRAMES")
local success=pcall(ClickTestPopup,failed,1)
ok(not success and not failed:IsShown(),"layout errors cannot strand a visible confirmation")
a.ResetFrames=reset
-- Escape uses a temporary UISpecialFrames sentinel; the reopened window waits until next update.
a:SelectOptionsPage(2);a.options:Show()
button(a.optionsPages[2],"Unlock frames"):GetScript("OnClick")()
ok(a.unlocked and a.unlockEscape:IsShown() and not a.options:IsShown(),"unlock enables Escape sentinel and hides settings")
CloseTestSpecialWindows()
ok(not a.unlocked and not a.unlockEscape:IsShown(),"Escape exits unlocked mode and hides all movers")
a.scripts.OnUpdate(a,.01)
ok(a.options:IsShown() and a.optionsPages[2]:IsShown(),"Escape reopens settings specifically on Frames page")
CloseTestSpecialWindows();a.scripts.OnUpdate(a,.01)
ok(not a.options:IsShown() and not a.reopenFrames,"normal Escape remains unchanged when already locked")
a:SetUnlocked(true);COMBAT=true;a.scripts.OnEvent(a,"PLAYER_REGEN_DISABLED")
COMBAT=false;a.scripts.OnUpdate(a,.01)
ok(not a.unlocked and not a.options:IsShown(),"combat exit from unlock does not masquerade as Escape")
a:SetUnlocked(true);a:SetUnlocked(false);a.scripts.OnUpdate(a,.01)
ok(not a.options:IsShown(),"explicit locking does not reopen settings")
-- #8: runtime-only opt-in, isolated visuals and live shared rendering.
a:CharacterProfile("account");a:Reset();openAuras()
ok(not a.testAuras and a.db.showTestAuras==nil,"preview starts unchecked and is absent from saved settings")
local checkbox
for i=1,100 do
 local c=_G["BetterLKFramesCheck"..i]
 if c and _G[c:GetName().."Text"]:GetText()=="Show test auras" then checkbox=c end
end
ok(checkbox and not checkbox:GetChecked(),"preview checkbox exists and starts unchecked")
local originalBuff=BUFFS.player;local realExpiry=BuffButton1.blkAura.cooldownExpiry
local realCooldownCalls=BuffButton1.blkAura.cooldown.cooldownCalls
local auraCount=0;for _ in pairs(a.auras) do auraCount=auraCount+1 end
checkbox:SetChecked(true);checkbox:GetScript("OnClick")(checkbox)
ok(a.testAuras and checkbox:GetChecked() and #a.auraPreviews==3,"preview creates labelled groups for player, target and focus")
local group=a.auraPreviews[1];local sample=group.samples[1];local visual=sample.visual
ok(group:IsShown() and group.title:GetText():find("TEST player",1,true) and not sample.mouse,"samples are labelled and have no tooltip/mouse interaction")
ok(not visual.cooldown:IsShown() and visual.time:GetText()=="" and not visual.edge:IsShown(),"samples respect disabled aura defaults")
a:Set("auraSpirals",true)
ok(visual.cooldown:IsShown(),"spiral setting immediately enables sample cooldown")
local calls=visual.cooldown.cooldownCalls
a:UpdateTestAuras();a:UpdateTestAuras()
ok(visual.cooldown.cooldownCalls==calls,"unchanged sample cooldown is not restarted on polling")
a:Set("auraSpirals",false);ok(not visual.cooldown:IsShown(),"spiral setting immediately removes sample cooldown")
a:Set("auraTimers",true);ok(visual.time:GetText()~="","timer setting immediately updates sample")
a:Set("auraWarnings",true);a:Set("warningSeconds",5)
ok(group.samples[2].visual.edge:IsShown(),"expiring sample reflects warning threshold")
a:Set("warningSeconds",0);ok(not group.samples[2].visual.edge:IsShown(),"warning threshold removes sample expiry border")
a:Set("darkAuras",true);ok(visual.skin:IsShown(),"dark aura edges apply to samples")
a:Set("darkAuras",false);ok(not visual.skin:IsShown(),"dark edge toggle clears sample skin")
a.db.importantSpells[21562]=true;a:Apply()
ok(visual.edge:IsShown() and visual.edge.borderColour[2]==.8,"sample reflects selected important-spell gold border")
a:Set("auraOffset",7)
ok(a.auraPreviews[2].samples[1].points[1][5]==-29,"target sample gap responds live")
a:Set("bigBars",false)
ok(a.auraPreviews[2].samples[1].points[1][5]==-22,"sample gap follows native large-bar prerequisite")
a:Set("bigBars",true)
ok(BUFFS.player==originalBuff and BuffButton1.blkAura.cooldownExpiry==realExpiry and
 BuffButton1.blkAura.cooldown.cooldownCalls==realCooldownCalls,"preview leaves real aura data, expiry and cooldown calls untouched")
local after=0;for _ in pairs(a.auras) do after=after+1 end
ok(after==auraCount and a.db.showTestAuras==nil,"sample frames never enter native aura registry or SavedVariables")
a:SetTestAuras(false)
ok(not group:IsShown() and not visual.cooldown:IsShown() and not checkbox:GetChecked(),"unchecking cleans up preview and checkbox")
a:SetTestAuras(true);a:SelectOptionsPage(1)
ok(not a.testAuras and not group:IsShown(),"leaving Casts / auras ends preview")
openAuras();a:SetTestAuras(true);a.options:Hide()
ok(not a.testAuras and not group:IsShown(),"closing settings ends preview")
openAuras();a:SetTestAuras(true);COMBAT=true;a.scripts.OnEvent(a,"PLAYER_REGEN_DISABLED")
ok(not a.testAuras and not group:IsShown() and not checkbox:GetChecked(),"combat clears previews without protected geometry")
ok(not a:SetTestAuras(true),"enabling preview in combat is rejected")
COMBAT=false
openAuras();a:SetTestAuras(true);a:Set("enabled",false)
ok(not a.testAuras and not group:IsShown(),"disabling addon clears preview")
a:Set("enabled",true);openAuras();a:SetTestAuras(true)
a.scripts.OnEvent(a,"PLAYER_LOGOUT");ok(not a.testAuras,"logout clears runtime preview state")
-- #9: circular built-in atlas for each supported class, normal restoration and NPC fallback.
local oldClass=UNITS.player.class;local coords=CLASS_ICON_TCOORDS
CLASS_ICON_TCOORDS={}
for i,class in ipairs({"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","DRUID"}) do
 CLASS_ICON_TCOORDS[class]={((i-1)%4)/4,((i-1)%4+1)/4,math.floor((i-1)/4)/4,(math.floor((i-1)/4)+1)/4}
 UNITS.player.class=class;a:Set("classPortraits",true);a:Refresh()
 ok(PlayerPortrait.texture=="Interface\\TargetingFrame\\UI-Classes-Circles" and
  PlayerPortrait.texCoords[1]==CLASS_ICON_TCOORDS[class][1],"circular class atlas and coordinates selected: "..class)
end
UNITS.player.class=oldClass;CLASS_ICON_TCOORDS=coords
a:Set("frameScale",1.6);a:Refresh()
ok(PlayerPortrait.texture=="Interface\\TargetingFrame\\UI-Classes-Circles","portrait scaling preserves circular texture")
a:Set("classPortraits",false)
ok(PlayerPortrait.texture=="portrait:player" and PlayerPortrait.texCoords[1]==0 and PlayerPortrait.texCoords[2]==1,"normal portrait and full coordinates restored")
a:Set("classPortraits",true);UNITS.player.player=false;a:Refresh()
ok(PlayerPortrait.texture=="portrait:player","NPC transition restores native portrait")
UNITS.player.player=true;a:Refresh();a:Set("enabled",false)
ok(PlayerPortrait.texture=="portrait:player","addon disable restores native portrait")
a:Set("enabled",true)
-- #10: native state can refresh, rest suppression persists, level/vehicle/combat remain native.
RESTING=true;PlayerFrame_UpdateStatus();HOOKS.PlayerFrame_UpdateStatus()
ok(not PlayerRestIcon:IsShown() and not PlayerRestGlow:IsShown() and PlayerLevelText:IsShown(),"resting badge hidden while native level stays visible")
PlayerAttackIcon:Show();a:Theme()
ok(PlayerAttackIcon:IsShown(),"rest suppression leaves attack badge untouched")
a:Set("classPortraits",false);a:Set("classPortraits",true)
ok(not PlayerRestIcon:IsShown() and PlayerLevelText:IsShown(),"rest badge behavior survives portrait-type changes")
VEHICLE=true;PlayerFrame_UpdateStatus();HOOKS.PlayerFrame_UpdateStatus()
ok(not PlayerLevelText:IsShown(),"native vehicle art keeps its own level visibility")
VEHICLE=false;PlayerFrame_UpdateStatus();HOOKS.PlayerFrame_UpdateStatus()
a:Set("enabled",false)
ok(PlayerRestIcon:IsShown() and PlayerRestGlow:IsShown(),"addon disable restores native resting indicators")
a:Set("enabled",true);RESTING=false;PlayerFrame_UpdateStatus();HOOKS.PlayerFrame_UpdateStatus()
ok(not PlayerRestIcon:IsShown() and PlayerLevelText:IsShown(),"leaving rest area retains native level")
print("TOTAL followups "..n.." assertions passed")
