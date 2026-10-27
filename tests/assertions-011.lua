-- Runs in a fresh VM with the actual SetUserPlaced precondition enforced by the mock.
local a=BetterLKFrames
local n=0
local function ok(v,name) assert(v,name);n=n+1;print("PASS #11 "..name) end
local calls={}
for _,key in ipairs({"Theme","SetupCasts","Refresh","RefreshAuraOffset","UpdateTestAuras"}) do
 local name,original=key,a[key]
 a[key]=function(self,...)
  calls[name]=(calls[name] or 0)+1
  return original(self,...)
 end
end
local function tails(before)
 for _,key in ipairs({"Theme","SetupCasts","Refresh","RefreshAuraOffset","UpdateTestAuras"}) do
  if (calls[key] or 0)<=(before[key] or 0) then return false end
 end
 return true
end
local function callSnapshot() return a.Copy(calls) end
BetterLKFramesDB={version=3,blizzardLayout=true,healthHeight=28,powerHeight=9,frameScale=1.1}
local before=callSnapshot()
a.scripts.OnEvent(a,"ADDON_LOADED","BetterLKFrames")
a.scripts.OnEvent(a,"PLAYER_LOGIN")
ok(not TargetFrame:IsMovable() and not TargetFrame:IsResizable() and not TargetFrame:IsUserPlaced(),"startup preserves native immovable target flags")
ok((TargetFrame.userPlacedCalls or 0)==0,"startup never calls SetUserPlaced on an already unplaced target")
ok(tails(before),"startup reaches every post-frame apply stage")
ok(a.frames.TargetFrame.health:GetHeight()==28 and a.frames.TargetFrame.power:GetHeight()==9,"startup applies health and power geometry")
-- Explicitly check the C API restriction remains enforced; the fix must not catch/suppress it.
local success,err=pcall(function() TargetFrame:SetUserPlaced(false) end)
ok(not success and err:find("TargetFrame is not movable or resizable",1,true),"mock reproduces original client precondition even when passing false")
local target=a.frames.TargetFrame
local baseSetMovable=TargetFrame.SetMovable
local flagChanges={}
TargetFrame.SetMovable=function(self,value) flagChanges[#flagChanges+1]=value;return baseSetMovable(self,value) end
-- Cached user-placed state may outlive the native XML's movable flag after reload.
TargetFrame.userPlaced=true;target.layoutDB=nil;before=callSnapshot()
ok(a:Apply(),"apply clears stale cached placement on immovable target")
ok(not TargetFrame:IsUserPlaced() and not TargetFrame:IsMovable() and not TargetFrame:IsResizable(),"stale placement cleared with original flags restored")
ok(#flagChanges==2 and flagChanges[1] and not flagChanges[2],"temporary mobility is scoped only to a necessary placement clear")
ok(tails(before),"stale-placement apply reaches all later stages")
local cleared=TargetFrame.userPlacedCalls
a:Apply()
ok(TargetFrame.userPlacedCalls==cleared and #flagChanges==2,"repeated apply does not change mobility or placement flags")
-- A resizable-only frame already satisfies the precondition and must not be made movable.
TargetFrame.resizable=true;TargetFrame.userPlaced=true;target.layoutDB=nil;flagChanges={}
a:Apply()
ok(not TargetFrame:IsUserPlaced() and TargetFrame:IsResizable() and not TargetFrame:IsMovable() and #flagChanges==0,"resizable-only frame retains its original flags")
TargetFrame.resizable=false;TargetFrame.movable=true;TargetFrame.userPlaced=true;target.layoutDB=nil
flagChanges={};a:Apply()
ok(not TargetFrame:IsUserPlaced() and TargetFrame:IsMovable() and #flagChanges==0,"already movable frame retains native mobility")
TargetFrame.movable=false
-- Retry settings from every tab after a pending restoration, as in the owner's report.
for index,page in ipairs(a.optionsPages) do
 local count=0
 for _,control in ipairs(page.children or {}) do
  if control.kind=="CheckButton" and control:GetScript("OnClick") then
   local title=_G[control:GetName().."Text"]:GetText()
   if title~="Show test auras" then
    a:Set("enabled",true);target.layoutDB=nil;before=callSnapshot()
    control:SetChecked(not control:GetChecked());control:GetScript("OnClick")(control)
    ok(tails(before),"checkbox finishes all apply stages: "..title)
    count=count+1
   end
  end
 end
 if index<=3 then ok(count>0,"settings controls exercised on tab "..index) end
end
-- Sliders and actual bar width come from the native bar and saved frame scale.
a:Set("enabled",true);a:Set("bigBars",true)
TargetFrame.healthbar:SetWidth(175);TargetFrame.manabar:SetWidth(140)
a:Set("healthHeight",29);a:Set("powerHeight",9);a:Set("frameScale",1.25)
ok(target.health:GetWidth()==175 and target.health:GetHeight()==29 and target.power:GetWidth()==140 and target.power:GetHeight()==9,"native widths and configured heights all apply")
ok(TargetFrame:GetScale()==1.25 and target.health:GetWidth()*TargetFrame:GetEffectiveScale()==218.75,"saved scale widens the displayed health bar")
a:Profile("save","Geometry A","account")
a:CharacterProfile("account") -- Leave A before editing a different configuration.
a:Set("healthHeight",20);a:Set("frameScale",.8);a:Profile("save","Geometry B","character")
a.db.positions.TargetFrame={x=700,y=500};a:CommitSettings()
before=callSnapshot()
ok(a:Profile("load","Geometry A","account") and tails(before),"profile switching finishes every apply stage")
ok(target.health:GetWidth()==175 and target.health:GetHeight()==29 and TargetFrame:GetScale()==1.25,"profile restores native width and saved bar geometry/scale")
a:InitSettings();before=callSnapshot();a:Apply()
ok(tails(before) and target.health:GetHeight()==29 and TargetFrame:GetScale()==1.25,"selected geometry persists across reload initialization")
ok(BetterLKFramesCharDB.profiles['Geometry B'].healthHeight==20 and BetterLKFramesCharDB.profiles['Geometry B'].positions.TargetFrame.x==700,"other profile settings and layout remain intact")
-- Reset also clears stale native placement safely and preserves other options/profile data.
TargetFrame.movable=false;TargetFrame.resizable=false;TargetFrame.userPlaced=true;flagChanges={}
a.db.positions.TargetFrame={x=800,y=600};a:CommitSettings();a:Apply()
a:SetUnlocked(true);before=callSnapshot()
ok(a:ResetFrames() and tails(before),"reset finishes all later settings stages")
ok(not a.unlocked and not target.mover:IsShown() and not TargetFrame:IsMovable() and not TargetFrame:IsResizable() and not TargetFrame:IsUserPlaced(),"reset clears placement without leaving target unlocked or changing flags")
ok(TargetFrame.points[1][4]==250 and TargetFrame.points[1][5]==-4 and next(a.db.positions)==nil,"reset restores native target anchor and clears saved offsets")
ok(a.db.healthHeight==29 and a.db.frameScale==1.25 and BetterLKFramesCharDB.profiles['Geometry B'].positions.TargetFrame.x==700,"reset preserves other options and profile layouts")
a:InitSettings();a:Apply()
ok(TargetFrame.points[1][4]==250 and target.health:GetHeight()==29,"reset and geometry persist together")
-- Real dragging is still available through handles; flags changed by dragging remain intentional.
a:SetUnlocked(true);target.mover:GetScript("OnDragStart")()
TargetFrame:SetUserPlaced(true);target.mover:GetScript("OnDragStop")()
ok(TargetFrame:IsMovable() and a.db.positions.TargetFrame and target.positionApplied,"manual drag and saved position still work")
a:SetUnlocked(false);a:ResetFrames()
ok(TargetFrame:IsMovable() and not TargetFrame:IsUserPlaced() and not target.mover:IsShown(),"reset preserves mobility established by an intentional drag, while locking handles")
-- Protected flags and anchors cannot be touched until combat ends.
TargetFrame.movable=false;TargetFrame.userPlaced=true;target.layoutDB=nil
local count=#flagChanges;before=callSnapshot();COMBAT=true
ok(not a:Apply() and not a:ResetFrames() and TargetFrame:IsUserPlaced() and #flagChanges==count,"combat defers placement work without any flag mutation")
a:Set("healthHeight",27)
COMBAT=false;a.scripts.OnEvent(a,"PLAYER_REGEN_ENABLED")
ok(tails(before) and not TargetFrame:IsMovable() and not TargetFrame:IsUserPlaced() and target.health:GetHeight()==27,"deferred apply clears placement safely and resumes later settings")
TargetFrame.SetMovable=baseSetMovable
print("TOTAL #11 "..n.." assertions passed")
