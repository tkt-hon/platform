local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'

local tinsert = _G.table.insert

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_PretendersCrown", "Item_HealthPotion", "Item_MarkOfTheNovice" }
behaviorLib.LaneItems = { "Item_MysticVestments", "Item_Marchers", "Item_HealthPotion", "Item_HealthPotion"}
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }


local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none

object.tSkills = {
  2, 1, 2, 1, 2,
  3, 2, 0, 0, 1,
  0, 1, 0, 3, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}


function plaguerider:SkillBuildOverride()
  plaguerider:SkillBuildOld()
  local unitSelf = self.core.unitSelf
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

--local vihut = core.AssessLocalUnits(self).EnemyHeroes
--for key,unit in pairs(vihut) do
--local beha = unit:GetBehavior()
--if beha then core.BotEcho("Teki jotain: "..beha:GetType())
--end
--end
--core.BotEcho(tostring(vihunplague))

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
--self.eventsLib.printCombatEvent(EventData)

end

-- override combat event trigger function.

local function IsSiege(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end

local function GetUltiTarget(botBrain, myPos, radius)
  local vihu = core.AssessLocalUnits(botBrain, myPos, radius).EnemyHeroes
  local vihunplague = nil
  
  for key,unit in pairs(vihu) do
    if unit ~= nil then
      vihunplague = unit
    end
  end
  
  if not vihunplague then 
    return nil
  end
  return vihunplague
end

local function AreThereOneToThreeEnemyUnitsClose(botBrain, myPos, range)
  local unitsLocal = core.AssessLocalUnits(botBrain, myPos, range).EnemyCreeps
  local vihucreeps = 0
  for _,unit in pairs(unitsLocal) do
    if not IsSiege(unit) then
      vihucreeps = vihucreeps + 1
    end
  end
  return vihucreeps < 4 and vihucreeps > 0
end

local function UltimateBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilUlti = unitSelf:GetAbility(3)
  local myPos = unitSelf:GetPosition()
  local vihu = GetUltiTarget(botBrain, myPos, abilUlti:GetRange())
  if not vihu then
    return 0
  end
  if abilUlti:CanActivate() and AreThereOneToThreeEnemyUnitsClose(botBrain, vihu:GetPosition(), abilUlti:GetRange()) then
    plaguerider.ultiTarget = vihu
    return 100
  end
  return 0
end

local function UltimateBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilUlti = unitSelf:GetAbility(3)
  local target = plaguerider.ultiTarget
  if target then
    return core.OrderAbilityEntity(botBrain, abilUlti, target, false)
  end
  return false
end 

local UltimateBehavior = {}
UltimateBehavior["Utility"] = UltimateBehaviorUtility
UltimateBehavior["Execute"] = UltimateBehaviorExecute
UltimateBehavior["Name"] = "Using ultimate properly"
tinsert(behaviorLib.tBehaviors, UltimateBehavior)

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
  local abilDeny = unitSelf:GetAbility(2)
  local myPos = unitSelf:GetPosition()
  local unit = GetUnitToDenyWithSpell(botBrain, myPos, abilDeny:GetRange())
  if abilDeny:CanActivate() and unit and IsUnitCloserThanEnemies(botBrain, myPos, unit) then
    plaguerider.denyTarget = unit
    return 50
  end
  return 0
end

local function DenyBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = unitSelf:GetAbility(2)
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



local function GetShieldingUnit(botBrain, myPos, radius)

	local core = botBrain.core
	local self = core.unitSelf
	local vihu = core.AssessLocalUnits(botBrain, myPos, radius).EnemyHeroes
	local vihunplague = nil

	for key,unit in pairs(vihu) do
  	if unit ~= nil then
  		vihunplague = unit
  	end
	end

	if not vihunplague then 
  	return nil
	end

	local vihundamage = core.GetFinalAttackDamageAverage(vihunplague)
	local kriipit = core.AssessLocalUnits(botBrain, mypos, radius).AllyUnits

	for key,unit in pairs(kriipit) do
		local armor = unit:GetArmor()
		local reduction = 1 - (armor*0.06)/(1+0.06*armor)
    	if unit:GetHealth() < vihundamage+30*reduction and not core.IsCourier(unit) then
				return unit
			else return nil
		end
	end
end

local function ShieldBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilShield = unitSelf:GetAbility(1)
  local myPos = unitSelf:GetPosition()
  local shieldingUnit = GetShieldingUnit(botBrain, myPos, abilShield:GetRange())
	if abilShield:CanActivate() and shieldingUnit  then	
		return 70
	end	
		return 0
end

local function ShieldExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilShield = unitSelf:GetAbility(1)
  local myPos = unitSelf:GetPosition()
  local shieldingUnit = GetShieldingUnit(botBrain, myPos, abilShield:GetRange())
  if shieldingUnit then
	local targetpos = shieldingUnit:GetPosition()
	HoN.DrawDebugLine(myPos, targetpos, true, "Red")
    return core.OrderAbilityEntity(botBrain, abilShield, shieldingUnit, false)
  else 
	return core.OrderAbilityEntity(botBrain, abilShield, unitSelf, false)
  end
  return false
end

local ShieldingBehavior = {}
ShieldingBehavior["Utility"] = ShieldBehaviorUtility
ShieldingBehavior["Execute"] = ShieldExecute
ShieldingBehavior["Name"] = "Shielding creep"
tinsert(behaviorLib.tBehaviors, ShieldingBehavior)



local function HarrassBehaUtility(botBrain)
	local unitSelf = core.unitSelf
	local kriipit = core.AssessLocalUnits(botBrain, mypos, radius).EnemyUnits
	
	for key,unit in pairs(kriipit) do
    	if unit:GetAttackTarget() ~= core.unitSelf and not core.IsCourier(unit) and not unit:IsHero() then
			return 100
		end
	end
		return 0
end
	
local function HarrassExecute(botBrain)
	local unitSelf = botBrain.core.unitSelf
	local myPos = unitSelf:GetPosition()
 	local vihu = core.AssessLocalUnits(botBrain, myPos, radius).EnemyHeroes
	local vihunplague = nil
	
	for key,unit in pairs(vihu) do
		if unit ~= nil then
			vihunplague = unit
		end
	end

	if not vihunplague then 
		return nil
	end
	
	if vihunplague ~= nil and unitSelf:GetHealthPercent() > 60 then
		core.BotEcho("vittuu")
		local targetpos = vihunplague:GetPosition()
		HoN.DrawDebugLine(myPos, targetpos, true, "Red")
		bActionTaken = core.OrderAttack(botBrain, unitSelf, vihunplague)
	end
	return false
end

local HarrassBehavior = {}
HarrassBehavior["Utility"] = HarrassBehaUtility
HarrassBehavior["Execute"] = HarrassExecute
HarrassBehavior["Name"] = "Harrass Hero"
tinsert(behaviorLib.tBehaviors, HarrassBehavior)


plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride


local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if core.unitSelf:GetAbility(0):CanActivate() then
    nUtil = nUtil + 70
  end
  
  if hero:GetHealth() < 100 then
	  nUtil = nUtil + 100
  end

  if core.unitSelf:GetAbility(3):CanActivate() then
    nUtil = nUtil + 100
  end
  
  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return plaguerider.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local abilNuke = unitSelf:GetAbility(0)
	local kriipit = core.AssessLocalUnits(botBrain, mypos, radius).EnemyUnits

	if core.GetTowersThreateningUnit(core.unitSelf, false) == nil then
	for key,unit in pairs(kriipit) do
    	if unit:GetAttackTarget() ~= core.unitSelf and not core.IsCourier(unit) and not unit:IsHero() then
			bActionTaken = core.OrderAttack(botBrain, unitSelf, unitTarget)
			
		else
			bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
			end
		end
	end

    if abilNuke:CanActivate() then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end

  end

  if not bActionTaken then
    return plaguerider.harassExecuteOld(botBrain)
  end
end
plaguerider.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
