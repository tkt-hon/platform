local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_Item_MinorTotem", "Item_RunesOfTheBlight", "Item_RunesOfTheBlight",  }
behaviorLib.LaneItems = { "Item_Marchers", "Item_ManaBattery", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_Striders", "Item_SpellShards", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower", "Item_RestorationStone" }

plaguerider.skills = {}
local skills = plaguerider.skills

local tinsert = _G.table.insert

core.itemWard = nil

plaguerider.tSkills = {
  2, 0, 0, 2, 0,
  3, 0, 4, 2, 3,
  3, 4, 2, 2, 4,
  3, 2, 4, 4, 4,
  3, 4, 4, 4, 4
}
function plaguerider:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilDeny == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilShield = unitSelf:GetAbility(1)
    skills.abilDeny = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function plaguerider:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
plaguerider.onthinkOld = plaguerider.onthink
plaguerider.onthink = plaguerider.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride
