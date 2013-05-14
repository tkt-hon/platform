local _G = getfenv(0)
local witchslayer = _G.object

witchslayer.heroName = "Hero_WitchSlayer"
runfile 'bots/core_herobot.lua'

local core, behaviorLib = witchslayer.core, witchslayer.behaviorLib
--------------------------------------------------------------
-- Itembuild --
--------------------------------------------------------------

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_PretendersCrown", "2 Item_ManaPotion" }
behaviorLib.LaneItems = { "Item_Strength5", "Item_Intelligence5", "Item_Replenish", "Item_Marchers", "Item_MysticPotpourri", "Item_Astrolabe" }
behaviorLib.MidItems = { }
behaviorLib.LateItems = { "Item_Intelligence7", "Item_Protect" }

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

witchslayer.skills = {}
local skills = witchslayer.skills

---------------------------------------------------------------
-- Selitys buildin takana: Nuke ja Hex ovat skillit joilla   --
-- hoidetana frägit, manaskilliä otetaan yksi jotta voidaan  --
-- estää tarvittaessa nullstonen käyttö (jos vastustajalla   --
-- on null stone, aloitetaan manaskillillä). Ulti finishaa   --
---------------------------------------------------------------

witchslayer.tSkills = {
  0, 1, 0, 1, 0,
  3, 0, 1, 1, 2,
  3, 4, 4, 4, 4,
  3, 4, 4, 4, 4,
  4, 4, 2, 2, 2
}

function witchslayer:SkillBuildOverride()
local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilHex = unitSelf:GetAbility(1)
    skills.abilMana = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
witchslayer.SkillBuildOld = witchslayer.SkillBuild
witchslayer.SkillBuild = witchslayer.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function witchslayer:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
witchslayer.onthinkOld = witchslayer.onthink
witchslayer.onthink = witchslayer.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function witchslayer:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
witchslayer.oncombateventOld = witchslayer.oncombatevent
witchslayer.oncombatevent = witchslayer.oncombateventOverride
