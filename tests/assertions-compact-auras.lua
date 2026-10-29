local a=BetterLKFrames
local total=0
local function ok(v,label) assert(v,label);total=total+1;print("PASS new issues "..label) end
local function near(a,b) return math.abs(a-b)<.001 end
BetterLKFramesDB=nil;BetterLKFramesCharDB=nil;a:InitSettings();a:Apply();a:BuildOptions()
-- Reproduce the original template's automatic OnShow resizing with actual cap
-- dimensions. Our callback replaces it and uses unconstrained label measurement.
for _,tab in ipairs(a.optionsNavigation) do
 _G[tab:GetName().."Left"]:SetWidth(20)
 tab:GetScript("OnShow")(tab)
 ok(tab:GetWidth()==tab:GetTextWidth()+48,"#16 explicit label fit uses native twenty-pixel caps")
end
for i=1,4 do
 a:SelectOptionsPage(i)
 for j,tab in ipairs(a.optionsNavigation) do
  local p,r,rp,x,y=tab:GetPoint(1)
  if j>1 then ok(p=="TOPLEFT" and r==a.optionsNavigation[j-1] and rp=="TOPRIGHT" and x==2 and y==0,"#16 equal edge spacing after selecting "..i.." tab "..j) end
 end
end
a:ShowStandaloneOptions();OpenTestCategory();a:ShowStandaloneOptions()
ok(a.options.selectedTab==4,"#16 selection survives embedded/standalone transitions")
-- Independent target class switch preserves legacy profile appearance on adoption.
ok(a.Normalize({classHealth=false}).targetClassHealth==false and a.Normalize({classHealth=true}).targetClassHealth==true,"#22 migration inherits prior class-colour preference")
local playerColour=a.frames.PlayerFrame.health.barColour[1]
a:Set("targetClassHealth",false)
ok(near(a.frames.TargetFrame.health.barColour[1],.15) and near(a.frames.PlayerFrame.health.barColour[1],playerColour),"#22 target-only off restores non-class path and leaves player alone")
a:Set("classHealth",false);a:Set("targetClassHealth",true)
ok(near(a.frames.TargetFrame.health.barColour[1],.78) and near(a.frames.PlayerFrame.health.barColour[1],.15),"#22 target-only class colour independent of other units")
local target=UNITS.target;UNITS.target={hp=10,maxhp=100,mana=0,maxmana=1,class="MAGE",player=false}
a:Refresh();ok(near(a.frames.TargetFrame.health.barColour[1],.1),"#22 NPC uses reaction colour, not guessed class")
UNITS.target={hp=10,maxhp=100,mana=0,maxmana=1,class="UNKNOWN",player=true};a:Refresh()
ok(near(a.frames.TargetFrame.health.barColour[1],.15),"#22 unknown player class falls back safely")
UNITS.target=target;target.class="MAGE";a:Refresh()
ok(near(a.frames.TargetFrame.health.barColour[1],.41),"#22 rapid target class change repaints")
target.dead=true;a:Refresh();ok(a.frames.TargetFrame.health.text:GetText()==DEAD,"#22 dead target keeps existing health text")
target.dead=nil;a:Set("targetClassHealth",false);a:Set("healthGradient",true);a:Refresh()
ok(near(a.frames.TargetFrame.health.barColour[1],.5),"#22 off respects health-gradient preference")
a:Set("healthGradient",false);a:Profile("save","Target choice","account");a:Set("targetClassHealth",true);a:InitSettings();a:Apply()
ok(a.db.targetClassHealth,"#22 independent target choice persists in selected profile")
-- Main player aura counters remain intact when the legacy cooldown model is invisible.
BUFFS.player={{"Buff","","icon",2,nil,60,NOW+30,"player",false,false,123}}
DEBUFFS.player={{"Debuff","","icon2",1,"Magic",20,NOW+10,"player",false,false,456}}
DebuffButton1=CreateFrame("Button","DebuffButton1",UIParent);DebuffButton1:SetID(1)
local native=CreateFrame("Cooldown","DebuffButton1Cooldown",DebuffButton1);native:SetAlpha(.7)
local icon=CreateFrame("Texture","DebuffButton1Icon",DebuffButton1);icon:SetTexture("icon2")
local border=CreateFrame("Texture","DebuffButton1Border",DebuffButton1);border:SetVertexColor(0,.5,1,1)
a:Set("auraTimers",true);a:Set("auraSpirals",true);a:Set("darkAuras",true);a:UpdateAuras()
local buff=BuffButton1.blkAura;local debuff=DebuffButton1.blkAura
ok(buff.cooldown:GetAlpha()==0 and buff.cooldown:IsShown() and native:GetAlpha()==0,"#23 player added/native cooldown models become invisible without clearing timers")
ok(buff.time:GetText()=="30" and debuff.time:GetText()=="10","#23 sibling countdown text remains visible")
ok(TargetFrameBuff1Cooldown:GetAlpha()==1,"#23 target native cooldown untouched")
local untouched=TargetFrameBuff1:GetPoint(1)
ok(buff.mainTrim:IsShown() and debuff.mainTrim:IsShown() and icon.colour==nil,"#23 both main aura types get outer trim without icon tint")
ok(border.colour[2]==.5 and border.colour[3]==1,"#23 native debuff-type colour remains intact")
local counter=CreateFrame("Frame",nil,buff.cooldown:GetParent());local numbers=counter:CreateFontString(nil,"OVERLAY");numbers:SetText("30")
ok(counter:IsVisible() and numbers:GetAlpha()==1,"#23 OmniCC-style sibling display remains visible when cooldown alpha is zero")
local calls=buff.cooldown.cooldownCalls
for i=1,3 do a:UpdateAuras() end
ok(buff.cooldown.cooldownCalls==calls,"#23 hidden model retains stable cooldown data for timer consumers")
native:SetAlpha(.4);ok(native:GetAlpha()==0,"#23 external cooldown opacity refresh cannot bring spiral back")
a:Set("hidePlayerAuraSpirals",false);a:UpdateAuras()
ok(native:GetAlpha()==.4 and buff.cooldown:GetAlpha()==1,"#23 opt-out restores native/latest requested opacity")
a:Set("hidePlayerAuraSpirals",true);LOADED_ADDONS.OmniCC=true;a:RefreshAuraCounterOwner();a:UpdateAuras()
ok(buff.time:GetText()=="" and buff.cooldown:GetAlpha()==0 and buff.cooldown.cooldown[2]==60,"#23 OmniCC override preserves cooldown timing while hiding spiral")
a:Set("darkAuras",false);a:UpdateAuras();ok(not buff.mainTrim:IsShown() and not debuff.mainTrim:IsShown(),"#23 dark-theme off removes trim")
a:Set("enabled",false);a:UpdateAuras();ok(native:GetAlpha()==.4,"#23 disable restores native opacity")
a:Set("enabled",true);LOADED_ADDONS.OmniCC=nil;a:RefreshAuraCounterOwner()
-- Native party fixtures: secure scripts/attributes/visibility stay owned by Blizzard.
local raid=CreateFrame("Frame","RaidFrame",UIParent)
for _,m in ipairs({"SetPoint","ClearAllPoints","SetScale","SetWidth","SetHeight","SetAlpha","SetParent","SetScript","Show","Hide"}) do raid[m]=function() error("Raid mutation: "..m) end end
local raidButton=CreateFrame("Button","RaidPullout1",UIParent);raidButton.SetScale=function() error("Raid button touched") end
RAID_SIZE=0;PARTY_SIZE=4
function GetNumRaidMembers() return RAID_SIZE end
function GetNumPartyMembers() return PARTY_SIZE end
function UnitIsConnected(u) return not (UNITS[u] and UNITS[u].offline) end
local secureClick=function() end
for i=1,4 do
 local name="PartyMemberFrame"..i;local owner=_G[name] or CreateFrame("Button",name,UIParent)
 owner.unit="party"..i;owner.protected=true;owner:SetWidth(128);owner:SetHeight(53);owner:SetHitRectInsets(7,85,6,7)
 owner:SetScript("OnClick",secureClick);owner.attributes={unit=owner.unit,type1="target",type2="menu"}
 owner.healthbar=owner.healthbar or CreateFrame("StatusBar",name.."HealthBar",owner)
 owner.manabar=owner.manabar or CreateFrame("StatusBar",name.."ManaBar",owner)
 owner.portrait=_G[name.."Portrait"] or CreateFrame("Texture",name.."Portrait",owner)
 owner.name=_G[name.."Name"] or CreateFrame("FontString",name.."Name",owner)
 local art=CreateFrame("Frame",nil,owner);local art2=CreateFrame("Frame",nil,art)
 CreateFrame("Texture",name.."Texture",art2)
 for j=1,4 do local d=CreateFrame("Button",name.."Debuff"..j,owner);d:SetPoint("TOPLEFT",owner,"TOPLEFT",48,-32);d:SetScript("OnEnter",secureClick) end
 local check=CreateFrame("Frame",name.."ReadyCheck",owner);check:SetPoint("CENTER",owner.portrait,"CENTER",0,0)
 local pet=CreateFrame("Button",name.."PetFrame",owner);pet.protected=true;pet:SetWidth(64);pet:SetHeight(26);pet:SetHitRectInsets(3,33,3,3)
 pet:SetPoint("TOPLEFT",owner,"TOPLEFT",23,-43);pet:SetScript("OnClick",secureClick)
 pet.healthbar=CreateFrame("StatusBar",name.."PetFrameHealthBar",pet)
 CreateFrame("Texture",name.."PetFramePortrait",pet)
 UNITS["party"..i]={hp=80,maxhp=100,mana=20,maxmana=40,player=true,class="WARRIOR"}
 UNITS["partypet"..i]={hp=50,maxhp=100,mana=0,maxmana=1,player=false}
