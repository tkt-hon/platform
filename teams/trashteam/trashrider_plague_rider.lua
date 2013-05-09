local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'

local tinsert = _G.table.insert

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_PretendersCrown", "Item_HealthPotion", "Item_RunesOfTheBlight" }
behaviorLib.LaneItems = { "Item_MysticVestments", "Item_Marchers", "Item_ManaBattery" }
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_PowerSupply", "Item_MysticVestments" }
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
  2, 0, 0, 0, 1,
  3, 1, 0, 3, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}


function plaguerider:SkillBuildOverride()
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
self.eventsLib.printCombatEvent(EventData)

end

-- override combat event trigger function.

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
  local abilDeny = unitSelf:GetAbility(2)
  local myPos = unitSelf:GetPosition()
  local unit = GetUnitToDenyWithSpell(botBrain, myPos, abilDeny:GetRange())
  if abilDeny:CanActivate() and unit and IsUnitCloserThanEnemies(botBrain, myPos, unit) then
    plaguerider.denyTarget = unit
    return 90
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
		return 100
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
  end
  return false
end

local ShieldingBehavior = {}
ShieldingBehavior["Utility"] = ShieldBehaviorUtility
ShieldingBehavior["Execute"] = ShieldExecute
ShieldingBehavior["Name"] = "Shielding creep"
tinsert(behaviorLib.tBehaviors, ShieldingBehavior)

plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride


local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if unitSelf:GetAbility(0):CanActivate() then
    nUtil = nUtil + 30
    local damages = {50,100,125,175}
    if hero:GetHealth() < damages[skills.abilNuke:GetLevel()] then
      nUtil = nUtil + 30
    end
  end

  if unitSelf:GetAbility(4):CanActivate() then
    nUtil = nUtil + 100
  end

  if core.unitSelf.isSuicide then
    nUtil = nUtil / 2
  end
  
  local kriipit = core.AssessLocalUnits(botBrain, mypos, radius).EnemyUnits

	for key,unit in pairs(kriipit) do
    	if unit:GetAttackTarget() ~= core.unitSelf and not core.IsCourier(unit) then
				return 100
			else return 0
		end
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

    if abilNuke:CanActivate() then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end

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
