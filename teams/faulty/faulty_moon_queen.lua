local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/faulty/bottle_behavior.lua'

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib
local tinsert, format = _G.table.insert, _G.string.format
local BotEcho = core.BotEcho

BotEcho("loading faulty_moon_queen.lua")

behaviorLib.StartingItems = { "Item_Bottle" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Soulscream 3" }
behaviorLib.MidItems = { "Item_PostHaste" }
behaviorLib.LateItems = { "Item_Evasion", "Item_Intelligence7" }

-- http://honwiki.net/wiki/Moon_Queen:Hit_R_to_Win
-- desired skillbuild order
-- 0 = Q(Moon Beam)
-- 1 = W(Multi-strike)
-- 2 = E(Lunar glow)
-- 3 = R(Moon Finale)
-- 4 = Attribute boost
moonqueen.tSkills = {
  0, 4, 3, 4, 0,
  3, 3, 0, 0, 2,
  2, 2, 4, 4, 4,
  2, 4, 4, 4, 4,
  4, 4, 4, 4, 4,
}

moonqueen.skills = {}
local skills = moonqueen.skills

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function moonqueen:SkillBuildOverride()
	local unitSelf = self.core.unitSelf
	if skills.abilNuke == nil then
		skills.abilNuke     = unitSelf:GetAbility(0)
		skills.abilBounce   = unitSelf:GetAbility(1)
		skills.abilAura     = unitSelf:GetAbility(2)
		skills.abilUltimate = unitSelf:GetAbility(3)
		skills.stats        = unitSelf:GetAbility(4)
	end
	moonqueen:SkillBuildOld()
end
moonqueen.SkillBuildOld = moonqueen.SkillBuild
moonqueen.SkillBuild = moonqueen.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function moonqueen:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)

	-- custom code here
end
moonqueen.onthinkOld = moonqueen.onthink
moonqueen.onthink = moonqueen.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function moonqueen:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)

	-- custom code here
end
-- override combat event trigger function.
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride

--------------------------------------------------------------------------------
-- CUSTOM HARASS BEHAVIOR
--
-- Utility: Overrides ability/item threath, return 0-100 based on usable skills and items
--          Utility also decides which action to take depending on circumstances.
--
-- Execute: Just executes the action from moonqueen.doHarass array

-- Base skill usable bonuses
local nNukeUp     = 10
local nBounceUp   = 0 -- do no use for nao
local nUltimateUp = 30

-- Creep count modifiers
local nNukeCreepMod     = 0
local nBounceCreepMod   = 0
local nUltimateCreepMod = -10 -- this is if greater than 2

-- level bonus for the skill
local nSkillLevelBonus = 10

-- enemy weakened bonuses, attack more if enemy is weaker.
local nEnemyNoMana = 20
local nEnemyNoHealth = 20

moonqueen.doHarass = {}
-- moonqueen.doHarass["target"] = nil
-- moonqueen.doHarass["skill"]  = nil
-- moonqueen.doHarass["item"]   = nil

-- functions returns integer value representing hero state.
local function HeroStateValue(hero, nNoManaVal, nNoHealthVal)
	local nHealthPercent = hero:GetHealthPercent()
	local nManaPercent   = hero:GetManaPercent()

	local nRet = 0
	if nHealthPercent ~= nil then
		nRet = nRet + (1 - nHealthPercent) * nNoHealthVal
	end
	if nManaPercent ~= nil then
		nRet = nRet + (1 - nManaPercent) * nNoManaVal
	end
	return nRet
end

-- Returns the number of nearby creeps in given radius
local function NearbyCreepCountUtility(botBrain, center, radius)
	local count = 0
	local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
	local enemies = unitsLocal.EnemyCreeps
	for _,unit in pairs(enemies) do
		count = count + 1
	end
	return count
end

