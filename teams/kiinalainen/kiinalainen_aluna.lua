local _G = getfenv(0)
local aluna = _G.object

aluna.heroName = "Hero_Aluna"

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function aluna:SkillBuildOverride()
  aluna:SkillBuildOld()
end
aluna.SkillBuildOld = aluna.SkillBuild
aluna.SkillBuild = aluna.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function aluna:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
aluna.onthinkOld = aluna.onthink
aluna.onthink = aluna.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function aluna:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
aluna.oncombateventOld = aluna.oncombatevent
aluna.oncombatevent = aluna.oncombateventOverride
