local _G = getfenv(0)
local magmus = _G.object

runfile 'bots/magmus/magmus_main.lua'

local core, behaviorLib = magmus.core, magmus.behaviorLib

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_CrushingClaws", "Item_MinorTotem", "Item_CrushingClaws"  }
behaviorLib.LaneItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_CrushingClaws", "Item_MinorTotem", "Item_CrushingClaws"  }
behaviorLib.MidItems = { "Item_PortalKey", "Item_EnhancedMarchers", "Item_PowerSupply" }
behaviorLib.LateItems = { "Item_GrimoireOfPower", "Item_RestorationStone" }

local skills = magmus.skills

local tinsert = _G.table.insert

core.itemWard = nil
magmus.bReportBehavior = true
magmus.bDebugUtility = true


magmus.tSkills = {
  0, 1, 0, 1, 0,
  3, 0, 1, 1, 2,
  3, 2, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
local SkillBuildOld = magmus.SkillBuild
local function SkillBuildOverride(self)
  local unitSelf = self.core.unitSelf
  if skills.abilVolcanicTouch == nil then
    skills.abilSurge = unitSelf:GetAbility(0)
    skills.abilBath = unitSelf:GetAbility(1)
    skills.abilVolcanicTouch = unitSelf:GetAbility(2)
    skills.abilEruption = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  local unitSelf = self.core.unitSelf
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local nlev = unitSelf:GetLevel()
  local nlevpts = unitSelf:GetAbilityPointsAvailable()
  local nStartPoint = 1+nlev-nlevpts
  for i = nStartPoint, nlev do
    unitSelf:GetAbility( self.tSkills[i] ):LevelUp()
  end
end
magmus.SkillBuild = SkillBuildOverride

----------------------------------
--	Skill use variables	--
----------------------------------

-- bonus aggro pts if skill/item is available
magmus.nSurgeUp = 30
magmus.nBathUp = 0
magmus.nTouch = 0
magmus.nUltUp = 25
 
 
-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
magmus.nSurgeUse = 15
magmus.nBathUse = 5
magmus.nTouchUse = 0
magmus.nUltUse = 35
 
 
--These are thresholds of aggression the bot must reach to use these abilities

magmus.nSurgeThreshold = 10
magmus.nBathThreshold = 5
magmus.nTouchThreshold = 11
magmus.nUltThreshold = 35

----------------------------------
--	OnCombatEvent Override	--
----------------------------------
-- @param: EventData
-- @return: none 
local oncombateventOld = magmus.oncombatevent
local function oncombateventOverride(self, EventData)
    oncombateventOld(self, EventData)
 
    local nAddBonus = 0
 
    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_Magmus2" then
            nAddBonus = nAddBonus + 15
	elseif EventData.InflictorName == "Ability_Magmus1" then
            nAddBonus = nAddBonus + 20
        elseif EventData.InflictorName == "Ability_Magmus3" then
            nAddBonus = nAddBonus + 20
        elseif EventData.InflictorName == "Ability_Magmus4" then
            nAddBonus = nAddBonus + 25
        end
    elseif EventData.Type == "Item" then
        end

   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
 end
-- override combat event trigger function.
magmus.oncombatevent     = oncombateventOverride

-------------------------------------------------------------
--              CustomHarassUtility Override
-------------------------------------------------------------

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilSurge:CanActivate() then
    nUtil = nUtil + 30
    local damages = {50,100,125,175}
    if hero:GetHealth() < damages[skills.abilSurge:GetLevel()] then
      nUtil = nUtil + 30
    end
  end

  if skills.abilEruption:CanActivate() then
    nUtil = nUtil + 40
  end

  if core.unitSelf.isSuicide then
    nUtil = nUtil / 2
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride


----------------------------------
--	HarassHeroOverride	--
----------------------------------
local harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
local function HarassHeroExecuteOverride(botBrain)

    local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil then
        return harassExecuteOld(botBrain)  --Target is invalid, move on to the next behavior
    end
     
    local unitSelf = core.unitSelf
    local vecMyPosition = unitSelf:GetPosition() 
    local nAttackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
    local nMyExtraRange = core.GetExtraRange(unitSelf)
     
    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetExtraRange = core.GetExtraRange(unitTarget)
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
 
     
    local nLastHarassUtility = behaviorLib.lastHarassUtil
    local bCanSee = core.CanSeeUnit(botBrain, unitTarget)    
    local bActionTaken = false

    if core.CanSeeUnit(botBrain, unitTarget) then
    -- Ulti
    local abilEruption = skills.abilEruption
    if not bActionTaken then
      if abilEruption:CanActivate() then
          bActionTaken = core.OrderAbility(botBrain, abilEruption)
 	local nRange = abilSurge:GetRange()
	if abilSurge:CanActivate() and nTargetDistanceSq < (nRange * nRange) then
         bActionTaken = core.OrderAbilityEntity(botBrain, abilSurge, unitTarget)
          else
            bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
          end
      end
end

        -- Surge
        local abilSurge = skills.abilSurge
        if abilSurge:CanActivate() then
          local nRange = abilSurge:GetRange()
          if nTargetDistanceSq < (nRange * nRange) then
            bActionTaken = core.OrderAbilityEntity(botBrain, abilSurge, unitTarget)
          else
            bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
          end
        end
	end

	-- Bath
	local abilBath = skills.abilBath
	if abilBath:CanActivate() then
	  local nRange = abilBath:GetRange()
	  if nTargetDistanceSq < (nRange * nRange) then	
	    local bestUnitTarget = funcBestTargetAoE(tEnemyHeroes, unitTarget, nRange)
		bActionTaken = core.OrderAbilityEntity(botBrain, abilBath, bestUnitTarget)
	  else
		bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, bestUnitTarget)
	  end
	end
    

  if not bActionTaken then
    return harassExecuteOld(botBrain)
  end