end
PetFrame=CreateFrame("Button","PetFrame",UIParent);PetFrame.unit="pet";PetFrame.protected=true;PetFrame:SetWidth(128);PetFrame:SetHeight(53)
PetFrame.healthbar=CreateFrame("StatusBar","PetFrameHealthBar",PetFrame);PetFrame.manabar=CreateFrame("StatusBar","PetFrameManaBar",PetFrame)
PetFrame.portrait=CreateFrame("Texture","PetFramePortrait",PetFrame);UNITS.pet=UNITS.partypet1
-- Existing simplified fixture entry must be rediscovered after replacing native art.
a.frames.PartyMemberFrame1=nil
a:Set("compactParty",true)
for i=1,4 do
 local owner=_G["PartyMemberFrame"..i];local e=a.frames["PartyMemberFrame"..i];local pet=_G["PartyMemberFrame"..i.."PetFrame"]
 ok(near(owner:GetWidth(),102.4) and owner:GetHeight()==52 and e.portrait:GetAlpha()==0,"#24 member "..i.." becomes portrait-free rectangle")
 ok(owner:GetScript("OnClick")==secureClick and owner.attributes.unit=="party"..i and owner:GetParent()==UIParent,"#24 member "..i.." keeps native secure identity/clicks/parent")
 local left,right=owner:GetHitRectInsets();ok(left==0 and right==0,"#24 full rectangle remains clickable "..i)
 ok(e.compactName:IsShown() and e.health:GetHeight()==26 and e.power:GetHeight()==11,"#24 member "..i.." retains name/health/resource")
 ok(pet:GetParent()==owner and pet:GetHeight()==31 and near(pet:GetWidth(),90.4) and pet:GetScript("OnClick")==secureClick,"#24 pet "..i.." retains native parent/interaction and reserves space for taller body")
 local v;for _,child in ipairs(pet.children) do if child.unit=="partypet"..i then v=child end end
 ok(v and v:GetValue()==50 and v.name:GetText():find("50%%"),"#24 pet "..i.." shows health and identity")
 local d=_G["PartyMemberFrame"..i.."Debuff1"]
 local _,relative,_,x=d:GetPoint(1)
 ok(relative==owner and near(x,106.4) and d:GetScript("OnEnter")==secureClick,"#24 native debuff indicators/tooltips remain beside member "..i)
 local _,_,_,cx,cy=a.castbars[i]:GetPoint(1)
 ok(near(cx,106.4) and cy==-35,"#24 cast bar remains usable beside member "..i)
