local _G = getfenv(0)
local yogi = _G.object

yogi.heroName = "Hero_Yogi"
local core, behaviorLib = yogi.core, yogi.behaviorLib

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none

yogi.skills = {}
local skills = yogi.skills

-----------------------------------------------------------------
-- Selitys buildin takana: Nallen maksimointi alkuun, tällöin  --
-- saadaan nallesta kestävä ja damagea tekevä, sekä skillit.   --
-- Passiivinen skilli lvl 2 alkuun, jolloin Wild (buffi) pysyy --
-- jatkuvasti yllä, 30sec cd ja 30sec kestävä buffi. Ultimate  --
-- pidetään jatkuvasti toggletettuna kestävyyden lisäämiseksi  --
-----------------------------------------------------------------

yogi.tSkills = {
  0, 2, 0, 2, 0,
  3, 0, 1, 1, 1,
  3, 1, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function yogi:SkillBuildOverride()
 local unitSelf = self.core.unitSelf
  if skills.abilBear == nil then
    skills.abilBear = unitSelf:GetAbility(0)
    skills.abilBuff = unitSelf:GetAbility(1)
    skills.abilPassive = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
yogi.SkillBuildOld = yogi.SkillBuild
yogi.SkillBuild = yogi.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function yogi:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
yogi.onthinkOld = yogi.onthink
yogi.onthink = yogi.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function yogi:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
yogi.oncombateventOld = yogi.oncombatevent
tempest.oncombatevent = tempest.oncombateventOverride
