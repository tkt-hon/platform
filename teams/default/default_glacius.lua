local _G = getfenv(0)
local glacius = _G.object

runfile 'bots/glacius/glacius_main.lua'
runfile 'bots/teams/default/utils/sitter.lua'


local tinsert = _G.table.insert
local core, behaviorLib = glacius.core, glacius.behaviorLib

behaviorLib.StartingItems = {"Item_GuardianRing", "Item_FlamingEye", "2 Item_MinorTotem", "Item_HealthPotion", "Item_RunesOfTheBlight"}

core.itemWard = nil

local function ShopUtilityOverride(botBrain)
  local seeded = behaviorLib.canAccessShopLast
  local utility = behaviorLib.ShopUtility(botBrain)
  if seeded ~= behaviorLib.canAccessShopLast then
    tinsert(behaviorLib.curItemList, 1, "Item_FlamingEye")
  end
  return utility
end
behaviorLib.ShopBehavior["Utility"] = ShopUtilityOverride

local function GetWardSpots()
  if core.myTeam == HoN.GetLegionTeam() then
    return {
      Vector3.Create(9896.0000, 4902.0000, 128.0000)
    }
  else
    return {
      Vector3.Create(6179.0000, 8218.0000, 128.0000)
    }
  end
end

local function IsSpotWarded(spot)
  local gadgets = HoN.GetUnitsInRadius(spot, 200, core.UNIT_MASK_GADGET + core.UNIT_MASK_ALIVE)
  for k, gadget in pairs(gadgets) do
    if gadget:GetTypeName() == "Gadget_FlamingEye" then
      return true
    end
  end
  return false
end

local function WardingUtility(botBrain)
  local ward = core.itemWard
  if ward then
    for _, spot in ipairs(GetWardSpots()) do
      if not IsSpotWarded(spot) then
        glacius.spot = spot
        return 50
      end
    end
  end
  return 0
end

local function WardingExecute(botBrain)
  local wardSpot = glacius.spot
  local ward = core.itemWard
  local unitSelf = core.unitSelf
  core.DrawXPosition(wardSpot)
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), wardSpot)
  local nRange = 600
  if nTargetDistanceSq < (nRange * nRange) then
    bActionTaken = core.OrderItemPosition(botBrain, unitSelf, ward, wardSpot)
  else
    bActionTaken = behaviorLib.MoveExecute(botBrain, wardSpot)
  end
  return bActionTaken
end

local WardingBehavior = {}
WardingBehavior["Utility"] = WardingUtility
WardingBehavior["Execute"] = WardingExecute
WardingBehavior["Name"] = "Warding spots"
tinsert(behaviorLib.tBehaviors, WardingBehavior)

local function funcFindItemsOverride(botBrain)
  local bUpdated = glacius.FindItemsOldOld(botBrain)

  if core.itemWard ~= nil and not core.itemWard:IsValid() then
    core.itemWard = nil
  end

  if core.itemWard then
    return
  end

  local inventory = core.unitSelf:GetInventory(true)
  for slot = 1, 12, 1 do
    local curItem = inventory[slot]
    if curItem then
      if core.itemWard == nil and curItem:GetName() == "Item_FlamingEye" then
        core.itemWard = core.WrapInTable(curItem)
      end
    end
  end
end
glacius.FindItemsOldOld = core.FindItems
core.FindItems = funcFindItemsOverride

local function PreGameExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  if not unitSelf.isSitter then
    return behaviorLib.PreGameExecute(botBrain)
  end
  local ward = core.itemWard
  local wardSpot = nil
  local gankSpot = nil
  local bActionTaken = false
  if core.myTeam == HoN.GetLegionTeam() then
    wardSpot = Vector3.Create(14326.0000, 4977.0000, 128.0000)
    gankSpot = Vector3.Create(13200.0000, 3500.0000, 128.0000)
  else
    wardSpot = Vector3.Create(2100.0000, 10900.0000, 128.0000)
    gankSpot = Vector3.Create(3100.0000, 12300.0000, 128.0000)
  end
  if ward and not IsSpotWarded(wardSpot) then
    core.DrawXPosition(wardSpot)
    local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), wardSpot)
    local nRange = 600
    if nTargetDistanceSq < (nRange * nRange) then
      bActionTaken = core.OrderItemPosition(botBrain, unitSelf, ward, wardSpot)
    else
      bActionTaken = behaviorLib.MoveExecute(botBrain, wardSpot)
    end
  elseif not ward and botBrain:GetGold() > 100 then
    return false
  else
    bActionTaken = behaviorLib.MoveExecute(botBrain, gankSpot)
  end
  return bActionTaken
end
behaviorLib.PreGameBehavior["Execute"] = PreGameExecuteOverride
