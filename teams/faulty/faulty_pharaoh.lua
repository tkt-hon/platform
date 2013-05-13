local _G = getfenv(0)
local pharaoh = _G.object

pharaoh.heroName = "Hero_Mumra"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = pharaoh.core, pharaoh.behaviorLib
local tinsert, format = _G.table.insert, _G.string.format
local BotEcho = core.BotEcho

BotEcho("loading faulty_pharaoh.lua")

pharaoh.skills = {}
local skills = pharaoh.skills

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function pharaoh:SkillBuildOverride()
	self:SkillBuildOld()
end
pharaoh.SkillBuildOld = pharaoh.SkillBuild
pharaoh.SkillBuild = pharaoh.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function pharaoh:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)

	-- custom code here
end
pharaoh.onthinkOld = pharaoh.onthink
pharaoh.onthink = pharaoh.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function pharaoh:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)

	-- custom code here
end
pharaoh.oncombateventOld = pharaoh.oncombatevent
pharaoh.oncombatevent = pharaoh.oncombateventOverride


BotEcho("finished loading faulty_pharaoh.lua")
