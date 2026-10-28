local a=BetterLKFrames
local n=0
local function ok(v,name) assert(v,name);n=n+1;print("PASS round "..name) end
local function checkbox(title)
 for i=1,100 do
  local c=_G["BetterLKFramesCheck"..i]
  if c and _G[c:GetName().."Text"]:GetText()==title then return c end
 end
 error("Missing checkbox: "..title)
end
local function action(page,title)
 for _,c in ipairs(page.children or {}) do if c:GetText()==title then return c:GetScript("OnClick") end end
 error("Missing action: "..title)
end
local function openAuras() a:SelectOptionsPage(3);a.options:Show() end
local function login(db,char)
 BetterLKFramesDB=db;BetterLKFramesCharDB=char;a:InitSettings();a:Apply()
 if not a.options then a:BuildOptions() end
end
login(nil,nil);a:RefreshOptions()
ok(not a.db.auraTimers and not checkbox("Aura time remaining"):GetChecked(),"#1 fresh Aura time remaining is unchecked")
for _,key in ipairs({"auraTimers","auraSpirals","auraWarnings","darkAuras"}) do ok(a.defaults[key]==false,"#1 fresh default remains disabled: "..key) end
ok(a.db.auraOffset==0 and not a.db.hideResting,"fresh aura gap is zero and new rest toggle is unchecked")
a:Set("auraTimers",true);a:InitSettings();a:Apply();a:RefreshOptions()
ok(a.db.auraTimers and checkbox("Aura time remaining"):GetChecked(),"#1 explicit saved timer preference survives upgrade/reinitialization")
a:CharacterProfile("defaults");ok(not a.db.auraTimers,"#1 fresh character defaults also leave timers unchecked")
a:CharacterProfile("account");ok(a.db.auraTimers,"#1 character preset does not overwrite saved account choice")
-- #4: successful creation clears only the text input; failed creation preserves it.
a:SelectOptionsPage(4);a.options:Show();a:Set("healthHeight",26)
a.profileNameEdit:SetText("Account round");action(a.optionsPages[4],"Create")()
ok(a.profileNameEdit:GetText()=="" and BetterLKFramesCharDB.activeProfile.name=="Account round" and a.db.healthHeight==26,"#4 successful account creation clears field and preserves active configuration")
a.options:Hide();a.options:Show();ok(a.profileNameEdit:GetText()=="","#4 cleared input remains clear after reopening")
a:CharacterProfile("account");a.profileNameEdit:SetText("Account round");action(a.optionsPages[4],"Create")()
ok(a.profileNameEdit:GetText()=="Account round" and not BetterLKFramesCharDB.activeProfile,"#4 duplicate creation preserves input and selection")
a.profileNameEdit:SetText("   ");action(a.optionsPages[4],"Create")()
ok(a.profileNameEdit:GetText()=="   ","#4 invalid name remains available for correction")
OpenTestMenu(a.profileScopeMenu)[2].func();a.profileNameEdit:SetText("Private round");action(a.optionsPages[4],"Create")()
ok(a.profileNameEdit:GetText()=="" and BetterLKFramesCharDB.activeProfile.scope=="character","#4 successful private creation clears input")
-- #10: opt-in rest suppression, immediate native restoration and profile persistence.
RESTING=true;PlayerFrame_UpdateStatus();a:Theme()
ok(PlayerRestIcon:IsShown() and not checkbox("Hide resting Zzz indicator"):GetChecked(),"#10 unchecked setting preserves native resting badge")
checkbox("Hide resting Zzz indicator"):SetChecked(true);checkbox("Hide resting Zzz indicator"):GetScript("OnClick")(checkbox("Hide resting Zzz indicator"))
ok(not PlayerRestIcon:IsShown() and PlayerLevelText:IsShown(),"#10 checked setting immediately reveals player level")
a:InitSettings();a:Apply();ok(a.db.hideResting and not PlayerRestIcon:IsShown(),"#10 rest preference survives selected-profile reload")
a:CharacterProfile("account");ok(not a.db.hideResting and PlayerRestIcon:IsShown(),"#10 switching to unchecked profile restores native rest behavior")
a:Profile("load","Private round","character");ok(a.db.hideResting and not PlayerRestIcon:IsShown(),"#10 private opt-in retained independently")
a:Set("hideResting",false);ok(PlayerRestIcon:IsShown() and RESTING,"#10 immediate off switch restores badge without changing rest state")
-- Shared real/sample timer anchors, single fallback and lifecycle safety.
a:Set("auraTimers",true);a:Set("auraSpirals",true);a:Set("auraWarnings",true)
BUFFS.player={{"Real buff","","icon",1,nil,60,NOW+45,"player",false,false,21562}}
a:UpdateAuras();openAuras();a:SetTestAuras(true)
local fallback=a.auraPreviewFallback
ok(fallback:IsShown() and #fallback.samples==3,"#8 one player fallback provides appearance samples without safe native geometry")
ok(not a.auraPreviews[2]:IsShown() and not a.auraPreviews[3]:IsShown(),"#8 no detached target/focus boxes")
local timer=fallback.samples[1].visual.time
ok(timer.points[1][1]=="BOTTOM" and timer.points[1][3]=="BOTTOM" and timer.points[1][5]==1,"#8 fallback counter lies inside icon")
ok(BuffButton1.blkAura.time.points[1][1]=="BOTTOM" and BuffButton1.blkAura.time.points[1][5]==1,"#8 real player counter uses the same inside anchor")
local aura=fallback.samples[1].visual
local calls=aura.cooldown.cooldownCalls;local hides=0;local oldHide=aura.cooldown.Hide
aura.cooldown.Hide=function(self) hides=hides+1;return oldHide(self) end
a:UpdateTestAuras();a:UpdateTestAuras()
ok(aura.cooldown.cooldownCalls==calls and hides==0,"#8 preview polling neither restarts nor hides unchanged cooldowns")
aura.cooldown.Hide=oldHide
-- Mirror precomputed vacant player slots; no native icon or anchor is repurposed.
BuffButton2=CreateFrame("Frame","BuffButton2",UIParent);BuffButton2:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-10,-10)
BuffButton2:SetWidth(32);BuffButton2:SetHeight(32);BuffButton2.left=800;BuffButton2.bottom=800;BuffButton2:SetScale(.8);BuffButton2:Hide()
for i=1,2 do
 local b=CreateFrame("Frame","DebuffButton"..i,UIParent);b:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-50*i,-50)
 b:SetWidth(32);b:SetHeight(32);b.left=800-50*i;b.bottom=700;b:Hide()
