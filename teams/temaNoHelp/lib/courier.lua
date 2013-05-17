local _G = getfenv(0)
local herobot = _G.object

local tinsert, tremove = _G.table.insert, _G.table.remove

herobot.courier = herobot.courier or {}

local core, courier = herobot.core, herobot.courier

function courier.HasCourier()
  local unitCourier = courier.unitCourier
  if unitCourier and unitCourier:IsValid() then
    return true
  else
    local allUnits = HoN.GetUnitsInRadius(Vector3.Create(), 99999, core.UNIT_MASK_ALIVE + core.UNIT_MASK_UNIT)
    for key, unit in pairs(allUnits) do
      if unit:GetTeam() == core.myTeam and core.IsCourier(unit) and unit:IsValid() then
        courier.unitCourier = unit
        return true
      end
    end
  end
  courier.unitCourier = nil
  return false
end

local function ItemsInStash()
  local inventory = core.unitSelf:GetInventory(true)
  for slot = 7, 12, 1 do
    local item = inventory[slot]
    if item then
      return true
    end
  end
  return false
end

local function MoveItems()
  local indexes = {}
  local inventory = core.unitSelf:GetInventory(true)
  for i=7, 12, 1 do
    local item = inventory[i]
    if item and item:IsValid() then
      tinsert(indexes, i)
    end
  end
  local unitCourier = courier.unitCourier
  local courierInventory = unitCourier:GetInventory()
  for i=1, 6, 1 do
    if #indexes <= 0 then
      return
    end
    if not courierInventory[i] then
      unitCourier:SwapItems(indexes[1], i)
      tremove(indexes, 1)
    end
  end
end

local function CourierFlys(unitCourier)
  return unitCourier:GetTypeName() == "Pet_FlyngCourier"
end

local function Danger(unitCourier)
  local vecCourier = unitCourier:GetPosition()
  local sortedUnits = {}
  local buildings = HoN.GetUnitsInRadius(vecCourier, 1000, core.UNIT_MASK_ALIVE + core.UNIT_MASK_BUILDING)
  local heroes = HoN.GetUnitsInRadius(vecCourier, 1000, core.UNIT_MASK_ALIVE + core.UNIT_MASK_HERO)
  sortedUnits = core.SortUnitsAndBuildings(buildings, sortedUnits)
  sortedUnits = core.SortUnitsAndBuildings(heroes, sortedUnits)
  return core.NumberElements(sortedUnits.enemyHeroes) + core.NumberElements(sortedUnits.enemyTowers) > 0
end

local function DeliverItems()
  local unitCourier = courier.unitCourier
  local abilDeliver = unitCourier:GetAbility(2)
  local abilReturn = unitCourier:GetAbility(3)
  if unitCourier:GetStashAccess() and ItemsInStash() then
    MoveItems()
  end
  local ItemsInCourier = core.NumberElements(unitCourier:GetInventory()) > 0
  if unitCourier:GetStashAccess() and not ItemsInCourier then
    return
  end
  local beha = unitCourier:GetBehavior()
  if not beha or beha:GetType() == "Guard" then
    if unitCourier:GetStashAccess() then
      core.OrderAbility(herobot, abilDeliver, true, true)
    else
      core.OrderAbility(herobot, abilReturn, true, true)
    end
  elseif CourierFlys(unitCourier) then
    local abilSpeed = unitCourier:GetAbility(0)
    local abilShield = unitCourier:GetAbility(1)
    if abilSpeed:CanActivate() then
      core.OrderAbility(herobot, abilSpeed)
    elseif abilShield:CanActivate() and Danger(unitCourier) then
      core.OrderAbility(herobot, abilShield)
    end
  elseif Danger(unitCourier) then
    local closestTower = core.GetClosestAllyTower(unitCourier:GetPosition(), 3000)
    if closestTower then
      core.OrderMoveToPosAndHoldClamp(herobot, unitCourier, closestTower:GetPosition())
    end
  end
end

function courier.UpgradeCourier()
  local unitCourier = courier.unitCourier
  if unitCourier and not CourierFlys(unitCourier) then
    local abilFly = unitCourier:GetAbility(0)
    if herobot:GetGold() >= 200 then
        core.OrderAbility(herobot, abilFly)
    end    
  end
end

local onthinkOld = herobot.onthink
function herobot:onthink(tGameVariables)
  onthinkOld(self, tGameVariables)

  if courier.HasCourier() then
    DeliverItems()
  end
end

function courier.CourierContains(item)
  local unitCourier = courier.unitCourier
  if unitCourier then
    return core.InventoryContains(unitCourier:GetInventory(), item)
  end
  return {}
end