end
ok(a.frames.PetFrame.compact and PetFrame:GetParent()==UIParent,"#24 owner's pet is restyled without duplicate player/party button")
for size=0,4 do
 PARTY_SIZE=size
 for i=1,4 do local f=_G["PartyMemberFrame"..i];if i<=size then f:Show() else f:Hide() end end
 a:GetScript("OnEvent")(a,"PARTY_MEMBERS_CHANGED")
 local visible=0;for i=1,4 do if _G["PartyMemberFrame"..i]:IsShown() then visible=visible+1 end end
 ok(visible==size and raid:GetParent()==UIParent,"#24 solo/party population "..size.." never forces native visibility or touches raids")
end
UNITS.party1.offline=true;a:Refresh();ok(a.frames.PartyMemberFrame1.health.text:GetText()=="Offline","#24 disconnected member status readable")
UNITS.party1.offline=nil;UNITS.partypet1.dead=true;a:Refresh()
local pv;for _,v in ipairs(PartyMemberFrame1PetFrame.children) do if v.unit=="partypet1" then pv=v end end
ok(pv.name:GetText():find(DEAD),"#24 pet death updates status")
PartyMemberFrame1PetFrame:Hide();a:GetScript("OnEvent")(a,"UNIT_PET","party1")
ok(not PartyMemberFrame1PetFrame:IsShown(),"#24 despawned pet stays native-hidden")
a:Set("compactParty",false)
for i=1,4 do
 local e=a.frames["PartyMemberFrame"..i];local owner=e.owner
 local l,r=owner:GetHitRectInsets()
 ok(owner:GetWidth()==128 and owner:GetHeight()==53 and l==7 and r==85 and e.portrait:GetAlpha()==1,"#24 standard member geometry/art/hitrect restored "..i)
 ok(_G["PartyMemberFrame"..i.."PetFrame"]:GetWidth()==64,"#24 native pet width restored "..i)
