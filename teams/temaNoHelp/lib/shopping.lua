local _G = getfenv(0)
local shopper = _G.object

local tremove = _G.table.remove

shopper.shopping = shopper.shopping or {}

local core, behaviorLib, shopping = shopper.core, shopper.behaviorLib, shopper.shopping

shopping.itemList = shopping.itemList or {}

local function NeverUtility(botBrain)
  return 0
end
behaviorLib.ShopBehavior["Utility"] = NeverUtility

function shopping.NumberStackableElements(items)
  local count = 0
  for _, item in ipairs(items) do
    if item:GetRechargeable() then
      count = count + item:GetCharges()
    else
      count = count + 1
    end
  end
  return count
end

function shopping.GetNextItemToBuy()
  return shopping.itemList[1] or "Item_HomecomingStone"
end

local function PerformShop(botBrain)
  local hero = core.unitSelf
  local nextItemName = shopping.GetNextItemToBuy()
  if not nextItemName then
    return
  end
  local nextItem = HoN.GetItemDefinition(nextItemName)
  local itemCost = nextItem:GetCost()
  if itemCost <= botBrain:GetGold() then
    hero:PurchaseRemaining(nextItem)
  end
end

local onthinkOld = shopper.onthink
function shopper:onthink(tGameVariables)
  onthinkOld(self, tGameVariables)

  PerformShop(self)
end
