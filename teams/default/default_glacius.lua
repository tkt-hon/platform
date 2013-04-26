local _G = getfenv(0)
local glacius = _G.object

runfile 'bots/glacius/glacius_main.lua'
runfile 'bots/teams/default/utils/sitter.lua'

local tinsert = _G.table.insert
local core, behaviorLib = glacius.core, glacius.behaviorLib

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
      Vector3.Create(14326.0000, 4977.0000, 128.0000),
      Vector3.Create(9896.0000, 4902.0000, 128.0000),
    }
  else
    return {
      Vector3.Create(4829.0000, 13921.0000, 128.0000),
      Vector3.Create(6179.0000, 8218.0000, 128.0000)
    }
  end
end

local function GetWardFromBag(unitSelf)
  local tItems = unitSelf:GetInventory()
  for _, item in ipairs(tItems) do
    if item:GetTypeName() == "Item_FlamingEye" then
      return item
    end
  end
  return nil
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
  local ward = GetWardFromBag(core.unitSelf)
  if ward then
    for _, spot in ipairs(GetWardSpots()) do
      if not IsSpotWarded(spot) then
        glacius.ward = ward
        glacius.spot = spot
        return 50
      end
    end
  end
  return 0
end

local function WardingExecute(botBrain)
  local wardSpot = glacius.spot
  local ward = glacius.ward
  local unitSelf = core.unitSelf
  core.DrawXPosition(wardSpot)
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), wardSpot)
  local nRange = 600
  if nTargetDistanceSq < (nRange * nRange) then
    bActionTaken = core.OrderItemPosition(botBrain, unitSelf, ward, wardSpot)
  else
    bActionTaken = core.OrderMoveToPosClamp(botBrain, unitSelf, wardSpot)
  end
  return bActionTaken
end

local WardingBehavior = {}
WardingBehavior["Utility"] = WardingUtility
WardingBehavior["Execute"] = WardingExecute
WardingBehavior["Name"] = "Warding spots"
tinsert(behaviorLib.tBehaviors, WardingBehavior)
