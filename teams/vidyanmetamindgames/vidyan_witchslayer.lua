local _G = getfenv(0)
local witchslayer = _G.object

witchslayer.heroName = "Hero_WitchSlayer"

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none
function witchslayer:SkillBuildOverride()
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
tempest.oncombatevent = tempest.oncombateventOverride