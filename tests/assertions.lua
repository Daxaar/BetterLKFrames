local a=BetterLKFrames
local tests=0
local function ok(v,name) assert(v,name);tests=tests+1;print("PASS "..name) end
local function near(a,b) return math.abs(a-b)<.00001 end
local function event(e,arg) a.scripts.OnEvent(a,e,arg) end
BetterLKFramesDB={healthHeight=999,darkness=0,frameScale="bad"}
event("ADDON_LOADED","BetterLKFrames")
ok(a.db.healthHeight==30 and a.db.darkness==.1 and a.db.frameScale==1,"malformed saved settings normalized")
a:Reset();event("PLAYER_LOGIN")
ok(a.frames.PlayerFrame and a.frames.TargetFrame and not a.frames.FocusFrame,"missing optional frames tolerated")
local e=a.frames.PlayerFrame
ok(e.health.height==22 and e.power.height==11 and e.originalHealth.alpha==0,"thick health and power overlays")
ok(near(e.health.barColour[1],.41) and near(e.health.barColour[2],.8),"player class health colour")
ok(near(a.frames.TargetFrame.health.barColour[1],.78),"target class health colour")
ok(PlayerFrameTexture.colour[1]==.28 and PlayerPortrait.colour==nil,"decoration darkened without tinting portrait")
ok(PlayerFrameTextureFrameHealthBarText.alpha==0,"duplicate native health text hidden")
ok(a.frames.PartyMemberFrame1.health.height==12,"secondary bars retain native height")
ok(a.frames.PartyMemberFrame1.health.text.text=="80%","secondary health text fits narrow bars")
a:Set("bigBars",false);ok(e.health.height==12 and e.power.height==12,"normal bar geometry option")
a:Set("bigBars",true)
a:Set("classPortraits",true);ok(PlayerPortrait.texture:find("UI%-Classes%-Circles")~=nil,"class portrait option")
a:Set("classPortraits",false);ok(PlayerPortrait.texture=="portrait:player","portrait restored")
COMBAT=true;a:Set("healthHeight",27);ok(a.pending and e.health.height==22,"combat layout change deferred")
event("UNIT_RAGE");a.scripts.OnUpdate(a,.3)
COMBAT=false;event("PLAYER_REGEN_ENABLED");ok(not a.pending and e.health.height==27,"layout applied after combat")
ok(a.events.UNIT_ENERGY and a.events.UNIT_RUNIC_POWER,"Wrath power events registered")
UNITS.player.hp=0;UNITS.player.maxhp=0;a:Refresh();ok(e.health.max==1,"zero maximum health safe")
UNITS.player.hp=800;UNITS.player.maxhp=1000
PlayerFrame.manabar:Hide();a:Refresh();ok(not e.power.shown,"hidden native power bar respected");PlayerFrame.manabar:Show()
UNITS.player.mana=123;PlayerFrame.manabar:SetValue(123);ok(e.power.value==123,"native power updates refresh overlay")
CASTS.player={"Fireball","","Fireball","icon",99000,102000,false,1,false}
CASTS.party1={"Fireball","","Fireball","icon",99000,102000,false,1,true}
a:UpdateCasts();ok(CastingBarFrame.blkTime.text=="2.0","native cast timer milliseconds converted")
ok(a.castbars[1].shown and a.castbars[1].barColour[1]==.5,"party noninterruptible cast grey")
CASTS.party1=nil;CHANNELS.party1={"Channel","","Channel","icon",98000,103000,false,true}
a:UpdateCasts();ok(a.castbars[1].value==3 and a.castbars[1].barColour[1]==.5,"legacy channel eighth return and countdown")
CHANNELS.party1=nil;a:UpdateCasts();ok(not a.castbars[1].shown,"idle party cast bar hidden")
BUFFS.player={{"Test aura","","icon",1,nil,10,104,"player",false,false,123}}
BUFFS.target={{"Permanent","","icon",1,nil,0,0,"target",false,false,7}}
a:Set("auraTimers",true);a:Set("auraSpirals",true);a:Set("auraWarnings",true)
a:UpdateAuras();ok(BuffButton1.blkAura.time.text=="4" and BuffButton1.blkAura.edge.shown,"aura timer and expiry warning")
ok(BuffButton1.duration.alpha==0,"duplicate native player aura timer hidden")
ok(BuffButton1.blkAura.cooldown.cooldown[1]==94,"missing aura spiral added")
ok(TargetFrameBuff1.blkAura.cooldown==nil,"existing native aura spiral preserved")
ok(TargetFrameBuff1.blkAura.time.text=="","permanent aura has no countdown")
a:Command("aura 123");a:UpdateAuras();ok(BuffButton1.blkAura.edge.borderColour[2]==.8,"important aura gold border")
BUFFS.player={};a:UpdateAuras();ok(not BuffButton1.blkAura.shown and not BuffButton1.blkAura.cooldown.shown,"removed aura overlay and cooldown hidden")
a:Profile("save","Test");a:Set("healthHeight",20);a:Profile("load","Test");ok(a.db.healthHeight==20,"active named profile edits persist when reselected")
a.db.positions.PlayerFrame={x=350,y=220};a:Apply();ok(e.positionApplied and e.owner.points[1][1]=="BOTTOMLEFT","saved frame position applied")
a:Set("frameScale",1.25);ok(near(e.owner.points[1][4],280),"saved UIParent coordinates account for frame scaling")
a:Set("frameScale",1)
a:SetUnlocked(true);ok(e.mover.shown,"frame movement handle created")
COMBAT=true;e.mover.scripts.OnDragStop(e.mover);event("PLAYER_REGEN_DISABLED");ok(e.stopPending and not e.mover.shown,"combat interrupts mover without protected geometry")
COMBAT=false;event("PLAYER_REGEN_ENABLED");ok(not e.stopPending,"deferred move stop after combat")
a:Set("castScale",1.5);ok(near(CastingBarFrame.scale,1.2),"cast scale relative to native baseline")
a:Set("enabled",false);a:UpdateAuras();a:UpdateCasts()
ok(e.originalHealth.alpha==1 and not e.health.shown and PlayerFrameTextureFrameHealthBarText.alpha==1,"disable restores native bars and labels")
ok(PlayerFrameTexture.colour[1]==1 and near(CastingBarFrame.scale,.8),"disable restores decoration and cast scale")
ok(e.owner.points[1][1]=="TOPLEFT" and BuffButton1.duration.alpha==1,"disable restores original anchors and aura duration")
a:OpenOptions();ok(a.options.shown and OPTIONS_CATEGORY.name=="BetterLKFrames","legacy settings panel and Interface category")
a:OpenOptions();ok(not a.options.shown,"settings panel toggles")
a:Set("enabled",true);a:Set("hidePvp",true);ok(PlayerPVPIcon.alpha==0,"player PvP icon option uses Wrath texture name")
a:Set("hidePvp",false);ok(PlayerPVPIcon.alpha==1,"player PvP icon restored")
a:CharacterProfile("account");a:Reset();ok(a.db.healthHeight==22 and next(a.db.profiles)==nil,"reset restores defaults and clears profiles")
print("TOTAL "..tests.." assertions passed")
