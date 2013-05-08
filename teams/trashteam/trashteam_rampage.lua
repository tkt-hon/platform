local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function rampage:SkillBuildOverride()
  self:SkillBuildOld()
end
rampage.SkillBuildOld = rampage.SkillBuild
rampage.SkillBuild = rampage.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function rampage:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
rampage.onthinkOld = rampage.onthink
rampage.onthink = rampage.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride
