-- Explicit Lua 5.1 WoW API mock. Geometry operations on protected frames fail in combat.
COMBAT=false; NOW=100; CREATIONS=0
local methods={}
local function geometry(self) if COMBAT and self.protected then error("protected geometry in combat") end end
function methods:GetName() return self.name end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:HookScript(event,fn)
 local old=self.scripts[event];self.scripts[event]=function(...) if old then old(...) end;fn(...) end
end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:GetAlpha() return self.alpha end
function methods:SetAlpha(a) self.alpha=a end
function methods:SetVertexColor(...) self.colour={...} end
function methods:GetVertexColor() return unpack(self.colour or {1,1,1,1}) end
function methods:GetTextColor() return unpack(self.colour or {1,1,1,1}) end
function methods:SetTextColor(...) self.colour={...} end
function methods:SetText(t) self.text=t end
function methods:GetText() return self.text or "" end
function methods:SetFont(...) self.font={...} end
function methods:SetPoint(...) geometry(self);self.points[#self.points+1]={...} end
function methods:ClearAllPoints() geometry(self);self.points={} end
function methods:GetNumPoints() return #self.points end
function methods:GetPoint(i) if self.points[i] then return unpack(self.points[i]) end end
function methods:SetAllPoints(f) geometry(self);self.allPoints=f end
function methods:SetWidth(x) geometry(self);self.width=x end
function methods:SetHeight(x) geometry(self);self.height=x end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(x) geometry(self);self.scale=x end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale end
function methods:GetLeft() return self.left or 120 end
function methods:GetBottom() return self.bottom or 240 end
function methods:SetFrameLevel(x) self.level=x end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameStrata(x) self.strata=x end
function methods:SetBackdrop(x) self.backdrop=x end
function methods:SetBackdropColor(...) self.backdropColour={...} end
function methods:SetBackdropBorderColor(...) self.borderColour={...} end
function methods:GetBackdropColor() return unpack(self.backdropColour or {1,1,1,1}) end
function methods:GetBackdropBorderColor() return unpack(self.borderColour or {1,1,1,1}) end
function methods:EnableMouse(x) self.mouse=x end
function methods:SetStatusBarTexture(x) self.texture=x end
function methods:SetStatusBarColor(...) self.barColour={...} end
function methods:SetMinMaxValues(a,b) self.min,self.max=a,b end
function methods:SetValue(x) self.value=x;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,x) end end
function methods:GetValue() return self.value end
function methods:SetValueStep(x) self.step=x end
function methods:GetFont() return unpack(self.font or {STANDARD_TEXT_FONT,11,"OUTLINE"}) end
function methods:SetJustifyV(x) self.justifyV=x end
function methods:GetParent() return self.parent end
function methods:GetRegions() return unpack(self.regions or {}) end
function methods:GetChildren() return unpack(self.children or {}) end
function methods:GetObjectType() return self.kind end
function methods:GetTexture() return self.texture end
function methods:GetTexCoord()
 local c=self.texCoords or {0,0,0,1,1,0,1,1}
 if #c==4 then return c[1],c[3],c[1],c[4],c[2],c[3],c[2],c[4] end
 return unpack(c)
