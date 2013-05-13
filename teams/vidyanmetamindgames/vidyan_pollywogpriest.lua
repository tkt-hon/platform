local _G = getfenv(0)
local pollywogpriest = _G.object

pollywogpriest.heroName = "Hero_PollywogPriest"

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none
function pollywogpriest:SkillBuildOverride()
  self:SkillBuildOld()
end
pollywogpriest.SkillBuildOld = pollywogpriest.SkillBuild
pollywogpriest.SkillBuild = pollywogpriest.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function pollywogpriest:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
pollywogpriest.onthinkOld = pollywogpriest.onthink
pollywogpriest.onthink = pollywogpriest.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function pollywogpriest:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
pollywogpriest.oncombateventOld = pollywogpriest.oncombatevent
tempest.oncombatevent = tempest.oncombateventOverride