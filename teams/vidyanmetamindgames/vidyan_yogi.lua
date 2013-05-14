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
function yogi:SkillBuildOverride()
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