local function CustomHarassUtilityFnOverride(hero)
	moonqueen.doHarass = {} -- reset
	local unitSelf = core.unitSelf

	local heroPos = hero:GetPosition()
	local selfPos = unitSelf:GetPosition()

	local ultimateVal = 0
	local nukeVal     = 0
	local bounceVal   = 0

	local nRet = 0
	local nMe = HeroStateValue(unitSelf, nEnemyNoMana, nEnemyNoHealth)
	local nEnemy = HeroStateValue(hero, nEnemyNoMana, nEnemyNoHealth)
	nRet = (nRet + nEnemy - nMe)

	local canSee = core.CanSeeUnit(moonqueen, hero)
	local targetDistanceSq = Vector3.Distance2DSq(selfPos, heroPos)
	local nukeRangeSq      = skills.abilNuke:GetRange() * skills.abilNuke:GetRange()

	if skills.abilUltimate:CanActivate() and targetDistanceSq < (700 * 700) then
		local creeps = NearbyCreepCountUtility(moonqueen, selfPos, 700)
		ultimateVal = nUltimateUp
		if creeps > 2 then
			ultimateVal = ultimateVal + creeps * nUltimateCreepMod
		end
		ultimateVal = ultimateVal + skills.abilUltimate:GetLevel() * nSkillLevelBonus
	end

	if skills.abilNuke:CanActivate() and canSee and targetDistanceSq < nukeRangeSq then
		local creeps = NearbyCreepCountUtility(moonqueen, heropos, 400)
		nukeVal = nNukeUp + creeps * nNukeCreepMod
		nukeVal = nukeVal + skills.abilNuke:GetLevel() * nSkillLevelBonus
	end

	--if skills.abilBounce:CanActivate() then
	--	local creeps = NearbyCreepCountUtility(moonqueen, heropos, 500)
	--	bounceVal = nBounceUp + creeps * nBounceCreepMod
	--	bounceVal = bounceVal + skills.abilBounce:GetLevel() * nSkillLevelBonus
	--end

	if ultimateVal == 0 and nukeVal == 0 and bounceVal == 0 then
		return nRet
	end

	local doUltimate = false
	local doNuke     = false
	local doBounce   = false

	-- determine highest
	if ultimateVal > nukeVal then
		if ultimateVal > bounceVal then
			doUltimate = true
		else
			doBounce = true
		end
	else
		if nukeVal > bounceVal then
			doNuke = true
		else
			doBounce = true
		end
	end

	moonqueen.doHarass["target"] = hero

	if doUltimate then
		moonqueen.doHarass["skill"] = skills.abilUltimate
		nRet = nRet + ultimateVal
	end

	if doNuke then
		moonqueen.doHarass["skill"] = skills.abilNuke
		nRet = nRet + nukeVal
	end

	if doBounce then
		moonqueen.doHarass["skill"] = skills.abilBounce
		nRet = nRet + bounceVal
	end

	BotEcho(format("  CustomHarassUtil: nuke: %g, bounce: %g, ultimate: %g", nukeVal, bounceVal, ultimateVal))

	return nRet
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

--------------------------------------------------------------------------------
-- Overridden harass/attack function.
--
--------------------------------------------------------------------------------
local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = moonqueen.doHarass["target"]
	local skill = moonqueen.doHarass["skill"]
	if unitTarget == nil or skill == nil or not skill:CanActivate() then
		return moonqueen.harassExecuteOld(botBrain)
	end

	local unitSelf = core.unitSelf
	-- distance to target squared
	local targetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
	local bActionTaken = false

	if skill:GetName() == "Ability_Krixi1" then
		if core.CanSeeUnit(botBrain, unitTarget) then
			local range = skill:GetRange()
			if targetDistanceSq < (range * range) then
				BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
				bActionTaken = core.OrderAbilityEntity(botBrain, skill, unitTarget)
			end
		end
	elseif skill:GetName() == "Ability_Krixi2" then
		BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
		bActionTaken = core.OrderAbilityEntity(botBrain, skill, unitTarget)
	elseif skill:GetName() == "Ability_Krixi4" then
		BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
		bActionTaken = core.OrderAbility(botBrain, skill)
	else
		BotEcho(format("  HarassHeroExecute: INVALID SKILL %s", skill:GetName()))
	end

	if not bActionTaken then
		return moonqueen.harassExecuteOld(botBrain)
	end
end
moonqueen.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


--------------------------------------------------------------------------------
-- FindItems Override
--
local function funcFindItemsOverride(botBrain)
	local bUpdated = moonqueen.FindItemsOld(botBrain)

	if core.itemBottle ~= nil and not core.itemBottle:IsValid() then
		core.itemBottle = nil
	end

	if bUpdated then
		-- only update if we need to
		if core.itemBottle then
			return
		end

		local inventory = core.unitSelf:GetInventory(true)
		for slot = 1, 12, 1 do
			local curItem = inventory[slot]
			if curItem then
				if curItem:GetName() == "Item_Bottle" then
					core.itemBottle = core.WrapInTable(curItem)
					return
				end
			end
		end
	end
end

moonqueen.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

--------------------------------------------------------------------------------

BotEcho("finished loading faulty_moon_queen.lua")
