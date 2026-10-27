local a=BetterLKFrames
local n=0
local function ok(v,name) assert(v,name);n=n+1;print("PASS 0.2.0 "..name) end
local function near(x,y) return math.abs(x-y)<.00001 end
a:Reset()
local e=a.frames.PlayerFrame
ok(e.power.height==11 and e.health.height==22,"power height increased independently of health")
ok(CastingBarFrame.blkTime.points[1][2]==CastingBarFrameText and CastingBarFrame.blkTime.font[2]==12,"cast timer anchored to native label with matching font")
BUFFS.player={{"Test aura","","icon",1,nil,60,160,"player",false,false,123}}
a:UpdateAuras()
local f=BuffButton1.blkAura;local calls=f.cooldown.cooldownCalls
for i=1,20 do NOW=100+i*.25;a:UpdateAuras() end
ok(f.cooldown.cooldownCalls==calls,"unchanged aura never restarts cooldown during repeated polling")
BUFFS.player[1][7]=170;a:UpdateAuras()
ok(f.cooldown.cooldownCalls==calls+1,"refreshed aura updates cooldown exactly once")
a:UpdateAuras();ok(f.cooldown.cooldownCalls==calls+1,"refreshed aura remains stable")
a:Set("auraSpirals",false);a:UpdateAuras();ok(not f.cooldown.shown,"spiral toggle hides added cooldown")
a:Set("auraSpirals",true);a:UpdateAuras();ok(f.cooldown.shown and f.cooldown.cooldownCalls==calls+2,"re-enabled spiral initialized once")
BUFFS.player={};a:UpdateAuras();ok(not f.shown and not f.cooldown.shown,"removed aura clears custom visuals")
ok(a.options.backdrop.edgeFile=="Interface\\DialogFrame\\UI-DialogBox-Border","settings uses legacy decorative dialog border")
ok(a.options.borderColour[1]==a.db.darkness,"settings border follows darkness")
ok(a.optionsSliders[1].borderColour[1]==a.db.darkness,"settings slider rim follows darkness without tinting thumb")
local account=a.accountDB
local accountScale=account.frameScale
account.profiles.keep={enabled=true,frameScale=1}
a:CharacterProfile("blizzard")
ok(a.db~=account and not a.db.enabled and BetterLKFramesCharDB.useCharacter,"character Blizzard preset uses isolated settings")
ok(account.enabled and account.frameScale==accountScale and account.profiles.keep,"character preset leaves account settings and named profiles intact")
a:Set("frameScale",1.3);ok(account.frameScale==accountScale and BetterLKFramesDB==account,"character changes never overwrite account saved variable")
a:CharacterProfile("account");ok(a.db==account and a.db.enabled,"return to shared account settings")
a:CharacterProfile("resume");ok(a.db.frameScale==1.3 and not a.db.enabled,"resume keeps character settings")
a:CharacterProfile("defaults");ok(a.db.enabled and a.db.frameScale==1 and a.db.positions.PlayerFrame==nil,"character defaults are fresh addon settings")
a:Reset();ok(account.profiles.keep and a.db.profiles.keep,"character reset preserves shared profiles")
a:Profile("save","CharTest");ok(account.profiles.CharTest,"named profiles remain shared from character scope")
-- Simulate login/reload and a second character using distinct per-character storage.
local localSave=BetterLKFramesCharDB
a:Set("healthHeight",26);a:InitSettings();ok(a.db.healthHeight==26 and a.accountDB==account,"character settings survive initialization")
BetterLKFramesCharDB={};a:InitSettings();ok(a.db==account and a.db.healthHeight==22,"another character retains shared settings")
BetterLKFramesCharDB=localSave;a:InitSettings();ok(a.db.healthHeight==26,"returning character retains its independent layout")
COMBAT=true;ok(not a:CharacterProfile("account") and BetterLKFramesCharDB.useCharacter,"profile scope switch blocked in combat")
COMBAT=false;a:CharacterProfile("account")
a:Set("showGrid",true);a:Set("showGuides",true);a:Set("gridSize",32);a:SetUnlocked(true)
ok(a.guides.shown and #a.guides.grid>50 and #a.guides.gridLabels>0,"visible centred grid and distance labels when unlocked")
a:Set("showGrid",false);a:Set("showGuides",false);ok(not a.guides.shown,"disabling grid and guides hides an active overlay")
a:Set("showGrid",true);a:Set("showGuides",true)
local creations=CREATIONS;a:ShowMoveGuides(true);ok(CREATIONS==creations,"grid textures reused between drags")
local labelFour=false;for _,t in ipairs(a.guides.gridLabels) do if t.text=="4" then labelFour=true end end
ok(labelFour,"major grid labels count four squares from centre")
a:SetUnlocked(false);ok(not a.guides.shown,"locking hides complete grid")
a:Set("auraOffset",4);a:RefreshAuraOffset()
ok(TargetFrameDebuff1.points[1][5]==-2,"target first debuff shifted down four pixels")
a:RefreshAuraOffset();a:RefreshAuraOffset();ok(TargetFrameDebuff1.points[1][5]==-2,"aura gap never accumulates")
a:Set("auraOffset",0);ok(TargetFrameDebuff1.points[1][5]==2,"zero gap restores original debuff anchor")
a:Set("auraOffset",4)
COMBAT=true;HOOKS.TargetFrame_UpdateAuras(TargetFrame);ok(a.auraLayoutPending,"aura reanchor deferred in combat")
COMBAT=false;a.scripts.OnEvent(a,"PLAYER_REGEN_ENABLED");ok(not a.auraLayoutPending,"aura reanchor resumes after combat")
ok(a.WindowEdges("Interface\\Icons\\INV_Misc_Book_01")==nil and a.WindowEdges("Interface\\WorldMap\\Elwynn\\Elwynn1")==nil,"window whitelist excludes icons and map tiles")
ok(a.WindowEdges("Interface\\QuestFrame\\UI-QuestLogDualPane-Left")=="LTB","quest log decorative texture recognized")
local before=#QuestLogFrame.regions;a:ThemeWindows();a:ThemeWindows();local after=#QuestLogFrame.regions
a:ThemeWindows();ok(#QuestLogFrame.regions==after,"window overlays never recursively skin their own copies")
ok(TestQuestIcon.colour==nil and WorldMapDetailTile1.colour==nil and TestQuestBorder.colour==nil,"original window art, icons and map contents untouched")
local overlays=0;for _,t in ipairs(QuestLogFrame.regions) do if t~=TestQuestIcon and t~=TestQuestBorder and t:IsShown() then overlays=overlays+1;ok(t.width<=16 or t.height<=12,"window copies restricted to narrow decorative rims") end end
ok(overlays==3,"quest log receives three rim copies")
a:Set("darkWindows",false)
local visible=0;for _,t in ipairs(QuestLogFrame.regions) do if t~=TestQuestIcon and t~=TestQuestBorder and t:IsShown() then visible=visible+1 end end
ok(visible==0 and a.options.borderColour[1]==1,"window toggle restores untouched original art and settings border")
print("TOTAL 0.2.0 "..n.." assertions passed")
