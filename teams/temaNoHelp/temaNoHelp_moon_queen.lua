local _G = getfenv(0)
local moonqueen = _G.object

local tinsert, tremove, max = _G.table.insert, _G.table.remove, _G.math.max

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/temaNoHelp/lib/courier.lua'
runfile 'bots/teams/temaNoHelp/lib/shopping.lua'
runfile 'bots/teams/temaNoHelp/mq_lasthit.lua'
runfile 'bots/teams/temaNoHelp/mq_position.lua'

local core, behaviorLib, shopping, courier = moonqueen.core, moonqueen.behaviorLib, moonqueen.shopping, moonqueen.courier

local ultDuration = HoN.GetMatchTime()-500

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_IronBuckler", "Item_RunesOfTheBlight", "Item_HealthPotion"}

local function PreGameItems()
  for _, item in ipairs(behaviorLib.StartingItems) do
    tremove(behaviorLib.StartingItems, 1)
    return item
  end
end

local function NumberInInventory(inventory, name)
  return shopping.NumberStackableElements(core.InventoryContains(inventory, name, false, true)) + shopping.NumberStackableElements(courier.CourierContains(name))
end

local function HasBoots(inventory)
  local boots = {
    "Item_Marchers",
    "Item_Steamboots",
  }
  for _, name in ipairs(boots) do
    if NumberInInventory(inventory, name) > 0 then
      return true
    end
  end
  return false
end

function shopping.GetNextItemToBuy()
  if HoN.GetMatchTime() <= 0 then
    return PreGameItems()
  end
  local inventory = core.unitSelf:GetInventory(true)
  if NumberInInventory(inventory, "Item_HealthPotion") < 3 then
    return "Item_HealthPotion"
  elseif NumberInInventory(inventory, "Item_ManaRegen3") <= 0 then
    if NumberInInventory(inventory, "Item_GuardianRing") <= 0 then
      return "Item_GuardianRing"
    elseif NumberInInventory(inventory, "Item_Scarab") <= 0 then
      return "Item_Scarab"
    end
  elseif not HasBoots(inventory) then
    return "Item_Marchers"
  elseif NumberInInventory(inventory, "Item_Steamboots") <= 0 then
    if NumberInInventory(inventory, "Item_BlessedArmband") <= 0 then
      return "Item_BlessedArmband"
    elseif NumberInInventory(inventory, "Item_GlovesOfHaste") <= 0 then
      return "Item_GlovesOfHaste"
    end
  elseif NumberInInventory(inventory, "Item_LifeSteal5") <= 0 then
    if NumberInInventory(inventory, "Item_TrinketOfRestoration") <= 0 then
      return "Item_TrinketOfRestoration"
    elseif NumberInInventory(inventory, "Item_HungrySpirit") <= 0 then
      return "Item_HungrySpirit"
    else
      return "Item_LifeSteal5"
    end
  elseif NumberInInventory(inventory, "Item_SolsBulwark") <= 0 then
    return "Item_SolsBulwark"
  elseif NumberInInventory(inventory, "Item_DaemonicBreastplate") <= 0 then
    return "Item_DaemonicBreastplate"
  end
end

local function ItemToSell()
  local inventory = core.unitSelf:GetInventory()
  local prioList = {
    "Item_RunesOfTheBlight",
    "Item_MinorTotem"
  }
  for _, name in ipairs(prioList) do
    local item = core.InventoryContains(inventory, name)
    if core.NumberElements(item) > 0 then
      return item[1]
    end
  end
  return nil
end

local function ItemCombines(inventory, item)
  if item == "Item_Scarab" then
    return true
  elseif item == "Item_GlovesOfHaste" then
    return true
  end
  return false
end

local function GetSpaceNeeded(inventoryHero, inventoryCourier)
  local count = core.NumberElements(inventoryCourier) - (6 - core.NumberElements(inventoryHero))
  for i = 1, 6, 1 do
    local item = inventoryCourier[i]
    if item then
      local name = item:GetName()
      local heroHas = core.InventoryContains(inventoryHero, name)
      if core.NumberElements(heroHas) > 0 and item:GetRechargeable() or ItemCombines(inventoryHero, name) then
        count = count - 1
      end
    end
  end
  return max(count, 0)
