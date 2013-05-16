local _G = getfenv(0)
local flint_beastwood = _G.object

flint_beastwood.heroName = "Hero_FlintBeastwood"

runfile 'bots/teams/drop-table-bots/droptable-herobot.lua'

flint_beastwood.skills = {}
local skills = flint_beastwood.skills

flint_beaswood.tSkills = {
  2, 0, 4, 2, 0,
  3, 2, 4, 4, 0,
  3, 1, 1, 1, 2,
  3, 0, 1, 4, 4,
  4, 4, 4, 4, 4
}


---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function flint_beastwood:SkillBuildOverride()
  self:SkillBuildOld()
end
flint_beastwood.SkillBuildOld = flint_beastwood.SkillBuild
flint_beastwood.SkillBuild = flint_beastwood.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function flint_beastwood:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
flint_beastwood.onthinkOld = flint_beastwood.onthink
flint_beastwood.onthink = flint_beastwood.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function flint_beastwood:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
flint_beastwood.oncombateventOld = flint_beastwood.oncombatevent
flint_beastwood.oncombatevent = flint_beastwood.oncombateventOverride
