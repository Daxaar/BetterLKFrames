local a=BetterLKFrames
local n=0
local function ok(v,name) assert(v,name);n=n+1;print("PASS issues "..name) end
local function checkbox(title)
    for i=1,100 do
        local c=_G["BetterLKFramesCheck"..i]
        if c and _G[c:GetName().."Text"]:GetText()==title then return c end
    end
    error("Missing checkbox: "..title)
end
-- #1: true first-run initialization, and an upgrade with explicit aura preferences.
BetterLKFramesDB=nil;BetterLKFramesCharDB=nil;a:InitSettings();a:Apply();a:RefreshOptions()
for _,key in ipairs({"auraTimers","auraSpirals","auraWarnings","darkAuras"}) do
    ok(a.db[key]==false,"fresh default disabled: "..key)
end
ok(a.db.auraOffset==0 and next(a.db.importantSpells)==nil,"fresh aura gap and important borders inactive")
for _,title in ipairs({"Aura time remaining","Add missing aura cooldown spirals","Expiring-aura red border","Dark buff/debuff borders"}) do
    ok(not checkbox(title):GetChecked(),"UI reflects disabled default: "..title)
end
BUFFS.player={{"Test aura","","icon",1,nil,10,NOW+4,"player",false,false,123}}
a:UpdateAuras()
ok(BuffButton1.blkAura.time:GetText()=="" and not BuffButton1.blkAura.edge:IsShown() and
    not BuffButton1.blkAura.cooldown:IsShown() and not BuffButton1.blkAura.skin:IsShown(),"fresh install has no custom aura visuals")
ok(BuffButton1.duration:GetAlpha()==1,"native aura duration remains visible")
local upgrade=a.Normalize({version=3,auraTimers=true,auraSpirals=false,auraWarnings=true,darkAuras=true,auraOffset=7,importantSpells={[123]=true}})
ok(upgrade.auraTimers and not upgrade.auraSpirals and upgrade.auraWarnings and upgrade.darkAuras and
    upgrade.auraOffset==7 and upgrade.importantSpells[123],"upgrade preserves explicit aura preferences")
-- #2: native template art, native hover/pushed treatment and persistent selected highlight.
a:Set("darkWindows",true);a:Set("darkness",.1)
for _,nav in ipairs(a.optionsNavigation) do
    ok(nav.template=="OptionsFrameTabButtonTemplate" and nav:GetWidth()==145,"navigation uses legible native tabs")