end
local point=a.frames.PartyMemberFrame1.health.text:GetPoint(1)
ok(point=="CENTER","#24 standard health text anchor restored")
a:Set("compactParty",true)
COMBAT=true;RAID_SIZE=10;a:GetScript("OnEvent")(a,"RAID_ROSTER_UPDATE")
ok(a.pending and PartyMemberFrame1:GetHeight()==52,"#24 combat party-to-raid defers only party geometry without touching raid widgets")
COMBAT=false;a:GetScript("OnEvent")(a,"PLAYER_REGEN_ENABLED")
RAID_SIZE=0;a:GetScript("OnEvent")(a,"RAID_ROSTER_UPDATE")
RAID_SIZE=10;a:GetScript("OnEvent")(a,"RAID_ROSTER_UPDATE")
ok(PartyMemberFrame1:GetHeight()==53 and not a.frames.PartyMemberFrame1.compact and not a.frames.PetFrame.compact,"#24 party-to-raid restores native party/pet presentation; raid sentinels untouched")
RAID_SIZE=0;a:GetScript("OnEvent")(a,"RAID_ROSTER_UPDATE")
ok(PartyMemberFrame1:GetHeight()==52,"#24 raid-to-party reapplies selected compact preference")
COMBAT=true;a:Set("compactParty",false)
ok(PartyMemberFrame1:GetHeight()==52 and a.pending,"#24 toggle in combat saves preference without protected geometry")
COMBAT=false;a:GetScript("OnEvent")(a,"PLAYER_REGEN_ENABLED")
ok(PartyMemberFrame1:GetHeight()==53,"#24 combat-deferred toggle restores native layout")
a:Profile("save","Standard party","account");a:Profile("save","Compact private","character");a:Set("compactParty",true)
a:InitSettings();a:Apply();ok(a.db.compactParty and PartyMemberFrame1:GetHeight()==52,"#24 private compact choice survives reinitialization")
a:Profile("load","Standard party","account");ok(not a.db.compactParty and PartyMemberFrame1:GetHeight()==53,"#24 profile switch restores standard layout")
a:Profile("load","Compact private","character");a:ResetFrames()
local _,reference,_,rx,ry=PartyMemberFrame1:GetPoint(1)
ok(PartyMemberFrame1:GetHeight()==52 and next(a.db.positions)==nil and reference==UIParent and rx==10 and ry==-160,"#24 reset in compact mode retains compact style and restores native group position")
a:Set("enabled",false)
ok(PartyMemberFrame1:GetHeight()==53 and not a.frames.PartyMemberFrame1.compact,"#24 addon disable restores standard party frames")
print("TOTAL new issues "..total.." assertions passed")
