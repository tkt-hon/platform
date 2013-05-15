local _G = getfenv(0)
local forsaken_archer = _G.object

forsaken_archer.heroName = "Hero_ForsakenArcher"

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function forsaken_archer:SkillBuildOverride()
  self:SkillBuildOld()
end
forsaken_archer.SkillBuildOld = forsaken_archer.SkillBuild
forsaken_archer.SkillBuild = forsaken_archer.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function forsaken_archer:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
forsaken_archer.onthinkOld = forsaken_archer.onthink
forsaken_archer.onthink = forsaken_archer.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function forsaken_archer:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
forsaken_archer.oncombateventOld = forsaken_archer.oncombatevent
forsaken_archer.oncombatevent = forsaken_archer.oncombateventOverride
