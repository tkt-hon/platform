local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/trashteam/utils/predictiveLasthitting.lua'
runfile 'bots/teams/trashteam/utils/EasyCourier.lua'

local courier = CourierUtils()

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib


behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_DuckBoots", "Item_MinorTotem", "Item_PretendersCrown" }
behaviorLib.LaneItems = { "Item_IronShield", "Item_Marchers", "Item_Steamboots", "Item_WhisperingHelm" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }

moonqueen.skills = {}
local skills = moonqueen.skills

core.itemGeoBane = nil

moonqueen.tSkills = {
  2, 1, 2, 1, 1,
  3, 1, 2, 2, 0,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
function moonqueen:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilBounce = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
    skills.taunt = unitSelf:GetAbility(8)
  end
  moonqueen:SkillBuildOld()
end
moonqueen.SkillBuildOld = moonqueen.SkillBuild
moonqueen.SkillBuild = moonqueen.SkillBuildOverride

---------------------------------------------------------------
--            ShopUtility override                           --
---------------------------------------------------------------
-- @param: none
-- @return: none
function ShopUtilityOverride(botBrain)
  --BotEcho('CanAccessStash: '..tostring(core.unitSelf:CanAccessStash()))

  --just got into shop access, try buying
  local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
  local nextitemCost = nextItemDef:GetCost()
  local gold = botBrain:GetGold()
  if gold > nextitemCost then
    behaviorLib.finishedBuying = false
  end

  local utility = 0
  if not behaviorLib.finishedBuying then
    if not core.teamBotBrain.bPurchasedThisFrame then
      utility = 99
    end
  end

  if botBrain.bDebugUtility == true and utility ~= 0 then
    BotEcho(format("  ShopUtility: %g", utility))
  end

  return utility
end

function ShopExecuteOverride(botBrain)
--[[Current algorithm:
    A) Buy items from the list
  B) Swap items to complete recipes
    C) Swap items to fill inventory, prioritizing...
       1. Boots / +ms
     2. Magic Armor
       3. Homecoming Stone
       4. Most Expensive Item(s) (price decending)
    --]]

  if object.bUseShop == false then
    return
  end

  --Space out your buys
  if behaviorLib.nextBuyTime > HoN.GetGameTime() then
    return
  end

  behaviorLib.nextBuyTime = HoN.GetGameTime()

  if behaviorLib.buyState == behaviorLib.BuyStateUnknown then
    --Determine where in the pattern we are (mostly for reloads)
    behaviorLib.DetermineBuyState(botBrain)
  end

  local unitSelf = core.unitSelf

  local bChanged = false
  local bShuffled = false
  local bGoldReduced = false
  local inventory = core.unitSelf:GetInventory(true)
  local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)

  --For our first frame of this execute
  if core.GetLastBehaviorName(botBrain) ~= core.GetCurrentBehaviorName(botBrain) then
    if nextItemDef:GetName() ~= core.idefHomecomingStone:GetName() then   
      --Seed a TP stone into the buy items after 1 min
      local sName = "Item_HomecomingStone"
      local nTime = HoN.GetMatchTime()
      if nTime > core.MinToMS(1) then
        tinsert(behaviorLib.curItemList, 1, sName)
        nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
      end
    end
  end

  if behaviorLib.printShopDebug then
    BotEcho("============ BuyItems ============")
    --printInventory(inventory)
    if nextItemDef then
      BotEcho("BuyItems - nextItemDef: "..nextItemDef:GetName())
    else
      BotEcho("ERROR: BuyItems - Invalid ItemDefinition returned from DetermineNextItemDef")
    end
  end

  if nextItemDef then
    core.teamBotBrain.bPurchasedThisFrame = true

    --open up slots if we don't have enough room in the stash + inventory
    local componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
    local slotsOpen = behaviorLib.NumberSlotsOpen(inventory)

    if behaviorLib.printShopDebug then
      BotEcho("Component defs for "..nextItemDef:GetName()..":")
      core.printGetNameTable(componentDefs)
      BotEcho("Checking if we need to sell items...")
      BotEcho("  #components: "..#componentDefs.."  slotsOpen: "..slotsOpen)
    end

    if #componentDefs > slotsOpen + 1 then --1 for provisional slot
      behaviorLib.SellLowestItems(botBrain, #componentDefs - slotsOpen - 1)
    elseif #componentDefs == 0 then
      behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
    end

    local goldAmtBefore = botBrain:GetGold()
    unitSelf:PurchaseRemaining(nextItemDef)

    local goldAmtAfter = botBrain:GetGold()
    bGoldReduced = (goldAmtAfter < goldAmtBefore)
    bChanged = bChanged or bGoldReduced

    --if bGoldReduced and nextItemDef ~= nil then
    --  botBrain:Chat("Hey all! I just bought a " .. nextItemDef:GetName())
    --end

    --Check to see if this purchased item has uncombined parts
    componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
    if #componentDefs == 0 then
      behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
    end
  end

  bShuffled = behaviorLib.SortInventoryAndStash(botBrain)
  bChanged = bChanged or bShuffled

  --BotEcho("bChanged: "..tostring(bChanged).."  bShuffled: "..tostring(bShuffled).."  bGoldReduced:"..tostring(bGoldReduced))

  if bChanged == false then
    BotEcho("Finished Buying!")
    behaviorLib.finishedBuying = true
  end
end

ShopUtilityOverrideOld = behaviorLib.ShopBehavior["Utility"]
behaviorLib.ShopBehavior["Utility"] = ShopUtilityOverride
behaviorLib.ShopBehavior["Execute"] = ShopExecuteOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function moonqueen:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  courier.tick(self)
  core.BotEcho(courier.GetState())

  -- custom code here
end
moonqueen.onthinkOld = moonqueen.onthink
moonqueen.onthink = moonqueen.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function moonqueen:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent = moonqueen.oncombateventOverride
