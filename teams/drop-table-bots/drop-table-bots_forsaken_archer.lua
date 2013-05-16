local _G = getfenv(0)
local forsaken_archer = _G.object

forsaken_archer.heroName = "Hero_ForsakenArcher"

runfile 'bots/teams/drop-table-bots/droptable-herobot.lua'
runfile 'bots/teams/drop-table-bots/libhon.lua'

local core, behaviorLib = forsaken_archer.core, forsaken_archer.behaviorLib
forsaken_archer.skills = {}
local skills = forsaken_archer.skills

forsaken_archer.tSkills = {
  0, 4, 4, 0, 2,
  3, 0, 2, 4, 0,
  3, 2, 2, 1, 1,
  3, 1, 1, 4, 4,
  4, 4, 4, 4, 4
}


---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function forsaken_archer:SkillBuildOverride()
    local unitSelf = self.core.unitSelf
    if  skills.abilCripplingVolley == nil then
		skills.abilCripplingVolley	= unitSelf:GetAbility(0)
		skills.abilSplitFire		= unitSelf:GetAbility(1)
		skills.abilCallOfTheDamned	= unitSelf:GetAbility(2)
		skills.abilUlti	            = unitSelf:GetAbility(3)
		skills.abilAttributeBoost	= unitSelf:GetAbility(4)
	end
    self:SkillBuildOld()
end
forsaken_archer.SkillBuildOld = forsaken_archer.SkillBuild
forsaken_archer.SkillBuild = forsaken_archer.SkillBuildOverride

---------------------------------------------------------------
--            Harass utility override                        --
---------------------------------------------------------------
-- @param: hero
-- @return: utility
function behaviorLib.CustomHarassUtility(heroTarget)
    -- Default 0
    local t = core.AssessLocalUnits(forsaken_archer, nil, 400)
    local numCreeps = core.NumberElements(t.EnemyUnits)
	local util = 10 - numCreeps*3
  	local unitSelf = core.unitSelf

	local volleyMult = 3
	local ultiMult = 6
	util = util + volleyMult * skills.abilCripplingVolley:GetLevel()
	util = util + ultiMult * skills.abilUlti:GetLevel()

	if heroTarget then
		if skills.abilCripplingVolley:CanActivate() and (unitSelf:GetManaPercent() >= 0.95 or heroTarget:GetHealthPercent() < 0.75) then
			util = util + 1000 -- Splitfire
		end
		if skills.abilUlti:CanActivate() and (heroTarget:GetHealthPercent() < 0.4 or numCreeps < 3) then
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
	local ultiRange = 625
    if behaviorLib.lastHarassUtil >= 5000 then
    	if nTargetDistanceSq < ultiRange * ultiRange then
            p("ULTI")
			success = core.OrderAbilityPosition(botBrain, skills.abilUlti, unitTarget:GetPosition())
        else
        	success = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
    end

	if not success and behaviorLib.lastHarassUtil >= 500 then
		local range = skills.abilCripplingVolley:GetRange()
        p("VOLLEY")
		if nTargetDistanceSq < range * range then
			success = core.OrderAbilityPosition(botBrain, skills.abilCripplingVolley, unitTarget:GetPosition())
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
