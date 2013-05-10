-- Courier for 1v1

local _G = getfenv(0)
local object = _G.object
local core = object.core
local BotEcho = object.core.BotEcho

local tinsert = _G.table.insert


local M = {}
M.UNIT = 0x0000001
M.BUILDING = 0x0000002
M.HERO = 0x0000004
M.POWERUP = 0x0000008
M.GADGET = 0x0000010
M.ALIVE = 0x0000020
M.CORPSE = 0x0000040

MASKS = M


local function ComeToCourierUtility(botBrain)
  local matchTime = HoN.GetMatchTime()
  if botBrain.bCourierOnWay and matchTime > botBrain.nCourierMeetupTime then 
    return 65
  end
  return 0
end

local function ComeToCourierExecute(botBrain) 
  local safePos = core.GetClosestAllyTower(core.unitSelf:GetPosition()):GetPosition()
  object.behaviorLib.MoveExecute(botBrain, safePos)
end

local CourierBehavior = {}
CourierBehavior["Utility"] = ComeToCourierUtility
CourierBehavior["Execute"] = ComeToCourierExecute
CourierBehavior["Name"] = "My people need me"
tinsert(object.behaviorLib.tBehaviors, CourierBehavior)

-- https://github.com/samitheberber/honbotstack/blob/master/utils/courier_controlling/selector.lua
local function GetCourier(bot)
  local teamId = bot:GetTeam()
  local allUnits = HoN.GetUnitsInRadius(Vector3.Create(), 99999, MASKS.ALIVE + MASKS.UNIT)
  for key, unit in pairs(allUnits) do
    local typeName = unit:GetTypeName()
    if unit:GetTeam() == teamId and core.IsCourier(unit) then
      return unit
    end
  end
  return nil
end

local function ReturnHome(bot, courier)
  bot:OrderAbility(courier:GetAbility(3))
  bot.bCourierOnWay = false
end

local function DeliverItems(bot, courier)
  local deliver = courier:GetAbility(2)
  bot:OrderAbility(deliver)
  bot.bCourierOnWay = true
  bot.nCourierMeetupTime = HoN.GetMatchTime() + 10000
end


-- below from https://github.com/samitheberber/honbotstack/blob/master/utils/courier_controlling/item_handler.lua

local function is_in_table(table, value)
  for _, v in ipairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

local function ItemsInInventory(inventory)
  local items = 0
  for i = 1, 6, 1 do
    if inventory[i] then
      items = items +1
    end
  end
  return items
end

local function HeroHasStackableItems(hero)
  local items = {}
  local inventory = hero:GetInventory(true)
  local stackableInHero = {}
  for i = 1, 6, 1 do
    local item = inventory[i]
    if item and item:GetCharges() > 0 then
      table.insert(stackableInHero, item:GetType())
    end
  end
  for i = 7, 12, 1 do
    local item = inventory[i]
    if item and is_in_table(stackableInHero, item:GetType()) then
      table.insert(items, i)
    end
  end
  return items
end

local function OtherItems(hero, oldItems)
  local items = {}
  local inventory = hero:GetInventory(true)
  local itemsInHero = ItemsInInventory(inventory)
  local emptySlots = 6 - itemsInHero
  for i = 7, 12, 1 do
    if emptySlots <= 0 then
      break
    end
    local item = inventory[i]
    if item and not is_in_table(oldItems, i) then
      table.insert(items, i)
      emptySlots = emptySlots - 1
    end
  end
  return items
end

local function ItemIndexes(hero)
  local items = HeroHasStackableItems(hero)
  local otherItems = OtherItems(hero, items)
  if not otherItems then return {} end
  for _, v in ipairs(otherItems) do
    table.insert(items, v)
  end
  return items
end

local function MoveItemsToCourier(courier, items)
  local inventory = courier:GetInventory()
  local itemsMoved = 0
  for slot = 1, 6, 1 do
    local slotItem = inventory[slot]
    if not slotItem then
      local item = items[1]
      if not item then
        return
      end
      courier:SwapItems(item, slot)
      table.remove(items, 1)
    end
  end
end

local function onthinkCourier(bot)
  local courier = GetCourier(bot)
  local hero = bot:GetHeroUnit()

  -- TODO: buy new?
  if not courier then return end
  
  if not hero:IsAlive() then 
    ReturnHome(bot, courier)
  end

  if not courier:GetStashAccess() then 
    if ItemsInInventory(courier:GetInventory()) == 0 then
      if courier:GetBehavior() and courier:GetBehavior():GetType() ~= "Move" then
        ReturnHome(bot, courier)
      end
    end
    return 
  end

  local itemsInCourier = ItemsInInventory(courier:GetInventory())
  if itemsInCourier > 0 then
    return
  end
  local items = ItemIndexes(hero)
  MoveItemsToCourier(courier, items)

  if ItemsInInventory(courier:GetInventory()) > 0 then 
    DeliverItems(bot, courier)
  end
end

object.onthinkCourier = onthinkCourier