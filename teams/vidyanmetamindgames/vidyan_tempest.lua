local _G = getfenv(0)
local tempest = _G.object

tempest.heroName = "Hero_Tempest"

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none
function tempest:SkillBuildOverride()
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