local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/faulty/lib/utils.lua'

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib
local tinsert, format = _G.table.insert, _G.string.format
local BotEcho = core.BotEcho

BotEcho("loading faulty_plague_rider.lua")

behaviorLib.StartingItems = { "Item_MinorTotem 2", "Item_RunesOfTheBlight", "Item_TrinketOfRestoration" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Strength5", "Item_PowerSupply", "Item_Astrolabe" }
behaviorLib.MidItems = { "Item_PostHaste" }
behaviorLib.LateItems = { "Item_Morph" }

-- http://forums.heroesofnewerth.com/showthread.php?24393-Plague-Rider-guide
-- desired skillbuild order
-- 0 = Q(Contagion)
-- 1 = W(Cursed Shield)
-- 2 = E(Extinguish)
-- 3 = R(Plague Carrier)
-- 4 = Attribute boost
plaguerider.tSkills = {
  0, 0, 2, 2, 0,
  3, 0, 2, 2, 1,
  3, 4, 4, 4, 4,
  3, 2, 2, 2, 4,
  4, 4, 4, 4, 4
}

plaguerider.skills = {}
local skills = plaguerider.skills

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function plaguerider:SkillBuildOverride()
	local unitSelf = self.core.unitSelf
	if skills.abilContagion == nil then
		skills.abilContagion  = unitSelf:GetAbility(0)
		skills.abilShield     = unitSelf:GetAbility(1)
		skills.abilExtinguish = unitSelf:GetAbility(2)
		skills.abilPlague     = unitSelf:GetAbility(3)
		skills.abilStats      = unitSelf:GetAbility(4)
	end
	plaguerider:SkillBuildOld()
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function plaguerider:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)

	-- custom code here
end
plaguerider.onthinkOld = plaguerider.onthink
plaguerider.onthink = plaguerider.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)

	-- custom code here
end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride


--------------------------------------------------------------------------------
-- CUSTOM HARASS BEHAVIOR
--
-- Utility: 
--
-- Execute: 

-- 0 = Q(Contagion)
-- 1 = W(Cursed Shield)
-- 2 = E(Extinguish)
-- 3 = R(Plague Carrier)
-- 4 = Attribute boost

-- skill bases
local nContagionUp = 30
local nPlagueUp    = 15

-- creep amount modifier
local nContagionCreepMod = 0 -- single target
local nPlagueCreepMod    = 10 

-- enemy weakened bonuses, attack more if enemy is weaker.
local nEnemyNoMana = 20
local nEnemyNoHealth = 20

-- level bonuses depending of the skill level
local nSkillLevelBonus = 5

plaguerider.doHarass = {}

local function CustomHarassUtilityFnOverride(hero)
	plaguerider.doHarass = {} -- reset
	local unitSelf = core.unitSelf

	local heroPos = hero:GetPosition()
	local selfPos = unitSelf:GetPosition()

	local nRet = 0
	local nMe = HeroStateValueUtility(unitSelf, nEnemyNoMana, nEnemyNoHealth)
	local nEnemy = HeroStateValueUtility(hero, nEnemyNoMana, nEnemyNoHealth)
	nRet = (nRet + nEnemy - nMe)

	local bCanSee = core.CanSeeUnit(plaguerider, hero)

	local nContagionVal = nRet
	local nPlagueVal = nRet

	if skills.abilContagion:CanActivate() and bCanSee then
		local nRange = skills.abilContagion:GetRange()
		local targetDistanceSq = Vector3.Distance2DSq(selfPos, heroPos)

		if targetDistanceSq < (nRange * nRange) then
			nContagionVal = nContagionVal + nContagionUp + skills.abilContagion:GetLevel() * nSkillLevelBonus
		end
	end

	if skills.abilPlague:CanActivate() and bCanSee then
		local nRange = skills.abilContagion:GetRange()
		local targetDistanceSq = Vector3.Distance2DSq(selfPos, heroPos)

		if targetDistanceSq < (nRange * nRange) then
			local creeps = NearbyEnemyCreepCountUtility(plaguerider, heroPos, 600)
			nPlagueVal = nPlagueVal + nPlagueUp + skills.abilContagion:GetLevel() * nSkillLevelBonus + creeps * nPlagueCreepMod
		end
	end

	if nContagionVal > nRet or nPlagueVal > nRet then
		plaguerider.doHarass["target"] = hero
		BotEcho(format("  CustomHarass; Contagion: %g, Plague: %g", nContagionVal, nPlagueVal))
	end

	if nPlagueVal > nContagionVal then
		plaguerider.doHarass["skill"] = skills.abilPlague
	else
		plaguerider.doHarass["skill"] = skills.abilContagion
	end

	return math.max(nPlagueVal, nContagionVal)
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = plaguerider.doHarass["target"]
	local skill = plaguerider.doHarass["skill"]
	if unitTarget == nil or skill == nil or not skill:CanActivate() then
		return plaguerider.harassExecuteOld(botBrain)
	end

	local unitSelf = core.unitSelf
	local targetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
	local bActionTaken = false

	if core.CanSeeUnit(botBrain, unitTarget) then
		local range = skill:GetRange()
		if targetDistanceSq < (range * range) then
			BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
			bActionTaken = core.OrderAbilityEntity(botBrain, skill, unitTarget)
		end
	end

	if not bActionTaken then
		return plaguerider.harassExecuteOld(botBrain)
	end
