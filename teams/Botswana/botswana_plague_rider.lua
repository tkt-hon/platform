local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib


behaviorLib.StartingItems = { "Item_MinorTotem", "Item_PretendersCrown", "Item_RunesOfTheBlight", "Item_MinorTotem", "Item_RunesOfTheBlight"  }
behaviorLib.LaneItems = { "Item_Marchers", "Item_ManaBattery", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_Striders", "Item_SpellShards", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower", "Item_RestorationStone" }

plaguerider.skills = {}
local skills = plaguerider.skills

local tinsert = _G.table.insert

core.itemWard = nil

plaguerider.tSkills = {
  2, 0, 0, 2, 0,
  3, 0, 4, 2, 4,
  3, 4, 4, 2, 4,
  3, 2, 4, 4, 4,
  3, 4, 4, 4, 4
}
function plaguerider:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilDeny == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilShield = unitSelf:GetAbility(1)
    skills.abilDeny = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
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


-- bonus aggro pts if skill/item is available
plaguerider.nNukeUp = 30
plaguerider.nArmorUp = 0
plaguerider.nManaUp = 0
plaguerider.nUltUp = 25
 
 
-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
plaguerider.nNukeUse = 15
plaguerider.nArmorUse = 5
plaguerider.nManaUse = 0
plaguerider.nUltUse = 35
 
 
--These are thresholds of aggression the bot must reach to use these abilities

plaguerider.nNukeThreshold = 10
plaguerider.nArmorThreshold = 5
plaguerider.nManaThreshold = 11
plaguerider.nUltThreshold = 35


----------------------------------------------
--            OnCombatEvent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)
  
  local nAddBonus = 0
  
  if EventData.Type == "Ability" then
  	if EventData.Inflictorname == "Ability_DiseasedRider1" then
  		nAddBonus = nAddBonus + plaguerider.nNukeUse
  	elseif EventData.Inflictorname == "Ability_DiseasedRider4" then
  		nAddBonus = nAddBonus + plaguerider.nUltUse
  	elseif EventData.Inflictorname == "Ability_DiseasedRider3" then
  		nAddBonus = nAddBonus + plaguerider.ManaUse
  	elseif EventData.Inflictorname == "Ability_DiseasedRider2" then
  		nAddBonus = nAddBonus + plaguerider.nArmorUse
  	
  	end
  end
  
  if nAddBonus > 0 then
  	core.Decaybonus(self)
  	core.nHarassBonus = core.nHarassBonus + nAddBonus
  end
  
end
  
  -- custom code here


-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride
-------------------------------------------------------
-- Deny

local function IsSiege(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end

local function GetUnitToDenyWithSpell(botBrain, myPos, radius)
  local unitsLocal = core.AssessLocalUnits(botBrain, myPos, radius)
  local allies = unitsLocal.AllyCreeps
  local unitTarget = nil
  local nDistance = 0
  for _,unit in pairs(allies) do
    local nNewDistance = Vector3.Distance2DSq(myPos, unit:GetPosition())
    if not IsSiege(unit) and (not unitTarget or nNewDistance < nDistance) then
      unitTarget = unit
      nDistance = nNewDistance
    end
  end
  return unitTarget
end

local function IsUnitCloserThanEnemies(botBrain, myPos, unit)
  local unitsLocal = core.AssessLocalUnits(botBrain, myPos, Vector3.Distance2DSq(myPos, unit:GetPosition()))
  return core.NumberElements(unitsLocal.EnemyHeroes) <= 0
end

local function DenyBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = skills.abilDeny
  local myPos = unitSelf:GetPosition()
  local unit = GetUnitToDenyWithSpell(botBrain, myPos, abilDeny:GetRange())
  if abilDeny:CanActivate() and unit and IsUnitCloserThanEnemies(botBrain, myPos, unit) then
    plaguerider.denyTarget = unit
    return 100
  end
  return 0
end

local function DenyBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = skills.abilDeny
  local target = plaguerider.denyTarget
  if target then
    return core.OrderAbilityEntity(botBrain, abilDeny, target, false)
  end
  return false
end

local DenyBehavior = {}
DenyBehavior["Utility"] = DenyBehaviorUtility
DenyBehavior["Execute"] = DenyBehaviorExecute
DenyBehavior["Name"] = "Denying creep with spell"
tinsert(behaviorLib.tBehaviors, DenyBehavior)
-------------------------------------------------------------
--              CustomHarassUtility Override
-------------------------------------------------------------

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilNuke:CanActivate() then
    nUtil = nUtil + 30
    local damages = {50,100,125,175}
    if hero:GetHealth() < damages[skills.abilNuke:GetLevel()] then
      nUtil = nUtil + 30
    end
  end

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil + 100
  end

  if core.unitSelf.isSuicide then
    nUtil = nUtil / 2
  end

  return nUtil
end
----------------------------------------------------------------
--              Harass Behaviour
-- How to to use abilities
----------------------------------------------------------------

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return plaguerider.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    
    -- Nuke
    local abilNuke = skills.abilNuke
    if abilNuke:CanActivate() then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
    
    --Ulti
    local abilUltimate = skills.abilUltimate
    if not bActionTaken then
      if abilUltimate:CanActivate() then
        local nRange = abilUltimate:GetRange()
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end
  end

  if not bActionTaken then
    return plaguerider.harassExecuteOld(botBrain)
  end
end
plaguerider.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride



---------------------------------------------------------
--		AttackCreepUtility and Execute
---------------------------------------------------------

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

		if botBrain.bDebugUtility == true and nUtility ~= 0 then
			BotEcho(format(" AttackCreepsUtility: %g", nUtility))
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