end
function methods:GetPushedTexture() return self.pushedTexture end
function methods:SetJustifyH(x) self.justify=x end
function methods:SetMovable(x) geometry(self);self.movable=x end
function methods:StartMoving() geometry(self);self.moving=true end
function methods:StopMovingOrSizing() geometry(self);self.moving=false end
function methods:RegisterForDrag(...) self.drag={...} end
function methods:Show() local was=self.shown;self.shown=true;if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self.shown=false;if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsShown() return self.shown end
function methods:SetTexture(x) self.texture=x end
function methods:SetTexCoord(...) self.texCoords={...} end
function methods:SetCooldown(a,b) self.cooldown={a,b};self.cooldownCalls=(self.cooldownCalls or 0)+1 end
function methods:GetID() return self.id or 0 end
function methods:SetID(id) self.id=id end
function methods:SetChecked(x) self.checked=x end
function methods:GetChecked() return self.checked end
function methods:SetAutoFocus(x) self.autoFocus=x end
function methods:SetMaxLetters(x) self.maxLetters=x end
function methods:ClearFocus() self.focus=false end
function methods:GetNormalTexture() return self.normalTexture end
function methods:CreateTexture(name,layer) local t=CreateFrame("Texture",name,self);t.layer=layer;return t end
function methods:CreateFontString(name,layer) return CreateFrame("FontString",name,self) end
function CreateFrame(kind,name,parent,template)
 CREATIONS=CREATIONS+1
 local f=setmetatable({kind=kind,name=name,parent=parent,scripts={},events={},alpha=1,scale=1,
 width=119,height=12,level=1,shown=true,points={}}, {__index=methods})
 if name then _G[name]=f end
 if parent then
  local key=(kind=="Texture" or kind=="FontString") and "regions" or "children"
  parent[key]=parent[key] or {};table.insert(parent[key],f)
 end
 if template=="UIPanelButtonTemplate" then f.normalTexture=CreateFrame("Texture",nil,f) end
 if template=="UICheckButtonTemplate" then CreateFrame("FontString",name.."Text",f) end
 if template=="OptionsSliderTemplate" then
  for _,s in ipairs({"Low","High","Text"}) do CreateFrame("FontString",name..s,f) end
 end
 return f
