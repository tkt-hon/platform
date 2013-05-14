local _G = getfenv(0)
local voodoo = _G.object

voodoo.heroName = "Hero_Voodoo"

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

voodoo.skills = {}
local skills = voodoo.skills

voodoo.tSkills = {
  0, 2, 0, 2, 0,
  3, 0, 2, 2, 1,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function voodoo:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilStun == nil then
    skills.abilStun = unitSelf:GetAbility(0)
    skills.abilMojo = unitSelf:GetAbility(1)
    skills.abilDebuff = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
voodoo.SkillBuildOld = voodoo.SkillBuild
voodoo.SkillBuild = voodoo.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function voodoo:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
voodoo.onthinkOld = voodoo.onthink
voodoo.onthink = voodoo.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function voodoo:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
voodoo.oncombateventOld = voodoo.oncombatevent
tempest.oncombatevent = tempest.oncombateventOverride
