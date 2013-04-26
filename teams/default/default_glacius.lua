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