end
plaguerider.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTINGUISH BEHAVIOR - Will consume creeps to restore mana.
--

local nBaseExtinguishUp = 20

local nManaThreshold = 0.7
local nManaLostBonus = 20

local nExtinguishSkillLevelBonus = 3

plaguerider.doExtinguish = {}
--plaguerider.doExtinguish["target"] = nil

function behaviorLib.ExtinguishUtility(botBrain)
	plaguerider.doExtinguish = {}

	if core.GetCurrentBehaviorName(botBrain) == "HealAtWell" then
		-- don't consume if going to well
		return 0
	end

	local unitSelf = core.unitSelf

	local nManaPercent = unitSelf:GetManaPercent()

	if nManaPercent < nManaThreshold and skills.abilExtinguish:CanActivate() then
		local unitsLocal = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 800)

		local target = nil
		local maxHealth = 0
		local count = 0

		-- find target
		for _,creep in pairs(unitsLocal.AllyCreeps) do
			if creep:GetHealthPercent() > maxHealth then
				target = creep
				maxHealth = creep:GetHealthPercent()
			end

			count = count + 1
		end

		if count == 0 then
			return 0
		end

		plaguerider.doExtinguish["target"] = target

		local nValue = nBaseExtinguishUp + (1 - nManaPercent) * nManaLostBonus
		nValue = nValue + skills.abilExtinguish:GetLevel() * nExtinguishSkillLevelBonus
		BotEcho(format("  ExtinguishUtility: ret: %g", nValue))
		return nValue
	end

	return 0
end

function behaviorLib.ExtinguishExecute(botBrain)
	local target = plaguerider.doExtinguish["target"]
	if target then
		if skills.abilExtinguish:CanActivate() then
			BotEcho("  ExtinguishExecuted!")
			core.OrderAbilityEntity(botBrain, skills.abilExtinguish, target)
		end
	else
		BotEcho("  ExtinguishExecute: INVALID TARGET!")
	end
end

behaviorLib.ExtinguishBehavior = {}
behaviorLib.ExtinguishBehavior["Utility"] = behaviorLib.ExtinguishUtility
behaviorLib.ExtinguishBehavior["Execute"] = behaviorLib.ExtinguishExecute
behaviorLib.ExtinguishBehavior["Name"] = "Extinguish"
tinsert(behaviorLib.tBehaviors, behaviorLib.ExtinguishBehavior)
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Overridden retreat from threat utilty => avoids towers
--
local function RetreatFromThreatUtilityOverride(botBrain)
	if core.GetClosestEnemyTower(core.unitSelf:GetPosition(), 730) then
		return 120
	end

	return behaviorLib.RetreatFromThreatUtility(botBrain)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = RetreatFromThreatUtilityOverride
--------------------------------------------------------------------------------

BotEcho("finished loading faulty_plague_rider.lua")
