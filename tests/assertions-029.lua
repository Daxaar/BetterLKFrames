-- Continue with the realistic native party/pet fixtures from the prior suite.
local a=BetterLKFrames
local n=0
local function ok(v,label) assert(v,label);n=n+1;print("PASS 0.2.9 "..label) end
local function near(x,y) return math.abs(x-y)<.001 end
BetterLKFramesDB=nil;BetterLKFramesCharDB=nil;a:InitSettings();a:Apply()
local e=a.frames.PartyMemberFrame1
-- #27: inspect both event orders. Native visibility remains under native control.
local pal={hp=800,maxhp=1000,mana=330,maxmana=330,player=true,class="WARRIOR"}
for _,compact in ipairs({false,true}) do
 a:Set("compactParty",compact)
 for _,nativeFirst in ipairs({false,true}) do
  UNITS.party1=nil;PartyMemberFrame1:Hide();a:GetScript("OnEvent")(a,"PARTY_MEMBERS_CHANGED")
  ok(not PartyMemberFrame1:IsShown(),"#27 solo never forces a party member visible")
  UNITS.party1=pal
  local function nativeJoin()
   PartyMemberFrame1:Show();PartyMemberFrame1:SetFrameLevel(2)
   e.originalHealth:SetValue(pal.hp)
  end
  if nativeFirst then nativeJoin() end
  a:GetScript("OnEvent")(a,"PARTY_MEMBERS_CHANGED")
  if not nativeFirst then nativeJoin() end
  a:GetScript("OnUpdate")(a,.11)
  ok(PartyMemberFrame1:IsVisible() and PartyMemberFrame1:GetAlpha()==1 and e.health:IsVisible() and e.health:GetAlpha()==1,
   "#27 join remains visible: compact="..tostring(compact).." native-first="..tostring(nativeFirst))
 end
