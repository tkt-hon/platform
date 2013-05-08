local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_moonbot.lua'

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib
local tinsert = _G.table.insert

behaviorLib.StartingItems = { "Item_TrinketOfRestoration", "Item_RunesOfTheBlight", "3 Item_MinorTotem" }
behaviorLib.LaneItems = { "Item_ManaRegen3", "Item_LifeSteal5", "Item_Marchers", "Item_WhisperingHelm" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }

behaviorLib.pushingStrUtilMul = 1

moonqueen.skills = {}
local skills = moonqueen.skills

core.itemGeoBane = nil

moonqueen.tSkills = {
  0, 4, 0, 4, 0,
  3, 0, 2, 2, 1,
  3, 1, 1, 1, 2,
  3, 2, 4, 4, 4,
  4, 4, 4, 4, 4
}

function moonqueen:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilBounce = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
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

  -- custom code here
end
-- override combat event trigger function.
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride

local function NearbyEnemyCreepCount(botBrain, center, radius)
  local count = 0
  local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
  local enemies = unitsLocal.EnemyCreeps
  for _,unit in pairs(enemies) do
    count = count + 1
  end
  return count
end

local function NearbyAllyCreepCount(botBrain, center, radius)
  local count = 0
  local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
  local enemies = unitsLocal.AllyCreeps
  for _,unit in pairs(enemies) do
    count = count + 1
  end
  return count
end

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  local unitSelf = core.unitSelf
  local mana = unitSelf:GetMana()

  if skills.abilNuke:CanActivate() and mana > 370 then
    nUtil = nUtil + 5*skills.abilNuke:GetLevel() + 15
  end

  local creeps = NearbyEnemyCreepCount(moonqueen, hero:GetPosition(), 700)

  if skills.abilUltimate:CanActivate() and creeps < 2 then
    nUtil = nUtil + 100
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return moonqueen.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local itemGeoBane = core.itemGeoBane
    if not bActionTaken then
      if itemGeoBane then
        if itemGeoBane:CanActivate() then
          bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemGeoBane)
        end
      end
    end

    local abilUltimate = skills.abilUltimate
    if not bActionTaken and nLastHarassUtility > 50 then
      if abilUltimate:CanActivate() then
        local nRange = 600
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbility(botBrain, abilUltimate)
	  core.AllChat("get owned!",10)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end

    local abilNuke = skills.abilNuke
    if abilNuke:CanActivate() then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
	core.AllChat("BAM!",10)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
  end

  if not bActionTaken then
    return moonqueen.harassExecuteOld(botBrain)
  end
end
moonqueen.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function DPSPushingUtilityOverride(myHero)
  local unitSelf = core.unitSelf
  local modifier = 1 + (NearbyAllyCreepCount(moonqueen, unitSelf:GetPosition(), 700) - NearbyEnemyCreepCount(moonqueen, unitSelf:GetPosition(), 700))  + myHero:GetAbility(1):GetLevel()*0.7
  if(modifier < 0) then modifier = 0
  end
  return moonqueen.DPSPushingUtilityOld(myHero) * modifier
end
moonqueen.DPSPushingUtilityOld = behaviorLib.DPSPushingUtility
behaviorLib.DPSPushingUtility = DPSPushingUtilityOverride

local function funcFindItemsOverride(botBrain)
  local bUpdated = moonqueen.FindItemsOld(botBrain)

  if core.itemGeoBane ~= nil and not core.itemGeoBane:IsValid() then
    core.itemGeoBane = nil
  end

  if bUpdated then
    if core.itemGeoBane then
      return
    end

    local inventory = core.unitSelf:GetInventory(true)
    for slot = 1, 12, 1 do
      local curItem = inventory[slot]
      if curItem then
        if core.itemGeoBane == nil and curItem:GetName() == "Item_ManaBurn2" and not curItem:IsRecipe() then
          core.itemGeoBane = core.WrapInTable(curItem)
        end
      end
    end
  end
  return bUpdated
end
moonqueen.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

local function UseAbilitiesWhenThreatenedUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local health = unitSelf:GetHealthPercent()
  local abilNuke = skills.abilNuke
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return 0
  end
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  if abilNuke:CanActivate() and health < 0.25 and nTargetDistanceSq < (abilNuke:GetRange()) then
    return 100
  end
  return 0
end

local function UseAbilitiesWhenThreatenedExecute(botBrain)
  core.AllChat("Using abilities to defend myself",10)
  local abilNuke = skills.abilNuke
  local unitTarget = behaviorLib.heroTarget
  core.AllChat("BAM!",10)
  return core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
end

local ThreatenedBehavior = {}
ThreatenedBehavior["Utility"] = UseAbilitiesWhenThreatenedUtility
ThreatenedBehavior["Execute"] = UseAbilitiesWhenThreatenedExecute
ThreatenedBehavior["Name"] = "Saving myself with spells"
tinsert(behaviorLib.tBehaviors, ThreatenedBehavior)




