local _G = getfenv(0)
local rhapsody = _G.object

local tinsert, tremove, max, format = _G.table.insert, _G.table.remove, _G.math.max, _G.string.formats

runfile 'bots/rhapsody/rhapsody_main.lua'
runfile 'bots/teams/temaNoHelp/lib/courier.lua'
runfile 'bots/teams/temaNoHelp/lib/shopping.lua'
runfile 'bots/teams/temaNoHelp/lib/healthregenbehavior.lua'
runfile 'bots/teams/temaNoHelp/lib/manaregenbehavior.lua'
runfile 'bots/teams/temaNoHelp/lib/lasthitting.lua'
runfile 'bots/teams/temaNoHelp/lib/ranges.lua'
runfile 'bots/teams/temaNoHelp/lib/avoidmagmus.lua'
runfile 'bots/teams/temaNoHelp/lib/avoidchronos.lua'

local core, behaviorLib, eventsLib, shopping, courier = rhapsody.core, rhapsody.behaviorLib, rhapsody.eventsLib, rhapsody.shopping, rhapsody.courier

--rhapsody.bReportBehavior = true
--rhapsody.bDebugUtility = true

local function IsSpotCounterWarded(spot)
  local gadgets = HoN.GetUnitsInRadius(spot, 800, core.UNIT_MASK_GADGET + core.UNIT_MASK_ALIVE)
  for k, gadget in pairs(gadgets) do
    if gadget:GetTypeName() == "Gadget_Item_ManaEye" then
      return true
    end
  end
  return false
end

behaviorLib.StartingItems = {"Item_RunesOfTheBlight", "Item_HealthPotion", "Item_ManaPotion", "Item_ManaPotion", "Item_MinorTotem", "Item_MinorTotem"}

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
    "Item_PlatedGreaves"
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
  local spot = core.teamBotBrain.antimagmus and core.teamBotBrain.antimagmus.GetAntiMagmusWardSpot() or false
  if spot and not IsSpotCounterWarded(spot) and NumberInInventory(inventory, "Item_ManaEye") <= 0 then
    core.BotEcho("need ward")
    return "Item_ManaEye"
  elseif NumberInInventory(inventory, "Item_HealthPotion") < 2 then
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
  elseif NumberInInventory(inventory, "Item_PlatedGreaves") <= 0 then
    if NumberInInventory(inventory, "Item_ShieldOfTheFive") <= 0 then
      if NumberInInventory(inventory, "Item_Ringmail") <= 0 then
        return "Item_Ringmail"
      elseif NumberInInventory(inventory, "Item_MinorTotem") <= 0 then
        return "Item_MinorTotem"
      else
        return "Item_ShieldOfTheFive"
      end
    else
      return "Item_PlatedGreaves"
    end

  elseif NumberInInventory(inventory, "Item_Astrolabe") <= 0 then
    if NumberInInventory(inventory, "Item_Strength5") <= 0 then
      return "Item_Strength5"
    elseif NumberInInventory(inventory, "Item_MysticPotpourri") <= 0 then
      return "Item_MysticPotpourri"
    else
      return "Item_Astrolabe"
    end

  elseif NumberInInventory(inventory, "Item_Shield2") <= 0 then
    if NumberInInventory(inventory, "Item_Lifetube") <= 0 then
      return "Item_Lifetube"
    elseif NumberInInventory(inventory, "Item_Beastheart") <= 0 then
      return "Item_Beastheart"
    else
      return "Item_IronBuckler"
    end


  elseif NumberInInventory(inventory, "Item_BehemothsHeart") <= 0 then
    if NumberInInventory(inventory, "Item_Beastheart") <= 0 then
      return "Item_Beastheart"
    elseif NumberInInventory(inventory, "Item_AxeOfTheMalphai") <= 0 then
      return "Item_AxeOfTheMalphai"
    else
      return "Item_BehemothsHeart"
    end
  end
end

local function ItemToSell()
  local inventory = core.unitSelf:GetInventory()
  local prioList = {
    "Item_RunesOfTheBlight",
    "Item_ManaPotion",
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

local onthinkOld = rhapsody.onthink
local function onthinkOverride(self, tGameVariables)
  onthinkOld(self, tGameVariables)
  courier.UpgradeCourier()
  SellItems()
  -- custom code here
end
rhapsody.onthink = onthinkOverride

local function RevealBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local vecAntiMagSpot = core.teamBotBrain.antimagmus and core.teamBotBrain.antimagmus.GetAntiMagmusWardSpot() or false
  if vecAntiMagSpot and not IsSpotCounterWarded(vecAntiMagSpot) and core.itemCounterWard then
    return 50
  end
  return 0
end

local function RevealBehaviorExecute(botBrain)
  local vecAntiMagSpot = core.teamBotBrain.antimagmus and core.teamBotBrain.antimagmus.GetAntiMagmusWardSpot() or false
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
  return bUpdated or core.itemCounterWard or false
end
core.FindItems = funcFindItemsOverride
