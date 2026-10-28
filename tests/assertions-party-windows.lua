local a=BetterLKFrames
local n=0
local function ok(v,name) assert(v,name);n=n+1;print("PASS followup round "..name) end
local function near(x,y) return math.abs(x-y)<.001 end
BetterLKFramesDB=nil;BetterLKFramesCharDB=nil;a:InitSettings();a:Apply();a:BuildOptions()
-- Label-sized widths and neighbouring anchors, in both settings hosts.
local total=0
for i,tab in ipairs(a.optionsNavigation) do
 total=total+tab:GetWidth()
 local p,r,rp,x,y=tab:GetPoint(1)
 ok(tab:GetWidth()==tab:GetTextWidth()+_G[tab:GetName().."Left"]:GetWidth()*2+8,"#16 label-sized tab "..i)
 if i>1 then ok(p=="TOPLEFT" and r==a.optionsNavigation[i-1] and rp=="TOPRIGHT" and x==2 and y==0,"#16 small consistent adjacent gap "..i) end
end
ok(total<500,"#16 strip occupies content width without stretching")
a:ShowStandaloneOptions();OpenTestCategory();a:SelectOptionsPage(3)
ok(a.options.selectedTab==3 and a.optionsPages[3]:IsShown(),"#16 selection works in embedded host")
a:ShowStandaloneOptions();ok(a.options.selectedTab==3,"#16 reopening preserves selected tab")
-- Actual 12340 atlas names/dimensions; originals remain untouched.
CharacterFrame=CreateFrame("Frame","CharacterFrame",UIParent)
local paper=CreateFrame("Frame","PaperDollFrame",CharacterFrame)
SpellBookFrame=CreateFrame("Frame","SpellBookFrame",UIParent)
local sources={}
for _,v in ipairs({
 {paper,"Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1",256},
 {paper,"Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-R1",128},
 {paper,"Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-BottomLeft",256},
 {paper,"Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-BottomRight",128},
 {SpellBookFrame,"Interface\\Spellbook\\UI-SpellbookPanel-TopLeft",256},
 {SpellBookFrame,"Interface\\Spellbook\\UI-SpellbookPanel-TopRight",128},
 {SpellBookFrame,"Interface\\Spellbook\\UI-SpellbookPanel-BotLeft",256},
 {SpellBookFrame,"Interface\\Spellbook\\UI-SpellbookPanel-BotRight",128}}) do
 local t=v[1]:CreateTexture(nil,"ARTWORK");t:SetTexture(v[2]);t:SetWidth(v[3]);t:SetHeight(256);sources[#sources+1]=t
end
local icon=SpellBookFrame:CreateTexture(nil,"ARTWORK");icon:SetTexture("Interface\\Icons\\Spell_Frost_FrostBolt02")
local model=paper:CreateTexture(nil,"ARTWORK");model:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-StatBackground")
a:Set("darkness",.3);a:Set("darkWindows",true)
for _,src in ipairs(sources) do
 local overlays={}
 for _,t in ipairs(src:GetParent().regions) do
  if t.points[1] and t.points[1][2]==src and t:IsShown() then overlays[#overlays+1]=t end
 end
 ok(#overlays>=2,"#19 native atlas gets visible trim copies: "..src:GetTexture())
 ok(src.colour==nil and src:GetTexture()~=nil,"#19 original atlas colours retained")
 local found=false
 for _,t in ipairs(overlays) do
  local _,_,_,x,y=t:GetPoint(1)
  if src:GetWidth()==128 and x==88 then found=true end
  if src:GetTexture():find("Bot") and y==-176 then found=true end
  ok(t.layer=="OVERLAY" and near(t.colour[1],.3),"#19 copied trim drawn above atlas with selected darkness")
 end
 if src:GetWidth()==128 then ok(found,"#19 right rim uses interior atlas coordinates, not transparent tile edge") end
end
ok(icon.colour==nil and model.colour==nil,"#19 spell icons and stat/model art remain untinted")
local count=#paper.regions+#SpellBookFrame.regions
a:ThemeWindows();a:ThemeWindows();ok(count==#paper.regions+#SpellBookFrame.regions,"#19 repeated scans do not duplicate overlays")
local function visibleCopies()
 local count=0
 for _,p in ipairs({paper,SpellBookFrame}) do
  for _,t in ipairs(p.regions) do if t.blkGeometry and t:IsShown() then count=count+1 end end
 end
 return count
end
a:Set("darkWindows",false);ok(visibleCopies()==0,"#19 toggle off restores original art")
SpellBookFrame:Hide();a:Set("darkWindows",true);SpellBookFrame:Show()
ok(visibleCopies()>0,"#19 opening window reapplies selected treatment")
a:Set("enabled",false);ok(visibleCopies()==0,"#19 disable restores normal trim")
a:Set("enabled",true)
-- A realistic four-member native chain with pets; no production UI globals spoofed.
UIParent:SetWidth(1000);UIParent:SetHeight(800);UIParent.left=0;UIParent.bottom=0
local function geometry(f)
 f.GetLeft=function(self)
  if self.left then return self.left end
  local p,r,rp,x=self:GetPoint(1);if type(r)=="string" then r=_G[r] end
  if not r then return 0 end
  local factor=r:GetEffectiveScale()/self:GetEffectiveScale()
  local base=r:GetLeft();if rp and rp:find("RIGHT") then base=base+r:GetWidth() end
  return base*factor+(x or 0)-(p and p:find("RIGHT") and self:GetWidth() or 0)
 end
 f.GetBottom=function(self)
  if self.bottom then return self.bottom end
  local p,r,rp,_,y=self:GetPoint(1);if type(r)=="string" then r=_G[r] end
  if not r then return 0 end
  local factor=r:GetEffectiveScale()/self:GetEffectiveScale()
  local base=r:GetBottom();if rp and rp:find("TOP") then base=base+r:GetHeight() end
  return base*factor+(y or 0)-(p and p:find("TOP") and self:GetHeight() or 0)
 end
end
for i=1,4 do
 local name="PartyMemberFrame"..i;local f=_G[name]
 if not f then
  f=CreateFrame("Button",name,UIParent);f.unit="party"..i;f.protected=true
  f.healthbar=CreateFrame("StatusBar",name.."HealthBar",f);f.manabar=CreateFrame("StatusBar",name.."ManaBar",f)
 end
 f:SetWidth(128);f:SetHeight(53);f:ClearAllPoints()
 if i==1 then f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-160)
 else f:SetPoint("TOPLEFT",_G["PartyMemberFrame"..(i-1).."PetFrame"],"BOTTOMLEFT",-23,-10) end
 geometry(f)
 local pet=CreateFrame("Button",name.."PetFrame",f);pet:SetWidth(70);pet:SetHeight(16)
 pet:SetPoint("TOPLEFT",f,"TOPLEFT",23,-27);geometry(pet)
 pet.GetEffectiveScale=function() return f:GetEffectiveScale() end
 f:Hide();pet:Hide();UNITS["party"..i]=nil
end
-- New native fixtures replace the one simplified mock entry, before discovery.
a.frames.PartyMemberFrame1=nil
a:Apply();a:SetUnlocked(true)
local g=a.partyGroup;local m=g.owner;geometry(m)
ok(m:IsShown() and m:GetParent()==UIParent and not m.protected,"#20 independent group handle is visible while solo")
for i=1,4 do
 ok(not _G["PartyMemberFrame"..i]:IsShown() and not a.frames["PartyMemberFrame"..i].mover,"#20 real member remains hidden and has no individual handle "..i)
end
ok(m:GetHeight()>=249,"#20 solo preview reserves the whole party group")
local old1=PartyMemberFrame1:GetLeft();local old2=PartyMemberFrame2:GetLeft()
m:GetScript("OnDragStart")();m.left=300;m.bottom=200
ok(PartyMemberFrame1:GetLeft()==old1 and PartyMemberFrame2:GetLeft()==old2,"#20 dragging preview does not spoof native visibility or unit state")
a.db.snapFrames=false;m:GetScript("OnDragStop")()
ok(a.db.positions.PartyMemberFrame1.x==300,"#20 releasing group saves one shared anchor")
ok(near(PartyMemberFrame1:GetLeft(),300) and near(PartyMemberFrame2:GetLeft(),300) and near(PartyMemberFrame4:GetLeft(),300),"#20 all four native members move together")
ok(a.db.positions.PartyMemberFrame2==nil and a.db.positions.PartyMemberFrame4==nil,"#20 group placement does not persist independent member positions")
local _,anchor=PartyMemberFrame2:GetPoint(1)
ok(anchor==PartyMemberFrame1PetFrame and PartyMemberFrame2:GetParent()==UIParent,"#20 native pet chain and secure parents retained")
PartyMemberFrame2:ClearAllPoints();PartyMemberFrame2:SetPoint("TOPLEFT",UIParent,"TOPLEFT",900,-500)
a:InitSettings();a:Apply()
local _,restoredChain=PartyMemberFrame2:GetPoint(1)
ok(a.db.partyGrouped and restoredChain==PartyMemberFrame1PetFrame,"#20 reload reapplies persisted group chain rather than stale individual anchors")
local previousY=PartyMemberFrame2:GetBottom()
PartyMemberFrame1PetFrame:ClearAllPoints();PartyMemberFrame1PetFrame:SetPoint("TOPLEFT",PartyMemberFrame1,"TOPLEFT",23,-43)
ok(near(previousY-PartyMemberFrame2:GetBottom(),16),"#20 native chain follows appearing party pets")
for _,size in ipairs({1,2,4}) do
 for i=1,4 do
  local f=_G["PartyMemberFrame"..i]
  UNITS["party"..i]=i<=size and UNITS.player or nil
  if i<=size then f:Show() else f:Hide() end
 end
 a:GetScript("OnEvent")(a,"PARTY_MEMBERS_CHANGED");a:GetScript("OnUpdate")(a,.3)
 local visible=0;for i=1,4 do if _G["PartyMemberFrame"..i]:IsShown() then visible=visible+1 end end
 ok(visible==size and m:IsShown(),"#20 party size "..size.." retains native visibility and one group handle")
end
local saved=a.Copy(a.db.positions);local player=PlayerFrame:GetScale();a:Set("frameScale",1.4)
for i=1,4 do ok(near(_G["PartyMemberFrame"..i]:GetScale(),1.4),"#20 existing all-unit scale includes member "..i) end
ok(near(PlayerFrame:GetScale(),player*1.4) and a.db.positions.PartyMemberFrame1.x==saved.PartyMemberFrame1.x,"#20 documented global scale retains existing scope and saved position")
-- Both profile libraries preserve party position/scale and character isolation.
a:Profile("save","Party shared","account");a:SetUnlocked(false)
ok(not m:IsShown() and not m.moving,"#20 locking hides handle and stops movement")
a:Profile("save","Party private","character");a:Set("frameScale",.8)
a.db.positions.PartyMemberFrame1={x=550,y=150};a:CommitSettings();a:Apply()
a:Profile("load","Party shared","account")
ok(a.db.frameScale==1.4 and a.db.positions.PartyMemberFrame1.x==300,"#20 shared profile retains party layout")
a:Profile("load","Party private","character");a:InitSettings();a:Apply()
ok(a.db.frameScale==.8 and a.db.positions.PartyMemberFrame1.x==550,"#20 private party layout survives reinitialization")
a:SetUnlocked(true);m.left=600;m.bottom=100;m:GetScript("OnDragStart")()
COMBAT=true;a:GetScript("OnEvent")(a,"PLAYER_REGEN_DISABLED")
ok(not m:IsShown() and not m.moving and g.stopPending and not a.unlocked,"#20 combat hides independent preview and defers geometry safely")
local before=a.db.positions.PartyMemberFrame1.x
a:Set("frameScale",1.2);ok(a.db.positions.PartyMemberFrame1.x==before,"#20 combat setting does not mutate native layout")
COMBAT=false;a:GetScript("OnEvent")(a,"PLAYER_REGEN_ENABLED")
ok(not g.stopPending and not m.moving and a.db.positions.PartyMemberFrame1.x==600,"#20 pending release completes outside combat")
-- A pending drag must never be committed into another profile or undo reset.
a:SetUnlocked(true);m:GetScript("OnDragStart")();m.left=700
COMBAT=true;a:GetScript("OnEvent")(a,"PLAYER_REGEN_DISABLED")
COMBAT=false;a:Profile("load","Party shared","account")
a:Apply()
ok(a.db.positions.PartyMemberFrame1.x==300,"#20 pending placement cannot overwrite a different selected profile")
a:SetUnlocked(true);m:GetScript("OnDragStart")();COMBAT=true;a:GetScript("OnEvent")(a,"PLAYER_REGEN_DISABLED")
COMBAT=false;a:ResetFrames()
ok(next(a.db.positions)==nil and not a.db.partyGrouped and not g.stopPending and not m:IsShown(),"#20 reset cancels deferred movement and clears group placement")
local _,ref,_,x,y=PartyMemberFrame1:GetPoint(1)
ok(ref==UIParent and x==10 and y==-160,"#20 reset restores native first member position")
ok(a.db.frameScale==1.4,"#20 position reset preserves selected scale")
a:Set("enabled",false);ok(near(PartyMemberFrame1:GetScale(),1) and near(PlayerFrame:GetScale(),1),"#20 disable restores native unit scales")
print("TOTAL followup round "..n.." assertions passed")