end
local nav=a.optionsNavigation[3];nav:GetScript("OnClick")(nav)
ok(nav.selected and nav.blkPage:IsShown() and not a.optionsNavigation[1].selected,"navigation selection tracks active page")
a:ThemeOptions();ok(nav.selected,"periodic theming preserves selected tab")
-- #3: retain existing command owners, register all available aliases contiguously.
local other=function() end
SLASH_OTHERADDON1="/BF";SlashCmdList.OTHERADDON=other
a:RegisterCommands()
ok(SLASH_OTHERADDON1=="/BF" and SlashCmdList.OTHERADDON==other,"conflicting addon command untouched")
local aliases={};for i=1,4 do if _G["SLASH_BETTERLKFRAMES"..i] then aliases[_G["SLASH_BETTERLKFRAMES"..i]]=true end end
ok(not aliases['/bf'] and aliases['/blkf'] and aliases['/gf'] and aliases['/betterlkframes'],"conflicting short alias skipped; compatibility aliases retained")
SLASH_OTHERADDON1=nil;SlashCmdList.OTHERADDON=nil;a:RegisterCommands()
ok(SLASH_BETTERLKFRAMES1=="/bf" and SLASH_BETTERLKFRAMES2=="/blkf" and SLASH_BETTERLKFRAMES4=="/gf","preferred and legacy aliases registered")
a.options:Hide();SlashCmdList.BETTERLKFRAMES("");ok(a.options:IsShown(),"shared alias handler opens options")
-- #4: legacy library remains account-wide without mutating its saved preferences.
BetterLKFramesDB={version=3,healthHeight=22,profiles={Legacy={version=3,healthHeight=25,auraTimers=true,positions={PlayerFrame={x=300,y=200}}}}}
BetterLKFramesCharDB={};a:InitSettings();a:Apply()
local account=a.accountDB
local entries=a:ListProfiles()
ok(#entries==2 and entries[2].scope=="account" and entries[2].name=="Legacy","legacy profile safely retained as account-wide")
ok(a:Profile("load","Legacy") and a.db.healthHeight==25 and a.db.auraTimers,"legacy profile loads retained settings")
a:Set("healthHeight",26);a:InitSettings()
ok(a.db.healthHeight==26 and BetterLKFramesCharDB.activeProfile.name=="Legacy","selection and edits survive initialization")
ok(account.healthHeight==22 and account.profiles.Legacy.profiles==nil,"active named profile isolated from unnamed settings and recursive library copies")
ok(a:Profile("save","Centre","character"),"create character profile from current settings")
a:Set("healthHeight",28)
ok(a.db.healthHeight==28 and account.profiles.Legacy.healthHeight==26,"character profile edits do not affect account profile")
ok(a:Profile("save","Centre","account"),"same base name allowed in another scope")
a:Set("healthHeight",29)
local characterSave=BetterLKFramesCharDB
local list=a:ListProfiles();local characterLabel
for _,entry in ipairs(list) do if entry.scope=="character" then characterLabel=entry.label end end
ok(#list==4 and characterLabel:find(UnitName("player"),1,true)==1,"eligible list distinguishes scopes and prefixes character owner")
ok(not a:Profile("save","Centre","character"),"duplicate creation cannot silently overwrite an existing profile")
BetterLKFramesCharDB={};a:InitSettings()
list=a:ListProfiles();ok(#list==3,"another character cannot list private profiles")
ok(not a:Profile("load","Centre","character"),"another character cannot select a private profile")
ok(a:Profile("load","Centre","account") and a.db.healthHeight==29,"another character may select account profile")
BetterLKFramesCharDB=characterSave;a:InitSettings()
ok(a:Profile("load","Centre","character") and a.db.healthHeight==28,"original character retains its private profile")
a:RefreshOptions();ok(a.profileSelector.menuText==a:ActiveProfileLabel(),"dropdown displays actual active profile")
local menu=OpenTestMenu(a.profileSelector)
ok(#menu==4,"selection dropdown lists every eligible profile")
local pick
for _,entry in ipairs(menu) do if entry.text=="Legacy (account)" then pick=entry end end
pick.func();ok(BetterLKFramesCharDB.activeProfile.name=="Legacy" and a.db.healthHeight==26,"dropdown selection applies the correct profile")
menu=OpenTestMenu(a.profileScopeMenu);menu[2].func()
a.profileNameEdit:SetText("Via UI")
local created=false
for _,child in ipairs(a.profileNameEdit:GetParent().children) do
    if child:GetText()=="Create" then child:GetScript("OnClick")(child);created=true end
end
ok(created and BetterLKFramesCharDB.activeProfile.scope=="character" and BetterLKFramesCharDB.profiles['Via UI'],"UI creation honours selected character scope")
COMBAT=true;ok(not a:Profile("load","Legacy") and not a:Profile("save","Blocked"),"profile changes blocked during combat")
COMBAT=false
-- #5: active named layout resets without destroying other settings or profiles.
a:Set("auraTimers",true);a:Set("frameScale",1.25);a.db.positions.PlayerFrame={x=600,y=400};a:CommitSettings();a:Apply()
a:Profile("save","Other","character");a:Profile("load","Via UI","character")
local otherPosition=BetterLKFramesCharDB.profiles.Other.positions.PlayerFrame.x
PlayerFrame:Show();a:SetUnlocked(true)
local resetButton
for _,child in ipairs(a.optionsNavigation[2].blkPage.children) do if child:GetText()=="Reset frames" then resetButton=child end end
resetButton:GetScript("OnClick")(resetButton)
ok(LAST_POPUP=="BETTERLKFRAMES_RESET_FRAMES" and a.db.positions.PlayerFrame,"reset requires confirmation before changing layout")
COMBAT=true;ok(not a:ResetFrames() and a.db.positions.PlayerFrame,"combat reset rejected without changing saved layout")
COMBAT=false;StaticPopupDialogs.BETTERLKFRAMES_RESET_FRAMES.OnAccept()
ok(next(a.db.positions)==nil and not a.unlocked and not a.guides:IsShown(),"confirmed reset clears all positions and locks frames")
ok(PlayerFrame:GetPoint(1)=="TOPLEFT" and PlayerFrame.points[1][4]==-19 and PlayerFrame.points[1][5]==-4,"reset restores native player anchor")
ok(TargetFrame.points[1][4]==250 and TargetFrame.points[1][5]==-4 and PartyMemberFrame1.points[1][5]==-160,"reset restores target and party defaults")
ok(PlayerFrame.userPlaced==false and a.db.blizzardLayout,"native position persistence cleared and reset state recorded")
ok(a.db.auraTimers and a.db.frameScale==1.25 and account.profiles.Legacy.healthHeight==26 and
    BetterLKFramesCharDB.profiles.Other.positions.PlayerFrame.x==otherPosition,"reset preserves appearance, aura options and other saved layouts")
a:InitSettings();a:Apply()
ok(next(a.db.positions)==nil and PlayerFrame.points[1][4]==-19,"reset persists across reload initialization")
-- Focus created later must use defaults even if its native user-placed position was cached.
FocusFrame=CreateFrame("Button","FocusFrame",UIParent);FocusFrame.unit="focus";FocusFrame.protected=true
FocusFrame.healthbar=CreateFrame("StatusBar","FocusFrameHealthBar",FocusFrame)
FocusFrame:SetMovable(true) -- Native FocusFrame is movable in 12340 XML.
FocusFrame:SetPoint("CENTER",UIParent,"CENTER",500,300);FocusFrame:SetUserPlaced(true)
a:Apply()
ok(FocusFrame.points[1][4]==250 and FocusFrame.points[1][5]==-240 and not FocusFrame.userPlaced,"late-discovered focus restores native rather than cached custom anchor")
a.db.positions.PlayerFrame={x=777,y=333};a:CommitSettings();a:Apply();a:InitSettings();a:Apply()
ok(PlayerFrame:GetPoint(1)=="BOTTOMLEFT" and a.db.positions.PlayerFrame.x==777,"new movement after reset persists normally")
-- Cover every additional movable-frame family and its native relative anchor chain.
local function optionalFrame(name,parent)
    local frame=CreateFrame("Button",name,parent or UIParent);frame.protected=true
    frame.healthbar=CreateFrame("StatusBar",name.."HealthBar",frame)
    frame:SetPoint("CENTER",UIParent,"CENTER",90,80)
    return frame
end
optionalFrame("PetFrame")
optionalFrame("TargetFrameToT",TargetFrame);optionalFrame("FocusFrameToT",FocusFrame)
for i=1,4 do
    if i>1 then optionalFrame("PartyMemberFrame"..i) end
    CreateFrame("Frame","PartyMemberFrame"..i.."PetFrame",_G["PartyMemberFrame"..i])
    optionalFrame("Boss"..i.."TargetFrame")
end
local arenaParent=CreateFrame("Frame","ArenaEnemyFrames",UIParent)
for i=1,5 do optionalFrame("ArenaEnemyFrame"..i,arenaParent) end
a:Apply()
for name in pairs(a.frames) do a.db.positions[name]={x=700,y=500} end
a:CommitSettings();a:Apply()
local managed=0;UIParent_ManageFramePositions=function() managed=managed+1 end
FocusFrame.smallSize=true;a:ResetFrames()
ok(managed==1,"reset requests Blizzard managed-frame recalculation")
ok(PetFrame.points[1][4]==80 and PetFrame.points[1][5]==-60,"pet resets to native position")
ok(TargetFrameToT.points[1][2]==TargetFrame and TargetFrameToT.points[1][4]==-35,"target-of-target restores native parent relationship")
ok(FocusFrameToT.points[1][2]==FocusFrame and FocusFrameToT.points[1][4]==-13,"focus-target reset respects native small-focus option")
for i=2,4 do
    local f=_G["PartyMemberFrame"..i]
    ok(f.points[1][2]==_G["PartyMemberFrame"..(i-1).."PetFrame"] and f.points[1][4]==-23,"party member resets onto preceding pet anchor "..i)
end
ok(Boss1TargetFrame.points[1][1]=="TOPRIGHT" and Boss1TargetFrame.points[1][4]==55,"first boss restores native base anchor")
for i=2,4 do ok(_G["Boss"..i.."TargetFrame"].points[1][2]==_G["Boss"..(i-1).."TargetFrame"],"boss relative chain restored "..i) end
ok(ArenaEnemyFrame1.points[1][2]==arenaParent and ArenaEnemyFrame1.points[1][4]==-2,"first arena frame restores native parent anchor")
for i=2,5 do ok(_G["ArenaEnemyFrame"..i].points[1][2]==_G["ArenaEnemyFrame"..(i-1)],"arena relative chain restored "..i) end
FocusFrame.smallSize=false;a:ResetFrames()
ok(FocusFrameToT.points[1][4]==-35,"large focus-target offset preserved")
-- Named reset is limited to the selected profile; unnamed legacy resets retain their prior semantics.
a:Reset();ok(a.db.healthHeight==22 and account.profiles.Legacy.healthHeight==26 and BetterLKFramesCharDB.profiles.Other,"named settings reset preserves other profiles")
BetterLKFramesCharDB.activeProfile={scope="character",name="Missing"};a:InitSettings()
ok(BetterLKFramesCharDB.activeProfile==nil,"missing saved selection safely falls back to unnamed settings")
print("TOTAL issues "..n.." assertions passed")
