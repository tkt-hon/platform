local _G = getfenv(0)
local plaguerider = _G.object

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/vidyanmetamindgames/shoppinglib.lua'

local core, behaviorLib = plaguerider.core, plaguerider.behaviorLib

-- behaviorLib.StartingItems = { "Item_MysticPotpourri" }
-- behaviorLib.StartingItems = { "6 Item_HealthPotion"  }
behaviorLib.StartingItems = { "Item_HealthPotion", "Item_ManaRegen3" }
behaviorLib.LaneItems = { "Item_MysticPotpourri", "Item_MysticVestments", "Item_Marchers", "Item_EnhancedMarchers", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_SpellShards 3", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower" }

plaguerider.skills = {}
local skills = plaguerider.skills

plaguerider.tSkills = {
    1, 4, 1, 4, 1,
    3, 1, 4, 4, 4,
    3, 0, 0, 0, 0,
    3, 4, 4, 4, 4,
    4, 2, 2, 2, 2
}

local tinsert = _G.table.insert

core.itemWard = nil

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

plaguerider.ShieldTarget = nil

local ArrowTarget = nil

local function IsMelee(unit)
    local unitType = unit:GetTypeName()
    return unitType == "Creep_LegionMelee" or unitType == "Creep_HellbourneMelee"
end

-- check if the bot should cast the armor spell on an allied creep
-- the creep with the most HP which has no armor will be chosen
local function GetShieldTarget(units)
    local nMaxHP = 0
    local unitTarget = nil

    if units == nil then
        return nil
    end

    for _,unit in pairs(units.AllyCreeps) do
        local nNewMaxHP = unit:GetHealth()
        local bHasShield = unit:HasState("State_DiseasedRider_Ability2_Buff")
        local bIsMelee = IsMelee(unit)

        if bIsMelee and nNewMaxHP > nMaxHP and not bHasShield then
            nMaxHP = nNewMaxHP
            unitTarget = unit
        end
    end

    return unitTarget
end

local function ShieldBehaviorUtility(botBrain)
    if skills.abilShield:CanActivate() then
        return 100
    end

    return 0
end

local function ShieldBehaviorExecute(botBrain)
    local unitSelf = botBrain.core.unitSelf
    local abilShield = skills.abilShield
    local unitsLocal = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), skills.abilShield:GetRange())

    local target = GetShieldTarget(unitsLocal)  

    if target ~= nil and abilShield:CanActivate() then
        core.BotEcho("Casting shield on "..target:GetTypeName().." with hp="..target:GetHealth())
        return core.OrderAbilityEntity(botBrain, abilShield, target, false)
    end

    return false
end

local ShieldBehavior = {}
ShieldBehavior["Utility"] = ShieldBehaviorUtility
ShieldBehavior["Execute"] = ShieldBehaviorExecute
ShieldBehavior["Name"] = "Casting shield spell on a creep"
tinsert(behaviorLib.tBehaviors, ShieldBehavior)




local function GetEnemyTower(units)
    if units.EnemyTowers == nil then
        return nil
    end

    for unit in units.EnemyTowers do
        return unit
    end
end

local function TowerAttackBehaviorUtility(botBrain)
    local unitSelf = botBrain.core.unitSelf
    local units = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 1000)

    local tower = nil--GetEnemyTower(units)
    if tower == nil then
        return 0
    end

    -- do your magic

end

local function TowerAttackBehaviorExecute(botBrain)
end

local TowerAttackBehavior = {}
TowerAttackBehavior["Utility"] = TowerAttackBehaviorUtility
TowerAttackBehavior["Execute"] = TowerAttackBehaviorExecute
TowerAttackBehavior["Name"] = "FUCK YEAH ATTACKING TOWERS :D"
tinsert(behaviorLib.tBehaviors, TowerAttackBehavior)

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function plaguerider:onthinkOverride(tGameVariables)
    self:onthinkOld(tGameVariables)
    local myPos = core.unitSelf:GetPosition()


    --Continuously prints tower position if near one. Will be removed in the future
    local localUnits = core.localUnits
    local enemyBuildings = localUnits["EnemyBuildings"]
    local sortedEnemyBuildings = core.SortBuildings(enemyBuildings)
    local towers = sortedEnemyBuildings.enemyTowers
    if core.NumberElements(towers) > 0 then
        for id, tower in pairs(towers) do
            core.BotEcho("tower pos: " ..tostring(tower:GetPosition()))
        end
    end
    --tower pos print end

    if ArrowTarget ~= nil then
        core.DrawDebugArrow(myPos, ArrowTarget, "lime")
    end
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

local function IsSiege(unit)
    local unitType = unit:GetTypeName()
    return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end


local function ShouldDenyByHP(unit)
    local hpp = unit:GetHealthPercent()

    if hpp < 0.05 then
        core.BotEcho('denying unit with health at '..hpp..'%')
        return true
    end

    return false
end

local function GetUnitToDenyWithSpell(botBrain, myPos, radius)
    local unitsLocal = core.AssessLocalUnits(botBrain, myPos, radius)
    local allies = unitsLocal.AllyCreeps
    local unitTarget = nil
    local nDistance = 0
    for _,unit in pairs(allies) do
        local nNewDistance = Vector3.Distance2DSq(myPos, unit:GetPosition())

        if not IsSiege(unit) and (not unitTarget or nNewDistance < nDistance) then --and ShouldDenyByHP(unit) then
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

local function OverrideGetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep)
    if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
        core.BotEcho("Using new")
        
        local unitSelf = botBrain.core.unitSelf
        local unitsLocal = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 550)
        local unitsAllies = unitsLocal.AllyCreeps
        
        if #unitsAllies == 1 and unitsAllies[1]:GetHealthPercent() ~= 1 then
          return nil
        end
        
        if unitEnemyCreep:GetHealthPercent() < 0.4 then
            return unitEnemyCreep
        end

        return nil
    end
    return behaviorLib.GetCreepAttackTargetOLD(botBrain, unitEnemyCreep, unitAllyCreep)
end

behaviorLib.GetCreepAttackTargetOLD = behaviorLib.GetCreepAttackTarget
behaviorLib.GetCreepAttackTarget = OverrideGetCreepAttackTarget

local function OverridePositionSelfExecute(botBrain)
    	
	local nCurrentTimeMS = HoN.GetGameTime()
	local unitSelf = core.unitSelf
	local vecMyPosition = unitSelf:GetPosition()
	
	if core.unitSelf:IsChanneling() then 
		return
	end
	
	local vecDesiredPos = vecMyPosition
	local unitTarget = nil
	vecDesiredPos, unitTarget = behaviorLib.PositionSelfLogic(botBrain)

	if vecDesiredPos then
		behaviorLib.MoveExecute(botBrain, vecDesiredPos)
	else
		BotEcho("PositionSelfExecute - nil desired position")
		return false
	end

	if bDebugLines then
		if unitTarget ~= nil then
			core.DrawXPosition(unitTarget:GetPosition(), 'orange', 125)
		end

		if vecDesiredPos then
			core.DrawXPosition(vecDesiredPos, 'blue')
		end
	end

end

behaviorLib.PositionSelfBehavior["Execute"] = OverridePositionSelfExecute
behaviorLib.PositionSelfExecuteOLD = behaviorLib.PositionSelfExecute
behaviorLib.PositionSelfExecute = OverridePositionSelfExecute

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
    local abilNuke = skills.abilNuke

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

local function IsSpotWarded(spot)
  local gadgets = HoN.GetUnitsInRadius(spot, 200, core.UNIT_MASK_GADGET + core.UNIT_MASK_ALIVE)
  for k, gadget in pairs(gadgets) do
    if gadget:GetTypeName() == "Gadget_FlamingEye" then
      return true
    end
  end
  return false
end

