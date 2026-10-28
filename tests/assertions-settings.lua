local a=BetterLKFrames
local n=0
local function ok(v,name) assert(v,name);n=n+1;print("PASS settings "..name) end
local function act(page,title)
 for _,c in ipairs(page.children or {}) do if c:GetText()==title then return c:GetScript("OnClick") end end
 error("Missing action: "..title)
end
local function selectMenu(menu,name)
 for _,entry in ipairs(OpenTestMenu(menu)) do if entry.text==name then entry.func();return end end
 error("Missing menu entry: "..name)
end
local function isEsc()
 local count=0;for _,v in ipairs(UISpecialFrames) do if v=="BetterLKFramesOptions" then count=count+1 end end
 return count
end
local function login(db,char)
 BetterLKFramesDB=db;BetterLKFramesCharDB=char;a:InitSettings();a:Apply()
end
login(nil,nil);a:BuildOptions();a:ShowStandaloneOptions()
local original=a.options;local selector=a.profileSelector;local edit=a.profileNameEdit
local appearance=a.optionsPages[1];local profilePage=a.optionsPages[4]
ok(original:GetParent()==UIParent and original:IsVisible() and isEsc()==1,"#17 standalone uses original settings tree and one Escape entry")
ok(#a.optionsNavigation==4 and original.selectedTab==1,"#16 four native tabs initialise on Appearance")
for i,tab in ipairs(a.optionsNavigation) do
 ok(tab.template=="OptionsFrameTabButtonTemplate" and tab:GetID()==i and tab:GetWidth()==tab:GetTextWidth()+24 and not tab:GetNormalTexture(),"#16 compact native tab with stable identity "..i)
 tab:GetScript("OnClick")()
 ok(original.selectedTab==i and a.optionsPages[i]:IsShown(),"#16 selection switches to page "..i)
end
for _,title in ipairs({"Use account","Copy to character","Resume character","Character: defaults","Character: Blizzard","Reset active scope"}) do
 local found=false;for _,c in ipairs(profilePage.children or {}) do if c:GetText()==title then found=true end end
 ok(not found,"#15 removed redundant legacy control: "..title)
end
local initial=a:ListProfiles();ok(#initial==1 and initial[1].scope=="default","#15 only-default configuration remains valid/selectable")
ok(#OpenTestMenu(a.profileDeleteMenu)==0,"#15 protected Default excluded from deletion candidates")
ok(a:PrepareProfileAction("delete",{scope="default"})==nil,"#15 backend rejects deleting Default")
-- Create through UI and keep Default's independent settings.
a:Set("healthHeight",25);a.profileNameEdit:SetText("Account A");act(profilePage,"Create")()
ok(edit:GetText()=="" and a:ActiveProfileRef().name=="Account A" and a.db.healthHeight==25,"#15 account creation clears field and selects copied settings")
a:Set("healthHeight",28)
a:Profile("load",nil,"default")
ok(a.db.healthHeight==25,"#15 Default values preserved after named edits")
edit:SetText("Account A");act(profilePage,"Create")()
ok(edit:GetText()=="Account A" and a:ActiveProfileRef().scope=="default","#15 duplicate inactive name preserves input and active identity")
OpenTestMenu(a.profileScopeMenu)[2].func();edit:SetText("Private A");act(profilePage,"Create")()
a:Set("healthHeight",29)
ok(a:ActiveProfileRef().scope=="character" and edit:GetText()=="","#15 private creation retains scope and clears input")
-- Copy selects a candidate only; Cancel cannot overwrite current settings.
selectMenu(a.profileCopyMenu,"Account A (account)")
local dialog=LAST_DIALOG
ok(dialog.which=="BETTERLKFRAMES_PROFILE_COPY" and dialog.arg1=="Account A (account)" and a.db.healthHeight==29,"#15 copy confirmation names source and leaves data unchanged until Accept")
ClickTestPopup(dialog,2)
ok(a.db.healthHeight==29 and dialog.data.used,"#15 cancelling copy is harmless and invalidates request")
selectMenu(a.profileCopyMenu,"Account A (account)");dialog=LAST_DIALOG;ClickTestPopup(dialog,1)
ok(a.db.healthHeight==28 and a:ActiveProfileRef().name=="Private A" and a:ActiveProfileRef().scope=="character","#15 copy overwrites current settings while retaining target identity")
ok(a.accountDB.profiles['Account A'].healthHeight==28 and a.accountDB.healthHeight==25,"#15 copy preserves source and Default")
-- Reset selected profile, including protected Default, without erasing libraries.
act(profilePage,"Reset Profile")();dialog=LAST_DIALOG
ok(dialog.which=="BETTERLKFRAMES_PROFILE_RESET" and dialog.arg1:find('Private A',1,true),"#15 reset confirmation identifies selected profile")
ClickTestPopup(dialog,2);ok(a.db.healthHeight==28,"#15 reset Cancel preserves settings")
act(profilePage,"Reset Profile")();ClickTestPopup(LAST_DIALOG,1)
ok(a.db.healthHeight==22 and BetterLKFramesCharDB.profiles['Private A'] and a.accountDB.profiles['Account A'],"#15 reset retains selected profile and other libraries")
a:Profile("load",nil,"default");act(profilePage,"Reset Profile")();ClickTestPopup(LAST_DIALOG,1)
ok(a.db.healthHeight==22 and a.accountDB.profiles['Account A'] and BetterLKFramesCharDB.profiles['Private A'],"#15 Default reset preserves every named profile")
-- Inactive deletion leaves selection; active deletion falls back to actual Default values.
a:Set("healthHeight",24);a:Profile("load","Private A","character")
selectMenu(a.profileDeleteMenu,"Account A (account)");dialog=LAST_DIALOG
ok(dialog.arg1=="Account A (account)" and a.accountDB.profiles['Account A'],"#15 selecting delete candidate only opens named confirmation")
ClickTestPopup(dialog,2);ok(a.accountDB.profiles['Account A'],"#15 delete Cancel preserves candidate")
selectMenu(a.profileDeleteMenu,"Account A (account)");ClickTestPopup(LAST_DIALOG,1)
ok(not a.accountDB.profiles['Account A'] and a:ActiveProfileRef().name=="Private A","#15 inactive deletion does not switch current profile")
selectMenu(a.profileDeleteMenu,a:ProfileLabel("Private A","character"));dialog=LAST_DIALOG;ClickTestPopup(dialog,1);ClickTestPopup(dialog,1)
ok(not BetterLKFramesCharDB.profiles['Private A'] and a:ActiveProfileRef().scope=="default" and a.db.healthHeight==24,"#15 active deletion switches once to preserved Default")
ok(#a:ListProfiles()==1 and a.accountDB==a.db,"#15 at least protected Default remains after last named deletion")
-- Stale dialogs cannot act on replacements, another target or another character.
a:Profile("save","Stale A","account");a:Profile("save","Stale B","account")
local req=a:PrepareProfileAction("delete",{scope="account",name="Stale A"})
a.accountDB.profiles['Stale A']=a.Copy(a.defaults)
ok(not a:ConfirmProfileAction(req) and a.accountDB.profiles['Stale A'],"#15 stale deletion cannot delete a replacement with the same name")
req=a:PrepareProfileAction("reset");a:Profile("load",nil,"default")
ok(not a:ConfirmProfileAction(req) and a.accountDB.profiles['Stale B'],"#15 stale reset cannot affect a newly selected profile")
req=a:PrepareProfileAction("copy",{scope="account",name="Stale A"});a:Profile("load","Stale B","account")
ok(not a:ConfirmProfileAction(req),"#15 stale copy cannot overwrite another active target")
req=a:PrepareProfileAction("delete",{scope="account",name="Stale A"});COMBAT=true
ok(not a:ConfirmProfileAction(req) and a.accountDB.profiles['Stale A'],"#15 combat confirmation cannot delete settings")
COMBAT=false
req=a:PrepareProfileAction("delete",{scope="account",name="Stale A"})
local originalChar=BetterLKFramesCharDB;BetterLKFramesCharDB={};a:InitSettings()
ok(not a:ConfirmProfileAction(req) and a.accountDB.profiles['Stale A'],"#15 stale dialog cannot cross character contexts")
BetterLKFramesCharDB=originalChar;a:InitSettings()
-- Old local settings remain a selectable, scoped profile without destructive migration.
local savedAccount=a.accountDB
BetterLKFramesCharDB={useCharacter=true,settings={healthHeight=27,frameScale=1.3}}
a:InitSettings();a:Apply();local legacy=BetterLKFramesCharDB.settings
local legacyLabel=a:ProfileRefLabel({scope="legacy-character"})
ok(a.db==legacy and a.db.healthHeight==27 and a:ActiveProfileRef().scope=="legacy-character","#15 legacy character configuration remains active without data loss")
selectMenu(a.profileSelector,"Default (account-wide)")
ok(a.db==savedAccount and BetterLKFramesCharDB.settings==legacy,"#15 switching Default preserves legacy character settings")
selectMenu(a.profileSelector,legacyLabel)
ok(a.db==legacy and a.db.frameScale==1.3,"#15 legacy settings selectable through the simplified UI")
act(profilePage,"Reset Profile")();ClickTestPopup(LAST_DIALOG,1)
ok(a.db.healthHeight==22 and BetterLKFramesCharDB.settings==a.db and a.accountDB.profiles['Stale A'],"#15 reset legacy settings preserves account library")
selectMenu(a.profileDeleteMenu,legacyLabel);ClickTestPopup(LAST_DIALOG,1)
ok(not BetterLKFramesCharDB.settings and a:ActiveProfileRef().scope=="default","#15 deleting active legacy entry falls back safely")
-- Private entries remain isolated from other characters, and operations survive initialization.
a:Profile("save","Saved private","character");a:Set("healthHeight",26)
local char=BetterLKFramesCharDB;a:InitSettings();a:Apply()
ok(a:ActiveProfileRef().name=="Saved private" and a.db.healthHeight==26,"#15 selection and copied/reset/deleted state survive reload initialization")
BetterLKFramesCharDB={};a:InitSettings()
local privateFound=false;for _,entry in ipairs(a:ListProfiles()) do if entry.scope=="character" then privateFound=true end end
ok(not privateFound and not a:Profile("load","Saved private","character"),"#15 another character cannot select private profiles")
BetterLKFramesCharDB=char;a:InitSettings();a:Apply()
-- Embedded and standalone show the very same controls/state, and never duplicate them.
a:ShowStandaloneOptions();a:SelectOptionsPage(2);a.profileNameEdit:SetText("Unsaved input")
OpenTestCategory()
ok(a.options==original and a.profileSelector==selector and a.profileNameEdit==edit,"#17 both hosts reuse the exact same control instances")
ok(a.optionsContext=="embedded" and original:GetParent()==a.optionsScrollChild and original:IsVisible(),"#17 category displays real embedded controls")
ok(not original:IsMovable() and not a.optionsClose:IsShown() and isEsc()==0 and not original.backdrop,"#17 embedded content has no standalone drag/close/Escape shell")
ok(a.optionsScroll.template=="UIPanelScrollFrameTemplate" and a.optionsScroll.scrollChild==a.optionsScrollChild,"#17 native scroll viewport owns shared content")
ok(original:GetScale()==622/640 and a.optionsScrollChild:GetHeight()==610*(622/640),"#17 width fit keeps full content scrollable instead of shrinking vertically")
original:GetScript("OnDragStart")(original);ok(not original.moving,"#17 dragging embedded content cannot move the category")
a:Set("healthHeight",30);a:SelectOptionsPage(4)
selectMenu(a.profileSelector,"Default (account-wide)")
ok(a:ActiveProfileRef().scope=="default" and a.optionsContext=="embedded","#17 embedded profile selection applies without switching hosts")
a:Set("healthHeight",28);a.optionsScroll:SetVerticalScroll(50)
a.optionsNavigation[3]:GetScript("OnClick")()
ok(original.selectedTab==3 and a.optionsScroll:GetVerticalScroll()==0,"#16 embedded tab switch resets scrolling and selection")
a:SetTestAuras(true);a:OpenOptions()
ok(a.optionsContext=="standalone" and original:GetParent()==UIParent and original:IsVisible() and not InterfaceOptionsFrame:IsShown(),"#17 slash transition hides native frame and restores unobscured standalone settings")
ok(not a.testAuras and a.profileNameEdit:GetText()=="Unsaved input" and a.db.healthHeight==28,"#17 transition cleans previews but preserves profile/state and typed text")
ok(original:GetScale()==1 and original:IsMovable() and a.optionsClose:IsShown() and original.backdrop and isEsc()==1,"#17 standalone chrome/scale/Escape restored once")
a:OpenOptions();ok(not original:IsShown(),"#17 standalone slash command retains toggle behaviour")
OpenTestCategory();a:SelectOptionsPage(2)
act(a.optionsPages[2],"Unlock frames")()
ok(a.unlocked and not InterfaceOptionsFrame:IsShown() and not original:IsShown(),"#17 embedded unlock closes native host for usable frame movement")
CloseTestSpecialWindows();a.scripts.OnUpdate(a,.01)
ok(not a.unlocked and original:IsVisible() and a.optionsContext=="standalone" and original.selectedTab==2,"#17 Escape after embedded unlock returns to standalone Frames tab")
for i=1,3 do OpenTestCategory();a:ShowStandaloneOptions() end
ok(a.options==original and isEsc()==1 and a.profileSelector==selector,"#17 repeated transitions never duplicate settings or Escape registration")
OpenTestCategory();a.optionsScroll.width=500;a.optionsScroll:GetScript("OnSizeChanged")()
ok(original:GetScale()==500/640,"#17 embedded resize refits width")
HideUIPanel(InterfaceOptionsFrame)
ok(not original:IsShown() and not a.testAuras,"#17 closing native host cleans the shared view")
a:InitSettings();a:ShowStandaloneOptions()
ok(a.db.healthHeight==28 and original.selectedTab==2,"#17 settings persist and current tab remains coherent after reinitialization")
print("TOTAL settings "..n.." assertions passed")
