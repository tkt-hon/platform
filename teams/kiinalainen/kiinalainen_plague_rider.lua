local _G = getfenv(0)
local plaguerider = _G.object
local tinsert = _G.table.insert

plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/teams/kiinalainen/core_kiinalainen_herobot.lua'

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function plaguerider:SkillBuildOverride()
  plaguerider:SkillBuildOld()
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride


--items
behaviorLib.StartingItems = { "Item_HealthPotion", "Item_RunesOfTheBlight", "Item_MarkOfTheNovice", "Item_PretendersCrown" }
--behaviorLib.StartingItems = { "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = { "Item_Marchers", "Item_MysticVestments", "Item_EnhancedMarchers", "Item_MagicArmor2" }
behaviorLib.MidItems = { "Item_SpellShards 3", "Item_Intelligence7", "Item_Lightbrand" }
behaviorLib.LateItems = { "Item_GrimoireOfPower" }

---deny with ability---
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
  local abilDeny = skills.abilExtinguish
  local myPos = unitSelf:GetPosition()
  local unit = GetUnitToDenyWithSpell(botBrain, myPos, abilDeny:GetRange())
  if abilDeny:CanActivate() and unit and unitSelf:GetManaPercent() < 80 and IsUnitCloserThanEnemies(botBrain, myPos, unit) then
    plaguerider.denyTarget = unit
    return 100
  end
  return 0
end

local function DenyBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = skills.abilExtinguish
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



-- These are bonus agression points if a skill/item is available for use
plaguerider.nContagionUp = 15
plaguerider.nPlagueCarrierUp = 30
plaguerider.nCursedShieldUp = 5
plaguerider.nExtinguishUp = 5
-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
plaguerider.nExtinguishUse = 10
plaguerider.nContagionUse = 20
plaguerider.nPlagueCarrierUse = 55

--These are thresholds of aggression the bot must reach to use these abilities
plaguerider.nContagionThreshold = 10
plaguerider.nPlagueCarrierThreshold = 50
plaguerider.nExtinguishThreshold = 1
plaguerider.nCursedShieldThreshold = 20

------------------------------------------------------
--            CustomHarassUtility Override          --
-- Change Utility according to usable spells here   --
------------------------------------------------------
-- @param: IunitEntity hero
-- @return: number


local function CustomHarassUtilityFnOverride(hero)
    local nUtil = 0
    local unitSelf = core.unitSelf
    local myPos = unitSelf:GetPosition()
    local distanceToClosestEnemy = 99999
--    for _,unit in pairs(enemies) do
--    	if Vector3.Distance2DSq(myPos, unit:GetPosition()) < distanceToClosestEnemy then
--    		distanceToClosestEnemy = Vector3.Distance2DSq(myPos, unit:GetPosition())
--		closestEnemy = unit
--	end
--    end

    if skills.abilContagion:CanActivate() and unitSelf:GetManaPercent() > 0.5 then
	core.AllChat("ebin nuke")
        nUtil = nUtil + plaguerider.nContagionUp
    end

    if skills.abilCursedShield:CanActivate() then
        nUtil = nUtil + plaguerider.nCursedShieldUp
    end


    if skills.abilPlagueCarrier:CanActivate() then
        nUtil = nUtil + plaguerider.nPlagueCarrierUp
    end

    if unitSelf:GetHealthPercent() < 0.15 then
    core.allChat("Minä kuolenkin itse, tämä on perseestä")
    end

    if core.GetClosestEnemyTower(hero:GetPosition(), 800) then
    nUtil = nUtil - 200
    end

    if unitSelf:GetHealthPercent() > 0.79 then
    nUtil = nUtil + 20
    end
    return nUtil
end
-- assisgn custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride


----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

local nAddBonus = 0

    if EventData.Type == "Ability" then
        if EventData.InflictorName == "Ability_DiseasedRider1" then
            nAddBonus = nAddBonus + plaguerider.nContagionUse
        elseif EventData.InflictorName == "Ability_DiseasedRider3" then
            nAddBonus = nAddBonus + plaguerider.nExtinguishUse
        elseif EventData.InflictorName == "Ability_DiseasedRider4" then
            nAddBonus = nAddBonus + plaguerider.nPlagueCarrierUse
        end
    end

   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end

end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent     = plaguerider.oncombateventOverride
  -- custom code here

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return plaguerider.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false


  if core.CanSeeUnit(botBrain, unitTarget) then
    local abilContagion = skills.abilContagion

    if abilContagion:CanActivate() then
      local nRange = abilContagion:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, 		abilContagion, unitTarget)
     else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain,unitSelf, unitTarget)
      end
    end

    local abilUltimate = skills.abilPlagueCarrier
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

function plaguerider.CustomHarassHeroUtilityOverride(botBrain)
  local nUtil = behaviorLib.HarassHeroUtility(botBrain)

  local unitSelf = core.unitSelf
  local selfPos = unitSelf:GetPosition()
  local selfHealth = unitSelf:GetHealth()
  local tLocalUnits = core.AssessLocalUnits(botBrain, selfPos, 600)

  if tLocalUnits.EnemyHeroes then
    local tEnemies = tLocalUnits.EnemyHeroes
    local nTotalEnemyHealth = nil
    for k,v in pairs(tEnemies) do
      nTotalEnemyHealth = nTotalEnemyHealth or 0 + v:GetHealth()
    end
    if (nTotalEnemyHealth or 9999 < unitSelf:GetHealth()) then
      nUtil = nUtil + (unitSelf:GetHealth() - nTotalEnemyHealth) * 0.05
    end
  end

  if skills.abilBash:IsReady() then
    nUtil = nUtil + 10
  end

  if skills.abilCharge:CanActivate() then
    nUtil = nUtil + 20
  end

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil + 50
  end

  return nUtil
end
behaviorLib.HarassHeroBehavior["Utility"] = plaguerider.CustomHarassHeroUtilityOverride
