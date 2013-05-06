local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Rampa_Rami"

runfile 'bots/core_herobot.lua'
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = rampage.core, rampage.behaviorLib

local tinsert = _G.table.insert

behaviorLib.StartingItems = { "Item_Marchers", "Item_RunesOfTheBlight", "Item_LoggersHatchet" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Lifetube", "Item_ManaBattery" }
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_PowerSupply", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }

local CHARGE_NONE, CHARGE_STARTED, CHARGE_TIMER, CHARGE_WARP = 0, 1, 2, 3

rampage.charged = CHARGE_NONE

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
rampage.skills = {}
local skills = rampage.skills

rampage.tSkills = {
  2, 0, 0, 1, 2,
  3, 0, 2, 2, 2,
  3, 0, 0, 2, 4,
  4, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
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

----------------------------------
--  FindItems Override
----------------------------------

---------------------------------------
--	Ability use management variables --
---------------------------------------
object.nStampedeUp = 10
object.nMightUp = 12
object.nHornedUp = 35
object.nChainsUp = 12

object.nStampedeUse = 15
object.nMightUse = 18
object.nHornedUse = 55
object.nChainsUse = 18

object.nStampedeThreshold = 20
object.nMightThreshold = 10
object.nHornedThreshold = 60
object.nChainsThreshold = 10

----------------------------------
-- CustomHarassUtility Override	--
----------------------------------
-- @param: IunitEntity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
	local nUtil = 0

	if skills.abilQ:CanActivate() then
		nUtil = nUtil + object.nStampedeUp
	end

	if skills.abilW:CanActivate() then
		nUtil = nUtil + object.nMightUp
	end

	if skills.abilR:CanActivate() then
		nUtil = nUtil + object.nHornedUp
	end

	return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

	local nAddBonus = 0

		if EventData.Type == "Ability" then
			if EventData.InflictorName == "Ability_Rampage0" then
				nAddBonus = nAddBonus + object.nStampedeUse
			elseif EventData.InflictorName == "Ability_Rampage1" then
				nAddBonus = nAddBonus + object.nMightUse
			elseif EventData.InflictorName == "Ability_Rampage2" then
				nAddBonus = nAddBonus + object.nHornedUse
			end
		if nAddBonus > 0 then
			core.DecayBonus(self)
			core.nHarassBonus = core.nHarassBonus + nAddBonus
		end
	end
end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride

