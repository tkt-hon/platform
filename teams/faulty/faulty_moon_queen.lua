local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib
local tinsert, format = _G.table.insert, _G.string.format
local BotEcho = core.BotEcho

BotEcho("loading faulty_moon_queen.lua")

behaviorLib.StartingItems = { "Item_Bottle", "Item_MinorTotem 2" }
behaviorLib.LaneItems = { "Item_Soulscream", "Item_Marchers", "Item_Soulscream 3" }
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
  0, 4, 0, 4, 0,
  3, 0, 2, 2, 2,
  3, 2, 1, 1, 1,
  3, 1, 4, 4, 4,
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

	BotEcho("EVENT! Type: " .. EventData.Type)
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
local nNukeUp     = 50
local nBounceUp   = 40
local nUltimateUp = 65

-- Creep count modifiers
local nNukeCreepMod     = 1
local nBounceCreepMod   = 8
local nUltimateCreepMod = -5

-- level bonus for the skill
local nSkillLevelBonus = 2

-- negative mana mod, if 0 mana, -10
local nManaMod = 10

moonqueen.doHarass = {}
-- moonqueen.doHarass["target"] = nil
-- moonqueen.doHarass["skill"]  = nil
-- moonqueen.doHarass["item"]   = nil

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
	--[[
	local nUtil = 0

	if skills.abilNuke:CanActivate() then
		nUtil = nUtil + 5*skills.abilNuke:GetLevel()
	end

	local heroPos = hero:GetPosition()
	local queryRadius = 700

	local creeps = NearbyCreepCount(moonqueen, heroPos, queryRadius)

	core.DrawDebugArrow(heroPos, heroPos + Vector3.Create( queryRadius, 0), 'white')
	core.DrawDebugArrow(heroPos, heroPos + Vector3.Create(-queryRadius, 0), 'white')
	core.DrawDebugArrow(heroPos, heroPos + Vector3.Create(0, -queryRadius), 'white')
	core.DrawDebugArrow(heroPos, heroPos + Vector3.Create(0,  queryRadius), 'white')

	if skills.abilUltimate:CanActivate() and creeps < 3 then
		nUtil = nUtil + 100
	end

	return nUtil
	]]--

	moonqueen.doHarass = {} -- reset
	local unitSelf = core.unitSelf

	local heroPos = hero:GetPosition()

	local ultimateVal = 0
	local nukeVal     = 0
	local bounceVal   = 0

	local canSee = core.CanSeeUnit(moonqueen, hero)
	local targetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), heroPos)
	local ultimateRangeSq  = skills.abilUltimate:GetRange() * skills.abilUltimate:GetRange()
	local nukeRangeSq      = skills.abilNuke:GetRange() * skills.abilNuke:GetRange()
	local bounceRangeSq    = skills.abilBounce:GetRange() * skills.abilBounce:GetRange()

	if skills.abilUltimate:CanActivate() and canSee and targetDistanceSq < ultimateRangeSq then
		local creeps = NearbyCreepCountUtility(moonqueen, heropos, 700)
		ultimateVal = nUltimateUp + creeps * nUltimateCreepMod
		ultimateVal = ultimateVal + skills.abilUltimate:GetLevel() * nSkillLevelBonus
	end

	if skills.abilNuke:CanActivate() and canSee and targetDistanceSq < nukeRangeSq then
		local creeps = NearbyCreepCountUtility(moonqueen, heropos, 400)
		nukeVal = nNukeUp + creeps * nNukeCreepMod
		nukeVal = nukeVal + skills.abilNuke:GetLevel() * nSkillLevelBonus
	end

	if skills.abilBounce:CanActivate() and canSee and targetDistanceSq < bounceRangeSq then
		local creeps = NearbyCreepCountUtility(moonqueen, heropos, 500)
		bounceVal = nBounceUp + creeps * nBounceCreepMod
		bounceVal = bounceVal + skills.abilBounce:GetLevel() * nSkillLevelBonus
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

	local ret = 0

	moonqueen.doHarass["target"] = hero

	if doUltimate then
		moonqueen.doHarass["skill"] = skills.abilUltimate
		ret = ultimateVal
	end

	if doNuke then
		moonqueen.doHarass["skill"] = skills.abilNuke
		ret = nukeVal
	end

	if doBounce then
		moonqueen.doHarass["skill"] = skills.abilBounce
		ret = bounceVal
	end

	return ret - ((1 - unitSelf:GetManaPercent()) * nManaMod)
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

--------------------------------------------------------------------------------
-- Overridden harass/attack function.
--
--------------------------------------------------------------------------------
local function HarassHeroExecuteOverride(botBrain)
	--[[
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil then
		return moonqueen.harassExecuteOld(botBrain)
	end

	local unitSelf = core.unitSelf
	-- distance to target squared
	local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
	local bActionTaken = false

	local abilNuke = skills.abilNuke
	if core.CanSeeUnit(botBrain, unitTarget) then
		if abilNuke:CanActivate() then
			local nRange = abilNuke:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
			end
		end
	end

	if not bActionTaken then
		return moonqueen.harassExecuteOld(botBrain)
	end
	]]--

	local unitTarget = moonqueen.doHarass["target"]
	if unitTarget == nil then
		BotEcho("  HarassHeroExecute: INVALID TARGET!")
		return moonqueen.harassExecuteOld(botBrain)
	end

	local unitSelf = core.unitSelf
	-- distance to target squared
	local targetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
	local bActionTaken = false

	if core.CanSeeUnit(botBrain, unitTarget) then
		local skill = moonqueen.doHarass["skill"]
		if skill:CanActivate() then
			local range = skill:GetRange()
			if targetDistanceSq < (range * range) then
				BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
				bActionTaken = core.OrderAbilityEntity(botBrain, skill, unitTarget)
			end
		end
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


--------------------------------------------------------------------------------
-- HEAL BEHAVIOR - Currently only heals self
--
-- Utility: 0 if health greater than healThreshold value, or item unusable
--          else: (1 - healthPercent) * healVar
--             e.g. assume healVar is 45, and health at given percent
--               0.7: 13.5
--               0.5: 22.5
--               0.3: 31.5
--               0.2: 36
moonqueen.doHeal = {}
--moonqueen.doHeal["target"] = nil
--moonqueen.doHeal["skill"]  = nil
--moonqueen.doHeal["item"]   = nil

local healThreshold = 0.7 -- heals when health below this %
local healVar = 45        -- just some magic value
                          -- higher it is, more likely to heal

function behaviorLib.HealUtility(botBrain)
	moonqueen.doHeal = {} -- reset

	if core.GetCurrentBehaviorName(botBrain) == "HealAtWell" then
		-- don't heal if going to well.
		return 0
	end

	core.FindItems()
	local itemBottle = core.itemBottle

	if itemBottle and itemBottle:CanActivate() and itemBottle:GetActiveModifierKey() ~= "bottle_empty" then
		local unitSelf = core.unitSelf
		local healthPercent = unitSelf:GetHealthPercent()
		local healthLow = (healthPercent < healThreshold)

		if healthLow then
			moonqueen.doHeal["target"] = unitSelf
			moonqueen.doHeal["item"]   = itemBottle
			local ret = (1 - healthPercent) * healVar
			BotEcho(format("  HealUtility: %g", ret))
			return ret
		end

	end

	return 0
end

function behaviorLib.HealExecute(botBrain)
	if moonqueen.doHeal["target"] then
		local target = moonqueen.doHeal["target"]
		if moonqueen.doHeal["item"] then
			local item = moonqueen.doHeal["item"]
			BotEcho(format("  HealExecute, Healing with %s", item:GetName()))
			core.OrderItemClamp(botBrain, target, item)
		elseif moonqueen.doHeal["skill"] then
			-- TODO
		end

		return true
	else
		BotEcho("  HealExecute: INVALID TARGET!")
	end

	return false
end

behaviorLib.HealBehavior = {}
behaviorLib.HealBehavior["Utility"] = behaviorLib.HealUtility
behaviorLib.HealBehavior["Execute"] = behaviorLib.HealExecute
behaviorLib.HealBehavior["Name"] = "Heal"
tinsert(behaviorLib.tBehaviors, behaviorLib.HealBehavior)
--------------------------------------------------------------------------------

BotEcho("finished loading faulty_moon_queen.lua")
