local _G = getfenv(0)
local herobot = _G.object

local tinsert, tremove = _G.table.insert, _G.table.remove

herobot.courier = herobot.courier or {}

local skills = {}

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
        skills.abilDeliver = unit:GetAbility(2)
        skills.abilReturn = unit:GetAbility(3)
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

local function DeliverItems()
  local unitCourier = courier.unitCourier
  if unitCourier:GetStashAccess() and ItemsInStash() then
    MoveItems()
  end
  local beha = unitCourier:GetBehavior()
  if not beha or beha:GetType() == "Guard" then
    core.OrderAbility(herobot, skills.abilDeliver)
    core.OrderAbility(herobot, skills.abilReturn, true, true)
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