end
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

------------------------------------------------
--		AttackCreepUtility and Execute        --
------------------------------------------------

local function AttackCreepsUtilityOverride(botBrain)	
	local nDenyVal = 15
	local nLastHitVal = 20

	local nUtility = 0

--we don't want to deny if we are pushing
	local unitDenyTarget = core.unitAllyCreepTarget
	if core.GetCurrentBehaviorName(botBrain) == "Push" then
		unitDenyTarget = nil
	end

	local unitTarget = behaviorLib.GetCreepAttackTarget(botBrain, core.unitEnemyCreepTarget, unitDenyTarget)

	if unitTarget and core.unitSelf:IsAttackReady() then
		if unitTarget:GetTeam() == core.myTeam then
			nUtility = nDenyVal
		else
			nUtility = nLastHitVal
		end
	core.unitCreepTarget = unitTarget
	end


	return nUtility
end

behaviorLib.AttackCreepsUtility = AttackCreepsUtilityOverride


local function AttackCreepsExecute(botBrain)
	local unitSelf = core.unitSelf
	local currentTarget = core.unitCreepTarget

	if currentTarget and core.CanSeeUnit(botBrain, currentTarget) then	
	local vecTargetPos = currentTarget:GetPosition()
	local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
	local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)

		if currentTarget ~= nil then
			if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() then
--only attack when in nRange, so not to aggro towers/creeps until necessary, and move forward when attack is on cd
				core.OrderAttackClamp(botBrain, unitSelf, currentTarget)
			else
--BotEcho("MOVIN OUT")
		local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
		core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)
			end
		end
	else
	return false
	end
end

behaviorLib.AttackCreepsBehavior = {}
behaviorLib.AttackCreepsBehavior["Utility"] = behaviorLib.AttackCreepsUtility
behaviorLib.AttackCreepsBehavior["Execute"] = behaviorLib.AttackCreepsExecute
behaviorLib.AttackCreepsBehavior["Name"] = "AttackCreeps"
tinsert(behaviorLib.tBehaviors, behaviorLib.AttackCreepsBehavior)

behaviorLib.AttackCreepsExecute = AttackCreepsExecuteOverride


local function funcBestTargetAOE(tEnemyHeroes, unitTarget, nRange)
-- Determines the optimal target for an AoE attack
    local nHeroes = core.NumberElements(tEnemyHeroes)
    if nHeroes <= 1 then
        return unitTarget 
    end
 
    local tTemp = core.CopyTable(tEnemyHeroes)
 
    local nRangeSq = nRange*nRange
    local nDistSq = 0
    local unitBestTarget = nil
    local nBestTargetsHit = 0
 
    for nTargetID,unitTarget in pairs(tEnemyHeroes) do
        local nTargetsHit = 1
        local vecCurrentTargetsPosition = unitTarget:GetPosition()
        for nHeroID,unitHero in pairs(tTemp) do
            if nTargetID ~= nHeroID then
                nDistSq = Vector3.Distance2DSq(vecCurrentTargetsPosition, unitHero:GetPosition())
                if nDistSq < nRangeSq then
                    nTargetsHit = nTargetsHit + 1
                end
            end
        end
 
        if nTargetsHit > nBestTargetsHit then
            nBestTargetsHit = nTargetsHit
            unitBestTarget = unitTarget
        end
    end
 
    return unitTarget
end
