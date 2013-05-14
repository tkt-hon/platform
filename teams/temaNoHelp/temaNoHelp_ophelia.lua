local _G = getfenv(0)
local ophelia = _G.object
local tinsert, tremove, max = _G.table.insert, _G.table.remove, _G.math.max

ophelia.heroName = "Hero_Ophelia"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/temaNoHelp/lib/avoidmagmus.lua'
runfile 'bots/teams/temaNoHelp/lib/avoidchronos.lua'
runfile 'bots/teams/temaNoHelp/lib/courier.lua'
runfile 'bots/teams/temaNoHelp/lib/shopping.lua'
runfile 'bots/teams/temaNoHelp/lib/lasthitting.lua'

ophelia.bReportBehavior = true
ophelia.bDebugUtility = true

local core, behaviorLib, shopping, courier = ophelia.core, ophelia.behaviorLib, ophelia.shopping, ophelia.courier

behaviorLib.StartingItems = { "Item_HealthPotion", "Item_RunesOfTheBlight", "Item_MinorTotem",  "Item_TrinketOfRestoration"}

local function PreGameItems()
  for _, item in ipairs(behaviorLib.StartingItems) do
    tremove(behaviorLib.StartingItems, 1)
    return item
  end
  return nil
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

local function IsSpotCounterWarded(spot)
  local gadgets = HoN.GetUnitsInRadius(spot, 800, core.UNIT_MASK_GADGET + core.UNIT_MASK_ALIVE)
  for k, gadget in pairs(gadgets) do
    if gadget:GetTypeName() == "Gadget_Item_ManaEye" then
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
  local spot = core.teamBotBrain.antimagmus.GetAntiMagmusWardSpot()
  if spot and not IsSpotCounterWarded(spot) and NumberInInventory(inventory, "Item_ManaEye") <= 0 then
    core.BotEcho("need ward")
    return "Item_ManaEye"
  elseif not HasBoots(inventory) then
    return "Item_Marchers"
  elseif NumberInInventory(inventory, "Item_MagicArmor2") + NumberInInventory(inventory, "Item_MysticVestments") <= 0 then
    return "Item_MysticVestments"
  elseif NumberInInventory(inventory, "Item_Steamboots") <= 0 then
    if NumberInInventory(inventory, "Item_BlessedArmband") <= 0 then
      return "Item_BlessedArmband"
    elseif NumberInInventory(inventory, "Item_GlovesOfHaste") <= 0 then
      return "Item_GlovesOfHaste"
    end
  elseif NumberInInventory(inventory, "Item_MagicArmor2") <= 0 then
    if NumberInInventory(inventory, "Item_HelmOfTheVictim") <= 0 then
      return "Item_HelmOfTheVictim"
    elseif NumberInInventory(inventory, "Item_TrinketOfRestoration") < 2 then
      return "Item_TrinketOfRestoration"
    end
  elseif NumberInInventory(inventory, "Item_LifeSteal5") <= 0 then
    if NumberInInventory(inventory, "Item_TrinketOfRestoration") <= 0 then
      return "Item_TrinketOfRestoration"
    elseif NumberInInventory(inventory, "Item_HungrySpirit") <= 0 then
      return "Item_HungrySpirit"
    elseif NumberInInventory(inventory, "Item_ManaRegen3") <= 0 then
      if NumberInInventory(inventory, "Item_GuardianRing") <= 0 then
        return "Item_GuardianRing"
      elseif NumberInInventory(inventory, "Item_Scarab") <= 0 then
        return "Item_Scarab"
      end
    else
      return "Item_LifeSteal5"
    end
  elseif NumberInInventory(inventory, "Item_SolsBulwark") <= 0 then
    return "Item_SolsBulwark"
  elseif NumberInInventory(inventory, "Item_DaemonicBreastplate") <= 0 then
    if NumberInInventory(inventory, "Item_Warpcleft") <= 0 then
      return "Item_Warpcleft"
    elseif NumberInInventory(inventory, "Item_Ringmail") <= 0 then
      return "Item_Ringmail"
    elseif NumberInInventory(inventory, "Item_DaemonicBreastplate") <= 0 then
      return "Item_DaemonicBreastplate"
    end
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

function ophelia:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  SellItems()

  -- custom code here
end
ophelia.onthinkOld = ophelia.onthink
ophelia.onthink = ophelia.onthinkOverride


local function RevealBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local vecAntiMagSpot = core.teamBotBrain.antimagmus.GetAntiMagmusWardSpot()
  if vecAntiMagSpot and not IsSpotCounterWarded(vecAntiMagSpot) and core.itemCounterWard then
    return 50
  end
  return 0
end

local function RevealBehaviorExecute(botBrain)
  local vecAntiMagSpot = core.teamBotBrain.antimagmus.GetAntiMagmusWardSpot()
  local ward = core.itemCounterWard
  if vecAntiMagSpot and ward then
    return core.OrderItemPosition(botBrain, core.unitSelf, ward, vecAntiMagSpot, false)
  end
  return false
end

local RevealBehavior = {}
RevealBehavior["Utility"] = RevealBehaviorUtility
RevealBehavior["Execute"] = RevealBehaviorExecute
RevealBehavior["Name"] = "Revealing creep with spell"
tinsert(behaviorLib.tBehaviors, RevealBehavior)

local FindItemsOld = core.FindItems
local function funcFindItemsOverride(botBrain)
  local bUpdated = FindItemsOld(botBrain)

  if core.itemCounterWard ~= nil and not core.itemCounterWard:IsValid() then
    core.itemCounterWard = nil
  end

  if bUpdated then
    if core.itemCounterWard then
      return
    end

    local inventory = core.unitSelf:GetInventory(true)
    for slot = 1, 12, 1 do
      local curItem = inventory[slot]
      if curItem then
        if core.itemCounterWard == nil and curItem:GetName() == "Item_ManaEye" then
          core.itemCounterWard = core.WrapInTable(curItem)
        end
      end
    end
  end
  return bUpdated
end
core.FindItems = funcFindItemsOverride
