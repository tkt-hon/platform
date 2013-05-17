local _G = getfenv(0)
local hammer = _G.object

local tinsert, tremove, max, format = _G.table.insert, _G.table.remove, _G.math.max, _G.string.formats

runfile 'bots/hammerstorm/hammerstorm_main.lua'
runfile 'bots/teams/temaNoHelp/lib/courier.lua'
runfile 'bots/teams/temaNoHelp/lib/shopping.lua'
runfile 'bots/teams/temaNoHelp/lib/lasthitting.lua'
runfile 'bots/teams/temaNoHelp/lib/ranges.lua'
runfile 'bots/teams/temaNoHelp/lib/avoidmagmus.lua'
runfile 'bots/teams/temaNoHelp/lib/avoidchronos.lua'

local core, behaviorLib, eventsLib, shopping, courier = hammer.core, hammer.behaviorLib, hammer.eventsLib, hammer.shopping, hammer.courier

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_GuardianRing", "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_MinorTotem"}

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
  if NumberInInventory(inventory, "Item_HealthPotion") < 2 then
    return "Item_HealthPotion"
  elseif NumberInInventory(inventory, "Item_LifeSteal5") + NumberInInventory(inventory, "Item_ManaRegen3") <= 0 then
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
  elseif NumberInInventory(inventory, "Item_ElderParasite") <= 0 then
    if NumberInInventory(inventory, "Item_GlovesOfHaste") <= 0 then
      return "Item_GlovesOfHaste"
    elseif NumberInInventory(inventory, "Item_Beastheart") <= 0 then
      return "Item_Beastheart"
    else
      return "Item_ElderParasite"
    end
  elseif NumberInInventory(inventory, "Item_BehemothsHeart") <= 0 then
    if NumberInInventory(inventory, "Item_Beastheart") <= 0 then
      return "Item_Beastheart"
    elseif NumberInInventory(inventory, "Item_AxeOfTheMalphai") <= 0 then
      return "Item_AxeOfTheMalphai"
    else
      return "Item_BehemothsHeart"
    end
  elseif NumberInInventory(inventory, "Item_Freeze") <= 0 then
    if NumberInInventory(inventory, "Item_Strength6") <= 0 then
      if NumberInInventory(inventory, "Item_MightyBlade") <= 0 then
        return "Item_MightyBlade"
      elseif NumberInInventory(inventory, "Item_BlessedArmband") <= 0 then
        return "Item_BlessedArmband"
      else
        return "Item_Strength6"
      end
    elseif NumberInInventory(inventory, "Item_Confluence") <= 0 then
      return "Item_Confluence"
    elseif NumberInInventory(inventory, "Item_Glowstone") <= 0 then
      return "Item_Glowstone"
    else
      return "Item_Freeze"
    end
  end
end

local function ItemToSell()
  local inventory = core.unitSelf:GetInventory()
  local prioList = {
    "Item_RunesOfTheBlight",
    "Item_MinorTotem",
    "Item_HealthPotion"
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
  return item == "Item_Scarab" or item == "Item_GlovesOfHaste" or item == "Item_LifeSteal5" or item == "Item_ElderParasite" or item == "Item_BehemothsHeart" or item == "Item_Strength6" or item == "Item_Freeze"
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

local onthinkOld = hammer.onthink
local function onthinkOverride(self, tGameVariables)
  onthinkOld(self, tGameVariables)

  SellItems()
  -- custom code here
end
hammer.onthink = onthinkOverride
