local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = rampage.core, rampage.behaviorLib
local tinsert, format = _G.table.insert, _G.string.format
local BotEcho = core.BotEcho

BotEcho("loading faulty_rampage.lua")

behaviorLib.StartingItems = { "Item_IronBuckler", "Item_MinorTotem 3", "Item_RunesOfTheBlight", "Item_HealthPotion" }
behaviorLib.LaneItems = { "Item_Warhammer", "Item_MightyBlade" }
behaviorLib.MidItems = { "Item_Immunity", "Item_Steamboots" }
behaviorLib.LateItems = { "Item_FrostfieldPlate" }

local CHARGE_NONE, CHARGE_STARTED, CHARGE_TIMER, CHARGE_WARP = 0, 1, 2, 3
rampage.charged = CHARGE_NONE


-- http://www.gamereplays.org/heroesofnewerth/portals.php?show=page&name=Heroes-ofnewerth-Rampage-Guide&st=1
-- Desired skill build
-- 0 = Q(Stampede)
-- 1 = W(Might of the Herd)
-- 2 = E(Horned Strike)
-- 3 = R(The Chains that Bind)
-- 4 = Attribute boost
rampage.tSkills = {
  2, 0, 1, 2, 2,
  0, 2, 3, 0, 0,
  1, 1, 1, 2, 4,
  4, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

rampage.skills = {}
local skills = rampage.skills

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function rampage:SkillBuildOverride()
	local unitSelf = self.core.unitSelf
	if skills.abilStampede == nil then
		skills.abilStampede = unitSelf:GetAbility(0)
		skills.abilMight    = unitSelf:GetAbility(1)
		skills.abilHorned   = unitSelf:GetAbility(2)
		skills.abilChains   = unitSelf:GetAbility(3)
		skills.stats        = unitSelf:GetAbility(4)
	end
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

	if EventData.Type == "Ability" and EventData.InflictorName == "Ability_Rampage1" then
		self.charged = CHARGE_STARTED
	elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Timer" then
		if self.charged == CHARGE_STARTED then
			self.charged = CHARGE_NONE
		end
	elseif EventData.Type == "State" and EventData.StateName == "State_Rampage_Ability1_Warp" then
		self.charged = CHARGE_WARP
	elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Warp" then
		self.charged = CHARGE_NONE
	elseif EventData.Type == "Death" then
		self.charged = CHARGE_NONE
	end

	-- custom code here
end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride


--------------------------------------------------------------------------------
-- CUSTOM HARASS BEHAVIOR
--
-- Utility: 
--
-- Execute: 

-- Base skills usable bonuses
local nStampede = 10

-- enemy weakened bonuses, attack more if enemy is weaker.
local nEnemyNoMana = 20
local nEnemyNoHealth = 20

-- level bonus for the skill
local nSkillLevelBonus = 5

rampage.doHarass = {}

local function NearbyCreepCountUtility(botBrain, center, radius)
	local count = 0
	local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
	local enemies = unitsLocal.EnemyCreeps
	for _,unit in pairs(enemies) do
		count = count + 1
	end
	return count
end

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

local function CustomHarassUtilityFnOverride(hero)
	rampage.doHarass = {} -- reset
	local unitSelf = core.unitSelf

	local heroPos = hero:GetPosition()
	local selfPos = unitSelf:GetPosition()

	local nTargetDistanceSq = Vector3.Distance2DSq(selfPos, heroPos)

	local nRet = 0
	local nMe = HeroStateValue(unitSelf, nEnemyNoMana, nEnemyNoHealth)
	local nEnemy = HeroStateValue(hero, nEnemyNoMana, nEnemyNoHealth)
	nRet = (nRet + nEnemy - nMe)

	local bCanSee = core.CanSeeUnit(rampage, hero)

	if skills.abilChains:CanActivate() and bCanSee then
		local nRange = skills.abilChains:GetRange()
		if nTargetDistanceSq < (nRange * nRange) then
			rampage.doHarass["target"] = hero
			rampage.doHarass["skill"]  = skills.abilChains
			nRet = nRet + nStampede + skills.abilChains:GetLevel() * nSkillLevelBonus
			BotEcho(format("  CustomHarass, Chains!: %g", nRet))
		end
	end

	return nRet
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = rampage.doHarass["target"]
	local skill = rampage.doHarass["skill"]
	if unitTarget == nil or skill == nil or not skill:CanActivate() then
		return rampage.harassExecuteOld(botBrain)
	end

	BotEcho(format("  HarassHeroExecute with %s", skill:GetName()))
	local bActionTaken = core.OrderAbilityEntity(botBrain, skill, unitTarget)

	if not bActiontaken then
		return rampage.harassExecuteOld(botBrain)
	end
end
rampage.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- CHARGE BEHAVIOR
--

local ChargeBehavior = {}

local function ChargeTarget(botBrain, unitSelf, abilCharge)
	local tEnemyHeroes = HoN.GetHeroes(core.enemyTeam)
	local utility = 0
	local unitTarget = nil
	local nTarget = 0
	for nUID, unit in pairs(tEnemyHeroes) do
		if core.CanSeeUnit(botBrain, unit) and unit:IsAlive() and (not unitTarget or unit:GetHealth() < unitTarget:GetHealth()) then
			unitTarget = unit
			nTarget = nUID
		end
	end
	if unitTarget then
		local damageLevels = {100,140,180,220}
		local chargeDamage = damageLevels[abilCharge:GetLevel()]
		local estimatedHP = unitTarget:GetHealth() - chargeDamage
		if estimatedHP < 200 then
			utility = 20
		end
		if unitTarget:GetManaPercent() < 30 then
			utility = utility + 5
		end
		local level = unitTarget:GetLevel()
		local ownLevel = unitSelf:GetLevel()
		if level < ownLevel then
			utility = utility + 5 * (ownLevel - level)
		else
			utility = utility - 10 * (ownLevel - level)
		end
		local vecTarget = unitTarget:GetPosition()
		for nUID, unit in pairs(tEnemyHeroes) do
			if nUID ~= nTarget and core.CanSeeUnit(botBrain, unit) and Vector3.Distance2DSq(vecTarget, unit:GetPosition()) < (500 * 500) then
				utility = utility - 5
			end
		end
	end
	return unitTarget, utility
end

local function ChargeUtility(botBrain)
	local abilStampede = skills.abilStampede
	local unitSelf = core.unitSelf
	if rampage.charged ~= CHARGE_NONE then
		return 9999
	end
	if not abilStampede:CanActivate() then
		return 0
	end
	local unitTarget, utility = ChargeTarget(botBrain, unitSelf, abilStampede)
	if unitTarget then
		rampage.chargeTarget = unitTarget
		return utility
	end
	return 0
end

local function ChargeExecute(botBrain)
	local bActionTaken = false
	if botBrain.charged ~= CHARGE_NONE then
		return true
	end
	if not rampage.chargeTarget then
		return false
	end
	local abilStampede = skills.abilStampede
	if abilStampede:CanActivate() then
		BotEcho("ChargeExecute IMMA CHARGING!")
		bActionTaken = core.OrderAbilityEntity(botBrain, abilStampede, rampage.chargeTarget)
	end
	return bActionTaken
end

ChargeBehavior["Utility"] = ChargeUtility
ChargeBehavior["Execute"] = ChargeExecute
ChargeBehavior["Name"] = "Charge like a boss"
tinsert(behaviorLib.tBehaviors, ChargeBehavior)
--------------------------------------------------------------------------------

BotEcho("finished loading faulty_rampage.lua")
