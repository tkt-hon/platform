local _G = getfenv(0)
local voodoo = _G.object

voodoo.heroName = "Hero_Voodoo"

runfile 'bots/core_herobot.lua'

---------------------------------------------------------------
-- SkillBuild override --
-- Handles hero skill building. To customize just write own --
---------------------------------------------------------------
-- @param: none
-- @return: none
function voodoo:SkillBuildOverride()
  self:SkillBuildOld()
end
voodoo.SkillBuildOld = voodoo.SkillBuild
voodoo.SkillBuild = voodoo.SkillBuildOverride

------------------------------------------------------
-- onthink override --
-- Called every bot tick, custom onthink code here --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function voodoo:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
voodoo.onthinkOld = voodoo.onthink
voodoo.onthink = voodoo.onthinkOverride

----------------------------------------------
-- oncombatevent override --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function voodoo:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
voodoo.oncombateventOld = voodoo.oncombatevent
tempest.oncombatevent = tempest.oncombateventOverride