end
local occupiedWidth=BuffButton1:GetWidth();local slotPoints=BuffButton2:GetNumPoints()
-- Supply read-only result geometry in the mock; production gets this from the native engine.
local pg=a.auraPreviews[1]
for _,kind in ipairs({"Buff","Debuff"}) do
 for _,b in pairs(pg.slots[kind]) do b.left=800;b.bottom=700 end
end
a:UpdateTestAuras()
-- The first update may allocate previously unused mirror slots; set their result coordinates.
for _,kind in ipairs({"Buff","Debuff"}) do for _,b in pairs(pg.slots[kind]) do b.left=800;b.bottom=700 end end
a:UpdateTestAuras()
ok(pg:IsShown() and pg.mode=="native" and #pg.samples==3 and not fallback:IsShown(),"#8 vacant player slots use actual native positions with no fallback")
ok(pg.samples[1].nativeSlot==BuffButton2 and pg.samples[1]:GetScale()==.8 and pg.samples[1]:GetWidth()==32,"#8 player mirrors native slot dimensions and scale")
ok(pg.samples[1].points[1][2]==UIParent and not pg.samples[1].allPoints,"#8 mirror does not anchor into protected native family")
ok(not BuffButton2:IsShown() and BuffButton2:GetNumPoints()==slotPoints and BuffButton1:GetWidth()==occupiedWidth,"#8 native icons, visibility and anchors untouched")
-- Contract test: native routines must receive only scratch frames with our private prefix.
local nativeCalls={};local oldPositions,oldBuff,oldDebuff=TargetFrame_UpdateAuraPositions,TargetFrame_UpdateBuffAnchor,TargetFrame_UpdateDebuffAnchor
TargetFrame_UpdateBuffAnchor=function() end;TargetFrame_UpdateDebuffAnchor=function() end
TargetFrame_UpdateAuraPositions=function(proxy,prefix,count,opposite,large,anchor,width,spacing)
 assert(proxy~=TargetFrame and proxy~=FocusFrame and prefix:find('^BetterLKFramesPreview'))
 nativeCalls[#nativeCalls+1]={proxy=proxy,prefix=prefix,count=count,opposite=opposite,width=width,spacing=spacing,anchor=anchor}
 for i=1,count do
  local b=_G[prefix..i];assert(b and b:GetParent()==proxy)
  b:SetWidth(large[i] and 21 or 17);b:SetHeight(large[i] and 21 or 17)
  b:SetPoint("TOPLEFT",proxy,"BOTTOMLEFT",5+(i-1)*(21+spacing),32)
  b.left=400+(i-1)*30;b.bottom=40
 end
 proxy.auraRows=proxy.auraRows+1
end
BUFFS.target={};DEBUFFS.target={};a:Set("auraOffset",7);a:UpdateTestAuras()
local target=a.auraPreviews[2]
ok(target:IsShown() and #target.samples==3 and #nativeCalls>=2,"#8 target samples use native aura routines on scratch frames")
ok(target.samples[1].points[1][5]==25 and target.samples[1].visual.time.points[1][5]==1,"#8 native target root gap and inside countdown are applied")
ok(target.points[1][2]==UIParent and target:GetScale()==TargetFrame:GetEffectiveScale()/UIParent:GetEffectiveScale(),"#8 proxy copies target scale in UIParent space")
ok(nativeCalls[1].spacing==3 and nativeCalls[2].spacing==4 and nativeCalls[1].width==122,"#8 buff/debuff layout uses native row-width/spacing contract")
a:Set("bigBars",false);ok(target.samples[1].points[1][5]==32,"#8 target gap honours large-bar prerequisite")
a:Set("bigBars",true)
-- A real aura occupying a sample rectangle must win; samples disappear without native writes.
BUFFS.target={{"Real target buff","","icon",1,nil,60,NOW+40,"target",false,false,1}}
TargetFrameBuff1.left=400;TargetFrameBuff1.bottom=40;TargetFrameBuff1:SetWidth(21);TargetFrameBuff1:SetHeight(21);TargetFrameBuff1:Show()
a:UpdateTestAuras()
local colliding=false
for _,b in ipairs(target.samples) do if b.left==400 then colliding=true;ok(not b:IsShown(),"#8 sample never covers an occupied real icon") end end
ok(colliding,"#8 collision fixture exercised")
TargetFrame_UpdateAuraPositions,TargetFrame_UpdateBuffAnchor,TargetFrame_UpdateDebuffAnchor=oldPositions,oldBuff,oldDebuff
-- #13: no global/table heuristic; detect loaded OmniCC only, including late load.
OmniCC={};LOADED_ADDONS.OmniCC=nil;a:RefreshAuraCounterOwner();a:UpdateAuras()
ok(not a:HasOmniCC() and not a.omniCCWarning:IsShown(),"#13 installed/global OmniCC without loaded addon does not trigger override")
CASTS.player={"Cast","","Cast","icon",99000,110000,false,1,false};a:UpdateCasts()
local castText=CastingBarFrame.blkTime:GetText();local realCalls=BuffButton1.blkAura.cooldown.cooldownCalls
BuffButton1:Hide()
LOADED_ADDONS.OmniCC=true;a.scripts.OnEvent(a,"ADDON_LOADED","OmniCC")
ok(BuffButton1.blkAura.time:GetText()=="","#13 late load clears counters on hidden existing aura overlays too")
BuffButton1:Show();a:UpdateAuras()
ok(a:HasOmniCC() and a.db.auraTimers and a.auraTimerCheck:GetChecked(),"#13 late loaded OmniCC preserves checked saved preference")
ok(BuffButton1.blkAura.time:GetText()=="" and BuffButton1.duration:GetAlpha()==1,"#13 existing real aura text suppressed, native duration restored")
local active=pg:IsShown() and pg or fallback
ok(active.samples[1].visual.time:GetText()=="","#13 existing preview counter suppressed immediately")
ok(a.omniCCWarning:IsShown() and a.omniCCWarning.points[1][2]==300 and a.omniCCWarning.points[1][3]<-80,"#13 warning is below Show test auras checkbox")
ok(_G[a.auraTimerCheck:GetName().."Text"]:GetText():find("saved preference",1,true),"#13 checkbox explicitly describes saved rather than effective state")
a:UpdateCasts();ok(CastingBarFrame.blkTime:GetText()==castText and castText~="","#13 cast countdown remains unaffected")
ok(BuffButton1.blkAura.cooldown:IsShown() and BuffButton1.blkAura.cooldown.cooldownCalls==realCalls,"#13 spiral visuals and existing cooldown timing preserved")
a:InitSettings();a:Apply();ok(a.db.auraTimers and BuffButton1.blkAura.time:GetText()=="","#13 preference persists while suppression survives reload initialization")
a:Set("auraTimers",false);LOADED_ADDONS.OmniCC=nil;a:RefreshAuraCounterOwner();a:RefreshOptions()
ok(not a.db.auraTimers and not a.omniCCWarning:IsShown() and BuffButton1.blkAura.time:GetText()=="","#13 absent OmniCC does not enable a saved-off timer preference")
a:Set("auraTimers",true);a:UpdateAuras();a:UpdateTestAuras()
ok(BuffButton1.blkAura.time:GetText()~="" and not a.omniCCWarning:IsShown(),"#13 own counters return when OmniCC absent and saved preference enabled")
-- Preview state is transient and all exit paths still clear it without protected geometry.
COMBAT=true;a.scripts.OnEvent(a,"PLAYER_REGEN_DISABLED")
ok(not a.testAuras and not pg:IsShown() and not target:IsShown() and not fallback:IsShown(),"#8 combat clears every preview without touching native anchors")
COMBAT=false;openAuras();a:SetTestAuras(true);a:SelectOptionsPage(4)
ok(not a.testAuras and not a.auraPreviewStatus:IsShown(),"#8 leaving page clears samples and status explanation")
OmniCC=nil
print("TOTAL round "..n.." assertions passed")
