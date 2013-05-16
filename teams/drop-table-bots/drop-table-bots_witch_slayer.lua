local _G = getfenv(0)
local witch_slayer = _G.object

witch_slayer.heroName = "Hero_WitchSlayer"

runfile 'bots/teams/drop-table-bots/droptable-herobot.lua'
runfile 'bots/teams/drop-table-bots/libhon.lua'

local core, behaviorLib = witch_slayer.core, witch_slayer.behaviorLib
witch_slayer.skills = {}
local skills = witch_slayer.skills

witch_slayer.tSkills = {
  0, 1, 2, 0, 1,
  3, 0, 1, 1, 1,
  3, 2, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
witch_slayer.graveyardUseTime = 0

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function witch_slayer:SkillBuildOverride()
    local unitSelf = self.core.unitSelf
    if  skills.abilGraveyard == nil then
		skills.abilGraveyard		= unitSelf:GetAbility(0)
		skills.abilMiniaturization	= unitSelf:GetAbility(1)
		skills.abilPowerDrain		= unitSelf:GetAbility(2)
		skills.abilUlti		= unitSelf:GetAbility(3)
		skills.abilAttributeBoost	= unitSelf:GetAbility(4)
	end
    self:SkillBuildOld()
end
witch_slayer.SkillBuildOld = witch_slayer.SkillBuild
witch_slayer.SkillBuild = witch_slayer.SkillBuildOverride

---------------------------------------------------------------
--            Harass utility override                        --
---------------------------------------------------------------
-- @param: hero
-- @return: utility
function behaviorLib.CustomHarassUtility(heroTarget)
    -- Default 0
    local t = core.AssessLocalUnits(witch_slayer, nil, 400)
    local numCreeps = core.NumberElements(t.EnemyUnits)
	local util = 15 - numCreeps*3
  	local unitSelf = core.unitSelf

	local graveyardMult = 3
	local ultiMult = 6
	util = util + graveyardMult * skills.abilGraveyard:GetLevel()
	util = util + ultiMult * skills.abilUlti:GetLevel()

    local graveyardRange = skills.abilGraveyard:GetRange()
    local drainRange = skills.abilPowerDrain:GetRange()
	if heroTarget then
        local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), heroTarget:GetPosition())
		if nTargetDistanceSq < drainRange * drainRange and
            skills.abilPowerDrain:CanActivate() and
            unitSelf:GetManaPercent() < 0.8 then
			util = util + 1000 -- Drain
		end

		if nTargetDistanceSq < graveyardRange * graveyardRange and
            skills.abilGraveyard:CanActivate() and
            (unitSelf:GetManaPercent() >= 0.95 or heroTarget:GetHealthPercent() < 0.65) then
			util = util + 1000 -- Graveyard
		end
        local timeDelta = HoN.GetGameTime() - witch_slayer.graveyardUseTime
        if skills.abilMiniaturization:CanActivate() and
                timeDelta > 1000 and timeDelta < 2500 then
			util = util + 10000 -- Mini
            p("GRAVEYARD TIMER")
        end

		if skills.abilUlti:CanActivate() and (heroTarget:GetHealthPercent() < 0.4 or numCreeps < 3) then
			util = util + 100000 -- Ulti
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
	local ultiRange = 700
    if behaviorLib.lastHarassUtil >= 50000 then
    	if nTargetDistanceSq < ultiRange * ultiRange then
            p("ULTI")
			success = core.OrderAbilityEntity(botBrain, skills.abilUlti, unitTarget)
        else
        	success = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
    end

	if not success and behaviorLib.lastHarassUtil >= 3000 then
        p("MINI")
		local range = skills.abilMiniaturization:GetRange()
		if nTargetDistanceSq < range * range then
			success = core.OrderAbilityEntity(botBrain, skills.abilMiniaturization, unitTarget)
            if success then
                witch_slayer.graveyardUseTime = 0
            end
		else
			success = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
		end
    end
	if not success
           and behaviorLib.lastHarassUtil >= 500 
           and unitSelf:GetManaPercent() < 0.8
           and skills.abilPowerDrain:CanActivate() then
        success = core.OrderAbilityEntity(botBrain, skills.abilPowerDrain, unitTarget)
    end
	if not success and behaviorLib.lastHarassUtil >= 500 then
        p("GRAVEYARD")
        success = core.OrderAbilityPosition(botBrain, skills.abilGraveyard, unitTarget:GetPosition())
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
function witch_slayer:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
witch_slayer.onthinkOld = witch_slayer.onthink
witch_slayer.onthink = witch_slayer.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function witch_slayer:oncombateventOverride(EventData)
    self:oncombateventOld(EventData)
    local bonus = 0
	if EventData.Type == "Ability" then
		if EventData.InflictorName == "Ability_WitchSlayer1" then
			bonus = bonus + 15
			witch_slayer.graveyardUseTime = EventData.TimeStamp
		elseif EventData.InflictorName == "Ability_WitchSlayer2" then
			bonus = bonus + 20
        end
    end
	if bonus > 0 then
		core.DecayBonus(self)
		core.nHarassBonus = core.nHarassBonus + bonus
    end
end
witch_slayer.oncombateventOld = witch_slayer.oncombatevent
witch_slayer.oncombatevent = witch_slayer.oncombateventOverride
