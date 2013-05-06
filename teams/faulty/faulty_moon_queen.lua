local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib
local BotEcho = core.BotEcho

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
-- Returns the number of nearby creeps in given radius
--
--------------------------------------------------------------------------------
local function NearbyCreepCount(botBrain, center, radius)
	local count = 0
	local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
	local enemies = unitsLocal.EnemyCreeps
	for _,unit in pairs(enemies) do
		count = count + 1
	end
	return count
end

--------------------------------------------------------------------------------
-- Returns the number of nearby creeps in given radius
--
--------------------------------------------------------------------------------
local function CustomHarassUtilityFnOverride(hero)
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
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

--------------------------------------------------------------------------------
-- Overridden harass/attack function.
--
--------------------------------------------------------------------------------
local function HarassHeroExecuteOverride(botBrain)
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
end
moonqueen.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
