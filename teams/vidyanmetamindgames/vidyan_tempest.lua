local _G = getfenv(0)
local tempest = _G.object

tempest.heroName = "Hero_Tempest"
local core, behaviorLib = tempest.core, tempest.behaviorLib

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

tempest.skills = {}
local skills = tempest.skills

tempest.tSkills = {
  0, 1, 1, 0, 1,
  3, 1, 0, 0, 4,
  3, 4, 4, 4, 4,
  3, 4, 4, 4, 4,
  4, 2, 2, 2, 2
}

function tempest:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilStun == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilMinions = unitSelf:GetAbility(1)
    skills.abilAoe = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
tempest.SkillBuildOld = tempest.SkillBuild
tempest.SkillBuild = tempest.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function tempest:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
tempest.onthinkOld = tempest.onthink
tempest.onthink = tempest.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function tempest:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
tempest.oncombateventOld = tempest.oncombatevent
tempest.oncombatevent = tempest.oncombateventOverride
