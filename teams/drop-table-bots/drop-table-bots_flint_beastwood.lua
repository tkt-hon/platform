local _G = getfenv(0)
local flint_beastwood = _G.object

flint_beastwood.heroName = "Hero_FlintBeastwood"

runfile 'bots/teams/drop-table-bots/droptable-herobot.lua'
runfile 'bots/teams/drop-table-bots/libhon.lua'
local core, behaviorLib = flint_beastwood.core, flint_beastwood.behaviorLib

flint_beastwood.skills = {}
local skills = flint_beastwood.skills

flint_beastwood.tSkills = {
  2, 0, 4, 2, 0,
  3, 2, 4, 4, 0,
  3, 1, 1, 1, 2,
  3, 0, 1, 4, 4,
  4, 4, 4, 4, 4
}
object.behaviorLib.nCreepPushbackMul = 0.4 -- Stay closer to creep wave, default 1



---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function flint_beastwood:SkillBuildOverride()
    local unitSelf = self.core.unitSelf
    if skills.flare == nil then
        skills.flare		= unitSelf:GetAbility(0)
        skills.hollowpoint	= unitSelf:GetAbility(1)
        skills.deadeye		= unitSelf:GetAbility(2)
        skills.abilUlti	= unitSelf:GetAbility(3)
        skills.attributeBoost = unitSelf:GetAbility(4)
    end
    self:SkillBuildOld()
end
flint_beastwood.SkillBuildOld = flint_beastwood.SkillBuild
flint_beastwood.SkillBuild = flint_beastwood.SkillBuildOverride

---------------------------------------------------------------
--            Harass utility override                        --
---------------------------------------------------------------
-- @param: hero
-- @return: utility
function behaviorLib.CustomHarassUtility(heroTarget)
    -- Default 0
    local t = core.AssessLocalUnits(flint_beastwood, nil, 400)
    local numCreeps = core.NumberElements(t.EnemyUnits)
	local util = 15 - numCreeps*3
  	local unitSelf = core.unitSelf

	local moonbeanMult = 4
	local ultiMult = 6
	util = util + moonbeanMult * skills.flare:GetLevel()
	util = util + ultiMult * skills.abilUlti:GetLevel()

	if heroTarget then
		if skills.flare:CanActivate() and (unitSelf:GetManaPercent() >= 0.95 or heroTarget:GetHealthPercent() < 0.5) then
			util = util + 1000 -- Flare
		end
		if skills.abilUlti:CanActivate() and numCreeps < 3 then
			util = util + 10000 -- Ulti
		end
	end
	return util
end

--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param: botbrain
-- @return: none
local oldExecute = behaviorLib.HarassHeroBehavior["Execute"]
local function executeBehavior(botBrain)
  	local unitTarget = behaviorLib.heroTarget
  	if unitTarget == nil then
    	return oldExecute(botBrain)
  	end

  	local unitSelf = core.unitSelf
  	local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  	local success = false
	local ultiRange = skills.abilUlti:GetRange() + core.GetExtraRange(unitSelf) + core.GetExtraRange(unitTarget)
    if behaviorLib.lastHarassUtil >= 5000 then
    	if nTargetDistanceSq < ultiRange * ultiRange then
			success = core.OrderAbilityEntity(botBrain, skills.abilUlti, unitTarget)
        else
        	success = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
    end

	if not success and behaviorLib.lastHarassUtil >= 500 then
		local range = skills.flare:GetRange()
		if nTargetDistanceSq < range * range then
			success = core.OrderAbilityPosition(botBrain, skills.flare, unitTarget:GetPosition())
		else
			success = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
		end
	end

	if not success then
		return oldExecute(botBrain)
	end
	return success
end
behaviorLib.HarassHeroBehavior["Execute"] = executeBehavior

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function flint_beastwood:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
flint_beastwood.onthinkOld = flint_beastwood.onthink
flint_beastwood.onthink = flint_beastwood.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function flint_beastwood:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
flint_beastwood.oncombateventOld = flint_beastwood.oncombatevent
flint_beastwood.oncombatevent = flint_beastwood.oncombateventOverride

local oldHitBuilding = behaviorLib.HitBuildingExecute
local function ourHitBuilding(botBrain)
	local unitSelf = core.unitSelf
	local target = behaviorLib.hitBuildingTarget

    p("HITBUILDING!")
    p(skills.flare:CanActivate())

    if (not target
        or not target:IsTower()
        or not skills.flare:CanActivate() or
            unitSelf:GetManaPercent() < 0.70) then
        return oldHitBuilding(botBrain)
    end

    local flareRange = skills.flare:GetRange() +
                        core.GetExtraRange(unitSelf) +
                        core.GetExtraRange(unitTarget)
    local dist = Vector3.Distance2DSq(unitSelf:GetPosition(), target:GetPosition())
    local inRange = dist < flareRange * flareRange

    local success
	if not inRange then
        success = core.OrderMoveToPosClamp(botBrain, unitSelf, target:GetPosition(), false)
    else
        success = core.OrderAbilityPosition(botBrain, skills.flare, target:GetPosition())
	end

    if not success then
        return oldHitBuilding(botBrain)
    end
end
behaviorLib.HitBuildingBehavior["Execute"] = ourHitBuilding