end
local db=a.db;local points=PartyMemberFrame1:GetNumPoints();local scale=PartyMemberFrame1:GetScale()
a:Command("partydebug")
ok(a.db==db and PartyMemberFrame1:GetNumPoints()==points and PartyMemberFrame1:GetScale()==scale and PartyMemberFrame1:IsVisible(),"#27 diagnostic command is read-only")
ok(DEFAULT_CHAT_FRAME.messages[#DEFAULT_CHAT_FRAME.messages]:find("overlayLevel",1,true),"#27 diagnostics include overlay state/level and profile/viewport evidence")
-- #24 text: distinct header/health/resource rows, not a concatenated name string.
local originalName=UnitName
UnitName=function(u) return u=="party1" and "Pal" or originalName(u) end
UNITS.party1=pal;a:Set("compactParty",true);a:Refresh()
ok(e.compactName:GetText()=="Pal","#24 header contains only the name")
ok(e.health.text:GetText()=="800 / 1000 (80%)" and e.power.text:GetText()=="330 / 330","#24 health/current/max/percent and resource rows are independently readable")
ok(e.health.text:GetStringWidth()<=e.health.text:GetWidth() and e.power.text:GetHeight()==11,"#24 value widths/heights fit their rows")
local leader=CreateFrame("Texture","PartyMemberFrame1LeaderIcon",PartyMemberFrame1);leader:SetTexture("leader");leader:Show()
local role=CreateFrame("Texture","PartyMemberFrame1GuideIcon",PartyMemberFrame1);role:SetTexture("role");role:Hide()
a:Apply();a:Refresh()
local mirror
for _,v in pairs(e.compactIcons) do if v.source==leader then mirror=v.copy end end
local _,relative,_,x,y=mirror:GetPoint(1)
ok(relative==PartyMemberFrame1 and x>=0 and x+mirror:GetWidth()<=PartyMemberFrame1:GetWidth() and y==-1,"#24 leader mirror is inside its own header")
ok(leader:GetAlpha()==0 and mirror:IsShown() and mirror:GetTexture()=="leader","#24 mirror preserves native leader artwork/state without a detached original")
leader:Hide();role:Show();a:Refresh()
ok(not mirror:IsShown(),"#24 native status visibility updates mirror immediately")
-- Changing sizes must preserve text fit, pets, native parents and compact toggle restore.
for _,size in ipairs({{110,40},{128,52},{220,80}}) do
 a:Set("compactWidth",size[1]);a:Set("compactHeight",size[2]);a:Refresh()
 ok(PartyMemberFrame1:GetWidth()==size[1] and PartyMemberFrame1:GetHeight()==size[2],"#24 profile dimensions apply: "..size[1].."x"..size[2])
 local pet=PartyMemberFrame1PetFrame;pet:Show()
 pet:ClearAllPoints();pet:SetPoint("TOPLEFT",PartyMemberFrame1,"TOPLEFT",23,-43)
 local view
 for _,v in ipairs(pet.children) do if v.unit=="partypet1" then view=v end end
 local _,ref,_,_,py=view:GetPoint(1)
 local nextTop=43+pet:GetHeight()+10
 ok(ref==PartyMemberFrame1 and -py>=PartyMemberFrame1:GetHeight()+4 and nextTop>=-py+view:GetHeight()+8,"#24 pet/body/next-member spacing remains clear at "..size[1].."x"..size[2])
 ok(pet:GetParent()==PartyMemberFrame1 and e.health.text:GetStringWidth()<=size[1]-6,"#24 size preserves parent and readable value width")
end
pal.hp=9999999;pal.maxhp=9999999;a:Set("compactWidth",110);a:Refresh()
ok(not e.health.text:GetText():find("%.%.%.") and e.health.text:GetStringWidth()<=104,"#24 large values use short format instead of ellipsis")
a:Set("compactWidth",10);a:Set("compactHeight",999)
ok(a.db.compactWidth==110 and a.db.compactHeight==80,"#24 controls enforce supported dimension bounds")
a:Profile("save","Sized party","character");a:Set("compactWidth",166);a:Set("compactHeight",60);a:InitSettings();a:Apply()
ok(a.db.compactWidth==166 and a.db.compactHeight==60,"#24 dimensions persist in private profile across reinitialization")
-- Only restore anchors that we actually changed: do not undo native pet/owner updates.
PartyMemberFrame1:ClearAllPoints();PartyMemberFrame1:SetPoint("TOPLEFT",UIParent,"TOPLEFT",32,-180)
PartyMemberFrame1PetFrame:ClearAllPoints();PartyMemberFrame1PetFrame:SetPoint("TOPLEFT",PartyMemberFrame1,"TOPLEFT",23,-27)
a:Set("compactParty",false)
local _,_,_,px=PartyMemberFrame1:GetPoint(1);local _,_,_,_,petY=PartyMemberFrame1PetFrame:GetPoint(1)
ok(px==32 and petY==-27,"#24 restore does not revert native owner/pet anchors it never changed")
ok(leader:GetAlpha()==1 and not mirror:IsShown(),"#24 standard mode restores native status art and hides copies")
-- #24 animation: sub-0.1s steps interpolate without extra cast API polling.
UNITS.party1=pal;NOW=100;CASTS.party1={"Smooth","","Smooth","icon",100000,102000,false,1,false}
local nativeText=CastingBarFrame.blkTime:GetText()
a:UpdateCasts();local f=a.castbars[1];local tick=f:GetScript("OnUpdate")
local calls=0;local read=UnitCastingInfo;UnitCastingInfo=function(...) calls=calls+1;return read(...) end
NOW=100.016;tick(f,.016);local first=f:GetValue();NOW=100.032;tick(f,.016)
ok(near(first,.016) and near(f:GetValue(),.032) and calls==0,"#24 standard progress advances at render cadence without recapturing cast data")
ok(CastingBarFrame.blkTime:GetText()==nativeText,"#24 party interpolation does not rewrite native player/target timer text")
a:Set("compactParty",true);NOW=100.048;tick(f,.016)
ok(near(f:GetValue(),.048),"#24 compact party progress uses same smooth clock")
CASTS.party1=nil;CHANNELS.party1={"Channel","","Channel","icon",100000,102000,false,true};a:UpdateCasts()
NOW=100.064;tick(f,.016);ok(near(f:GetValue(),1.936),"#24 channel progress smoothly counts down")
CHANNELS.party1=nil;a:UpdateCasts();ok(not f:IsShown() and not f.blkClock,"#24 interruption clears animation clock")
CASTS.party1={"Short","","Short","icon",100000,101000,false,1,false};a:UpdateCasts();NOW=101;tick(f,.016)
ok(not f:IsShown() and not f.blkClock,"#24 completion stops exactly at cached finish time")
UnitCastingInfo=read;CASTS.party1=nil;NOW=100
-- #23 one timer owner for main auras; unit-frame native duration treatment unchanged.
BUFFS.player={{"Buff","","icon",1,nil,60,130,"player",false,false,123}}
BuffButton1:Show();local main=BuffButton1.blkAura
BuffButton1.duration=BuffButton1.duration or CreateFrame("FontString",nil,BuffButton1)
main.nativeDuration=BuffButton1.duration;main.nativeDuration:SetAlpha(1)
LOADED_ADDONS.OmniCC=nil;a:Set("auraTimers",false);a:UpdateAuras()
ok(main.time:GetText()=="" and main.nativeDuration:GetAlpha()==1,"#23 native duration owns main timer without addon counters or OmniCC")
a:Set("auraTimers",true);a:UpdateAuras()
ok(main.time:GetText()~="" and main.nativeDuration:GetAlpha()==0,"#23 own main counter suppresses native duplicate")
LOADED_ADDONS.OmniCC=true;a:RefreshAuraCounterOwner();a:UpdateAuras()
ok(main.time:GetText()=="" and main.nativeDuration:GetAlpha()==0,"#23 OmniCC ownership hides both competing main timer sources")
local target=a.auras[TargetFrameBuff1]
if target then
 target.nativeDuration=CreateFrame("FontString",nil,TargetFrameBuff1);target.nativeDuration:SetAlpha(1)
 a:UpdateAuras();ok(target.nativeDuration:GetAlpha()==1,"#23 target/focus native duration ownership remains independent")
end
a:Set("darkAuras",true);a:UpdateAuras()
ok(main.mainTrim.allPoints==BuffButton1 and main.mainTrim:GetNumPoints()==0,"#23 main dark trim is flush with icon without padded double frame")
a:Set("enabled",false);a:UpdateAuras()
ok(main.nativeDuration:GetAlpha()==1,"#23 disabling addon restores main native durations")
print("TOTAL 0.2.9 "..n.." assertions passed")