end
UIParent=CreateFrame("Frame","UIParent")
STANDARD_TEXT_FONT="Fonts\\FRIZQT__.TTF";DEAD="Dead";ACCEPT="Accept";CANCEL="Cancel"
SlashCmdList={};UISpecialFrames={};StaticPopupDialogs={}
DEFAULT_CHAT_FRAME={messages={},AddMessage=function(self,m) self.messages[#self.messages+1]=m end}
function StaticPopup_Show(key) LAST_POPUP=key end
function InterfaceOptions_AddCategory(f) OPTIONS_CATEGORY=f end
function InCombatLockdown() return COMBAT end
function GetTime() return NOW end
function GetSpellInfo(id) if id==123 then return "Test aura" end end
RAID_CLASS_COLORS={WARRIOR={r=.78,g=.61,b=.43},MAGE={r=.41,g=.8,b=.94}}
CLASS_ICON_TCOORDS={WARRIOR={0,.25,0,.25},MAGE={.25,.5,0,.25}}
PowerBarColor={[0]={r=0,g=0,b=1},MANA={r=0,g=0,b=1}}
UNITS={player={hp=800,maxhp=1000,mana=250,maxmana=500,player=true,class="MAGE"},
 target={hp=200,maxhp=400,mana=20,maxmana=100,player=true,class="WARRIOR"},
 party1={hp=400,maxhp=500,mana=70,maxmana=100,player=true,class="MAGE"}}
function UnitExists(u) return UNITS[u]~=nil end
function UnitIsPlayer(u) return UNITS[u] and UNITS[u].player end
function UnitClass(u) return "Class",UNITS[u] and UNITS[u].class end
function UnitHealth(u) return UNITS[u] and UNITS[u].hp or 0 end
function UnitHealthMax(u) return UNITS[u] and UNITS[u].maxhp or 0 end
function UnitMana(u) return UNITS[u] and UNITS[u].mana or 0 end
function UnitManaMax(u) return UNITS[u] and UNITS[u].maxmana or 0 end
function UnitPowerType() return 0,"MANA" end
function UnitIsDeadOrGhost(u) return UNITS[u] and UNITS[u].dead end
function UnitSelectionColor() return .1,.8,.1 end
function SetPortraitTexture(t,u) t.texture="portrait:"..u end
CASTS={};CHANNELS={};BUFFS={};DEBUFFS={}
function UnitCastingInfo(u) if CASTS[u] then return unpack(CASTS[u],1,9) end end
function UnitChannelInfo(u) if CHANNELS[u] then return unpack(CHANNELS[u],1,8) end end
function UnitBuff(u,i) if BUFFS[u] and BUFFS[u][i] then return unpack(BUFFS[u][i],1,11) end end
function UnitDebuff(u,i) if DEBUFFS[u] and DEBUFFS[u][i] then return unpack(DEBUFFS[u][i],1,11) end end
function UnitFramePortrait_Update() end
function PlayerFrame_UpdateArt() end
function TargetFrame_CheckClassification() end
HOOKS={}
function hooksecurefunc(name,fn) HOOKS[name]=fn end
local function unitFrame(name,unit)
 local f=CreateFrame("Button",name,UIParent);f.unit=unit;f.protected=true;f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20)
 f.healthbar=CreateFrame("StatusBar",name.."HealthBar",f)
 f.manabar=CreateFrame("StatusBar",name.."ManaBar",f)
 f.name=CreateFrame("FontString",name.."Name",f)
 f.portrait=CreateFrame("Texture",name.."Portrait",f)
 CreateFrame("FontString",name.."TextureFrameHealthBarText",f)
 CreateFrame("FontString",name.."TextureFrameManaBarText",f)
 return f
end
unitFrame("PlayerFrame","player");unitFrame("TargetFrame","target");unitFrame("PartyMemberFrame1","party1")
PlayerPortrait=PlayerFrame.portrait;PlayerName=PlayerFrame.name
for _,n in ipairs({"PlayerFrameTexture","TargetFrameTextureFrameTexture","MainMenuBarTexture0","MinimapBorder"}) do CreateFrame("Texture",n,UIParent) end
CastingBarFrame=CreateFrame("StatusBar","CastingBarFrame",UIParent);CastingBarFrame.unit="player";CastingBarFrame.scale=.8;CastingBarFrame.protected=true
TargetFrameSpellBar=CreateFrame("StatusBar","TargetFrameSpellBar",TargetFrame);TargetFrameSpellBar.unit="target"
GameTooltip=CreateFrame("Frame","GameTooltip",UIParent)
BuffButton1=CreateFrame("Button","BuffButton1",UIParent);BuffButton1.id=1;BuffButton1.duration=CreateFrame("FontString",nil,BuffButton1)
TargetFrameBuff1=CreateFrame("Button","TargetFrameBuff1",TargetFrame);TargetFrameBuff1.id=1
TargetFrameBuff1Cooldown=CreateFrame("Cooldown","TargetFrameBuff1Cooldown",TargetFrameBuff1)

PlayerPVPIcon=CreateFrame("Texture","PlayerPVPIcon",PlayerFrame)

UIParent.width=1920;UIParent.height=1080
function UnitName(u) return u and ("Name "..u) end
SHIFT=false
function IsShiftKeyDown() return SHIFT end
TargetFrame.nameBackground=CreateFrame("Texture","TargetFrameNameBackground",TargetFrame)
for _,name in ipairs({"ActionButton1","MultiBarRightButton1","CharacterBag0Slot","MainMenuBarBackpackButton","CharacterMicroButton","TempEnchant1"}) do
 local f=CreateFrame("CheckButton",name,UIParent);f.normalTexture=CreateFrame("Texture",name.."NormalTexture",f)
 f.protected=true
end

CastingBarFrameText=CreateFrame("FontString","CastingBarFrameText",CastingBarFrame)
CastingBarFrameText:SetFont(STANDARD_TEXT_FONT,12,"OUTLINE");CastingBarFrame.Text=CastingBarFrameText
function TargetFrame_UpdateAuras() end
QuestLogFrame=CreateFrame("Frame","QuestLogFrame",UIParent)
local questArt=QuestLogFrame:CreateTexture("TestQuestBorder","ARTWORK")
questArt:SetTexture("Interface\\QuestFrame\\UI-QuestLogDualPane-Left");questArt:SetWidth(512);questArt:SetHeight(512)
TestQuestIcon=QuestLogFrame:CreateTexture("TestQuestIcon","ARTWORK");TestQuestIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_01")
WorldMapFrame=CreateFrame("Frame","WorldMapFrame",UIParent)
WorldMapDetailTile1=WorldMapFrame:CreateTexture("WorldMapDetailTile1","ARTWORK");WorldMapDetailTile1:SetTexture("Interface\\WorldMap\\Elwynn\\Elwynn1")
WorldMapFrameTexture1=WorldMapFrame:CreateTexture("WorldMapFrameTexture1","ARTWORK");WorldMapFrameTexture1:SetTexture("Interface\\WorldMap\\UI-WorldMap-Top1")
TargetFrameDebuff1=CreateFrame("Button","TargetFrameDebuff1",TargetFrame);TargetFrameDebuff1:SetPoint("TOPLEFT",TargetFrame,"BOTTOMLEFT",5,2)
