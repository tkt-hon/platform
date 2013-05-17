local _G = getfenv(0)
local forsaken = _G.object

local tinsert, tremove, max, format = _G.table.insert, _G.table.remove, _G.math.max, _G.string.formats

runfile 'bots/forsakenarcher/forsakenarcher_main.lua'
runfile 'bots/teams/temaNoHelp/lib/courier.lua'
runfile 'bots/teams/temaNoHelp/lib/shopping.lua'
runfile 'bots/teams/temaNoHelp/lib/healthregenbehavior.lua'
runfile 'bots/teams/temaNoHelp/lib/manaregenbehavior.lua'
runfile 'bots/teams/temaNoHelp/lib/lasthitting.lua'
runfile 'bots/teams/temaNoHelp/lib/ranges.lua'


local core, behaviorLib, eventsLib, shopping, courier = forsaken.core, forsaken.behaviorLib, forsaken.eventsLib, forsaken.shopping, forsaken.courier

behaviorLib.StartingItems = {"Item_RunesOfTheBlight", "Item_HealthPotion", "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem"}

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
  elseif not HasBoots(inventory) then
    return "Item_Marchers" 
  elseif NumberInInventory(inventory, "Item_PowerSupply") <= 0 then
    if NumberInInventory(inventory, "Item_ManaBattery") <= 0 then
      return"Item_ManaBattery"
    elseif NumberInInventory(inventory, "Item_MinorTotem") < 2 then
      return "Item_MinorTotem"
    else
      return "Item_PowerSupply"
    end
  elseif NumberInInventory(inventory, "Item_Steamboots") <= 0 then
    if NumberInInventory(inventory, "Item_BlessedArmband") <= 0 then
      return "Item_BlessedArmband"
    elseif NumberInInventory(inventory, "Item_GlovesOfHaste") <= 0 then
      return "Item_GlovesOfHaste"
    end

  elseif NumberInInventory(inventory, "Item_Shield2") <= 0 then
    if NumberInInventory(inventory, "Item_Lifetube") <= 0 then
      return "Item_Lifetube"
    elseif NumberInInventory(inventory, "Item_Beastheart") <= 0 then
      return "Item_Beastheart"
    else
      return "Item_IronBuckler"
    end


  elseif NumberInInventory(inventory, "Item_Lightning1") <= 0 then
    if NumberInInventory(inventory, "Item_GlovesOfHaste") <= 0 then
      return "Item_GlovesOfHaste"
    elseif NumberInInventory(inventory, "Item_Warhammer") <= 0 then
      return "Item_Warhammer"
    else
      return "Item_Lightning1"
    end

  elseif NumberInInventory(inventory, "Item_Sicarius") <= 0 then
    if NumberInInventory(inventory, "Item_Quickblade") <= 0 then
      return "Item_Quickblade"
    elseif NumberInInventory(inventory, "Item_Fleetfeet") <= 0 then
      return "Item_Fleetfeet"
    else
      return "Item_Sicarius"
    end
  elseif NumberInInventory(inventory, "Item_ManaBurn2") <= 0 then
    if NumberInInventory(inventory, "Item_Confluence") <= 0 then
      return "Item_Confluence"
    else
      return "Item_ManaBurn2"
    end
  elseif NumberInInventory(inventory, "Item_Weapon3") <= 0 then
    if NumberInInventory(inventory, "Item_Voulge") <= 0 then
      return "Item_Voulge"
    elseif NumberInInventory(inventory, "Item_Warhammer") < 2 then
      return "Item_Warhammer"
    end
  end
end

local function ItemToSell()
  local inventory = core.unitSelf:GetInventory()
  local prioList = {
    "Item_RunesOfTheBlight",
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

local onthinkOld = forsaken.onthink
local function onthinkOverride(self, tGameVariables)
  onthinkOld(self, tGameVariables)
  courier.UpgradeCourier()
  SellItems()
  -- custom code here
end
forsaken.onthink = onthinkOverride