local function PreGameExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  local ward = core.itemWard
  local wardSpot = nil
  if core.myTeam == HoN.GetLegionTeam() then
    wardSpot = Vector3.Create(5003.0000, 12159.0000, 128.0000)
  else
    wardSpot = Vector3.Create(11140.0000, 3400.0000, 128.0000)
  end
  if unitSelf.isSuicide and ward and not IsSpotWarded(wardSpot) then
    core.DrawXPosition(wardSpot)
    local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), wardSpot)
    local nRange = 600
    if nTargetDistanceSq < (nRange * nRange) then
      bActionTaken = core.OrderItemPosition(botBrain, unitSelf, ward, wardSpot)
    else
      bActionTaken = behaviorLib.MoveExecute(botBrain, wardSpot)
    end
    return bActionTaken
  elseif unitSelf.isSuicide and not ward and botBrain:GetGold() > 100 then
    return true
  else
    return behaviorLib.PreGameExecute(botBrain)
  end
end
behaviorLib.PreGameBehavior["Execute"] = PreGameExecuteOverride

local function DistanceThreatUtilityOverride(nDist, nRange, nMoveSpeed, bAttackReady)
  if core.unitSelf.isSuicide then
    nRange = nRange * 2
    nDist = nDist / 2
  end
  return behaviorLib.DistanceThreatUtilityOld(nDist, nRange, nMoveSpeed, bAttackReady)
end
behaviorLib.DistanceThreatUtilityOld = behaviorLib.DistanceThreatUtility
behaviorLib.DistanceThreatUtility = DistanceThreatUtilityOverride

local function funcFindItemsOverride(botBrain)
  local bUpdated = plaguerider.FindItemsOld(botBrain)

  if core.itemWard ~= nil and not core.itemWard:IsValid() then
    core.itemWard = nil
  end

  if bUpdated then
    if core.itemWard then
      return
    end

    local inventory = core.unitSelf:GetInventory(true)
    for slot = 1, 12, 1 do
      local curItem = inventory[slot]
      if curItem then
        if core.itemWard == nil and curItem:GetName() == "Item_FlamingEye" then
          core.itemWard = core.WrapInTable(curItem)
        end
      end
    end
  end
  return bUpdated
end
plaguerider.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

local function EnemiesNearPosition(vecPosition)
  local tHeroes = HoN.GetUnitsInRadius(vecPosition, core.localCreepRange, core.UNIT_MASK_ALIVE + core.UNIT_MASK_HERO)
  for _, hero in pairs(tHeroes) do
    if hero:GetTeam() == core.enemyTeam then
      return true
    end
  end
  return false
end

local function PositionSelfTraverseLaneOverride(botBrain)
  local oldPosition = behaviorLib.PositionSelfTraverseLaneOld(botBrain, unitCurrentTarget)
  local unitSelf = core.unitSelf

  if unitSelf.isSuicide and not plaguerider.bMetEnemies and HoN.GetMatchTime() < core.MinToMS(1) then
    if EnemiesNearPosition(oldPosition) then
      plaguerider.bMetEnemies = true
      ArrowTarget = oldPosition
      return oldPosition
    else
      local towerPosition = core.GetFurthestLaneTower(core.teamBotBrain:GetDesiredLane(unitSelf), core.bTraverseForward, core.myTeam):GetPosition()
      local basePosition = core.allyMainBaseStructure:GetPosition()
      if Vector3.Distance2DSq(oldPosition, basePosition) < Vector3.Distance2DSq(towerPosition, basePosition) then
      ArrowTarget = oldPosition  
      return oldPosition
      else
        ArrowTarget = towerPosition
        return towerPosition
      end
    end
  else
    ArrowTarget = oldPosition
    return oldPosition
  end
end
behaviorLib.PositionSelfTraverseLaneOld= behaviorLib.PositionSelfTraverseLane
behaviorLib.PositionSelfTraverseLane = PositionSelfTraverseLaneOverride