end

local function SellItems()
  if courier.HasCourier() then
    local unitSelf = core.unitSelf
    local unitCourier = courier.unitCourier
    if Vector3.Distance2DSq(unitSelf:GetPosition(), unitCourier:GetPosition()) < 300*300 then
      local spaceNeeded = GetSpaceNeeded(unitSelf:GetInventory(), unitCourier:GetInventory())
      for i = 1, spaceNeeded, 1 do
        local itemTosell = ItemToSell()
        if itemTosell then
          unitSelf:Sell(itemTosell)
        end
      end
    end
  end
end

behaviorLib.pushingStrUtilMul = 1

moonqueen.bReportBehavior = true
moonqueen.bDebugUtility = true

moonqueen.skills = {}
local skills = moonqueen.skills

moonqueen.tSkills = {
  4, 0, 0, 4, 0,
  3, 0, 4, 0, 4,
  3, 1, 1, 1, 2,
  3, 2, 2, 2, 4,
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

function moonqueen:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  SellItems()
  -- custom code here
end

moonqueen.onthinkOld = moonqueen.onthink
moonqueen.onthink = moonqueen.onthinkOverride

function moonqueen:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride

function behaviorLib.PositionSelfExecute(botBrain)
  local unitSelf = core.unitSelf
  local vecMyPosition = unitSelf:GetPosition()

  if core.unitSelf:IsChanneling() then
    return
  end

  local vecDesiredPos = vecMyPosition
  vecDesiredPos, _ = behaviorLib.PositionSelfLogic(botBrain)

  if vecDesiredPos then
    return behaviorLib.MoveExecute(botBrain, vecDesiredPos)
  else
    return false
  end
end
behaviorLib.PositionSelfBehavior["Execute"] = behaviorLib.PositionSelfExecute

local function NearbyCreepCount(botBrain, center, radius)
  local count = 0
  local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
  local enemies = unitsLocal.EnemyCreeps

  for _,unit in pairs(enemies) do
    count = count + 1
  end
  return count
end

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 10
  local time = HoN.GetMatchTime()
  local counter = HoN.GetMatchTime()-ultDuration


  --jos tornin rangella ni ei mennä
  if core.GetClosestEnemyTower(core.unitSelf:GetPosition(), 950) then
    return -1000
  end

  if counter < 20000 then
    return 200
  end

  if skills.abilNuke:CanActivate() then
    nUtil = nUtil + 20
  end

  local creeps = NearbyCreepCount(moonqueen, hero:GetPosition(), 700)

  if skills.abilUltimate:CanActivate() and creeps < 3 then
    nUtil = nUtil + 300
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

    local abilUltimate = skills.abilUltimate
    if not bActionTaken and nLastHarassUtility > 50 then
      if abilUltimate:CanActivate() and unitSelf:GetMana() > 149 then
        local nRange = 600
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbility(botBrain, abilUltimate)
          ultDuration = HoN.GetMatchTime()
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end

    local abilNuke = skills.abilNuke
    if abilNuke:CanActivate() and core.unitSelf:GetLevel() > 2 then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
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


local function RetreatFromThreatUtilityOverride(botBrain)

  local selfPosition = core.unitSelf:GetPosition()

  if core.GetClosestEnemyTower(selfPosition, 950) then
    return 10000
  end

  return behaviorLib.RetreatFromThreatUtility(botBrain)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = RetreatFromThreatUtilityOverride

local function DPSPushingUtilityOverride(myHero)
  local modifier = 1 + myHero:GetAbility(1):GetLevel()*0.3
  return moonqueen.DPSPushingUtilityOld(myHero) * modifier
end
moonqueen.DPSPushingUtilityOld = behaviorLib.DPSPushingUtility
behaviorLib.DPSPushingUtility = DPSPushingUtilityOverride

function behaviorLib.HealthPotUtilFn(nHealthMissing)
  --Roughly 20+ when we are down 400 hp
  --  Fn which crosses 20 at x=400 and 40 at x=650, convex down
  if nHealthMissing > 250 then
    return 100
  end
  return 0
end
