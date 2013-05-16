local _G = getfenv(0)
local magmus = _G.object

magmus.heroName = "Hero_Magmar"

runfile 'bots/core_herobot.lua'

magmus.skills = {}
local skills = magmus.skills

magmus.tSkills = {
  1, 0, 1, 0, 4,
  3, 1, 0, 1, 0,
  3, 2, 4, 2, 4,
  3, 2, 4, 2, 4,
  4, 4, 4, 4, 4
}


---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function magmus:SkillBuildOverride()
  self:SkillBuildOld()
end
magmus.SkillBuildOld = magmus.SkillBuild
magmus.SkillBuild = magmus.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function magmus:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
magmus.onthinkOld = magmus.onthink
magmus.onthink = magmus.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function magmus:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
magmus.oncombateventOld = magmus.oncombatevent
magmus.oncombatevent = magmus.oncombateventOverride
