local _G = getfenv(0)
local witch_slayer = _G.object

witch_slayer.heroName = "Hero_WitchSlayer"

runfile 'bots/core_herobot.lua'

witch_slayer.skills = {}
local skills = witch_slayer.skills

witch_slayer.tSkills = {
  0, 1, 0, 2, 0,
  3, 0, 1, 1, 1,
  3, 2, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function witch_slayer:SkillBuildOverride()
  self:SkillBuildOld()
end
witch_slayer.SkillBuildOld = witch_slayer.SkillBuild
witch_slayer.SkillBuild = witch_slayer.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function witch_slayer:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
witch_slayer.onthinkOld = witch_slayer.onthink
witch_slayer.onthink = witch_slayer.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function witch_slayer:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
witch_slayer.oncombateventOld = witch_slayer.oncombatevent
witch_slayer.oncombatevent = witch_slayer.oncombateventOverride
