local a=BetterLKFrames
local n=0
local function ok(v,label) assert(v,label);n=n+1;print("PASS #29 "..label) end
BetterLKFramesDB=nil;BetterLKFramesCharDB=nil;a:InitSettings();a:Apply();a:BuildOptions()
local names={"MainMenuBarTexture0","MainMenuBarTexture1","MainMenuBarTexture2","MainMenuBarTexture3",
 "MainMenuBarLeftEndCap","MainMenuBarRightEndCap","BonusActionBarTexture0","BonusActionBarTexture1"}
local bar=CreateFrame("Frame","MainMenuBar",UIParent);bar.protected=true
local button=ActionButton1;local callback=function() end;button:SetScript("OnClick",callback)
local untouched={}
for _,name in ipairs({"MainMenuExpBar","ReputationWatchBar","MainMenuXPBarTexture0","MainMenuMaxLevelBar0",
 "SlidingActionBarTexture0","ShapeshiftBarLeft","PossessBackground1","MainMenuBarVehicleLeaveButton","MultiBarBottomLeft"}) do
 local f=CreateFrame("Frame",name,UIParent);f.protected=true;untouched[#untouched+1]=f
end
for _,name in ipairs(names) do local t=CreateFrame("Texture",name,bar);t:SetAlpha(.7) end
local choice
for _,c in ipairs(a.optionsPages[1].children) do
 if c:GetName() and _G[c:GetName().."Text"] and _G[c:GetName().."Text"]:GetText()=="Hide main action-bar artwork" then choice=c end
end
ok(a.defaults.hideMainBarArt==false and choice and not choice:GetChecked(),"new checkbox defaults off")
a:Theme();ok(MainMenuBarTexture0:GetAlpha()==.7,"default leaves existing opacity alone")
a:Set("hideMainBarArt",true)
for _,name in ipairs(names) do ok(_G[name]:GetAlpha()==0 and _G[name]:IsShown(),"only decorative opacity hidden: "..name) end
for _,f in ipairs(untouched) do ok(f:GetAlpha()==1 and f:IsShown(),"functional/secondary UI preserved: "..f:GetName()) end
ok(bar:IsShown() and bar:GetAlpha()==1 and button:GetScript("OnClick")==callback and button:IsShown(),"bar frame and secure button interaction unchanged")
MainMenuBarTexture3:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-KeyRing");MainMenuBarTexture3:SetAlpha(.4)
ok(MainMenuBarTexture3:GetAlpha()==0,"native keyring/opacity refresh stays suppressed")
MainMenuBarLeftEndCap:Hide();a:Set("hideMainBarArt",false)
ok(MainMenuBarTexture3:GetAlpha()==.4 and not MainMenuBarLeftEndCap:IsShown(),"restore uses latest native alpha without forcing hidden art visible")
ok(MainMenuBarTexture0.colour[1]==a.db.darkness,"restore retains selected dark action-bar tint")
a:Set("darkActionBars",false);ok(MainMenuBarTexture0.colour[1]==1,"dark theme remains independently reversible")
COMBAT=true;a:Set("hideMainBarArt",true);a:Theme()
ok(a.pending and MainMenuBarTexture0:GetAlpha()==.7,"enabling in combat defers artwork changes")
COMBAT=false;a:GetScript("OnEvent")(a,"PLAYER_REGEN_ENABLED")
ok(MainMenuBarTexture0:GetAlpha()==0,"deferred hide applies after combat")
COMBAT=true;MainMenuBarTexture0:SetAlpha(.5)
ok(MainMenuBarTexture0:GetAlpha()==0,"existing suppression survives native opacity updates in combat without frame geometry")
a:Set("hideMainBarArt",false);a:Theme()
ok(MainMenuBarTexture0:GetAlpha()==0,"disabling during combat also defers restoration")
COMBAT=false;a:GetScript("OnEvent")(a,"PLAYER_REGEN_ENABLED")
ok(MainMenuBarTexture0:GetAlpha()==.5,"post-combat restore respects native-requested opacity")
a:Profile("save","Artwork visible","account");a:Profile("save","Artwork hidden","character");a:Set("hideMainBarArt",true)
a:InitSettings();a:Apply();ok(a.db.hideMainBarArt and MainMenuBarTexture0:GetAlpha()==0,"private profile preference survives reinitialization")
a:Profile("load","Artwork visible","account");ok(not a.db.hideMainBarArt and MainMenuBarTexture0:GetAlpha()==.5,"profile switch restores visible artwork")
a:Profile("load","Artwork hidden","character");a:Set("enabled",false)
ok(MainMenuBarTexture0:GetAlpha()==.5 and bar:IsShown(),"disabling addon restores artwork without changing bar state")
a:Set("enabled",true)
BonusActionBarTexture1=nil;a:Theme()
local late=CreateFrame("Texture","BonusActionBarTexture1",bar);late:SetAlpha(.6);a:Theme()
ok(late:GetAlpha()==0,"late native decoration is discovered without scanning buttons")
a:Set("hideMainBarArt",false)
ok(late:GetAlpha()==.6,"late decoration restores its own original opacity")
print("TOTAL #29 "..n.." assertions passed")
