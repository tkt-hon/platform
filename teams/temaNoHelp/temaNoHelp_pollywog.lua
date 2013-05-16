local _G = getfenv(0)
local pollywog = _G.object

local tinsert, tremove, max = _G.table.insert, _G.table.remove, _G.math.max
local endGame = false


pollywog.heroName = "Hero_PollywogPriest"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/temaNoHelp/lib/courier.lua'
runfile 'bots/teams/temaNoHelp/lib/shopping.lua'
runfile 'bots/teams/temaNoHelp/lib/lasthitting.lua'
runfile 'bots/teams/temaNoHelp/lib/healthregenbehavior.lua'
runfile 'bots/teams/temaNoHelp/lib/manaregenbehavior.lua'
runfile 'bots/teams/temaNoHelp/lib/custom_unit_control.lua'
runfile 'bots/lib/rune_controlling/init.lua'


pollywog.bReportBehavior = true
pollywog.bDebugUtility = true

local core, behaviorLib, shopping, courier = pollywog.core, pollywog.behaviorLib, pollywog.shopping, pollywog.courier
local eventsLib = pollywog.eventsLib

behaviorLib.StartingItems = { "Item_HealthPotion", "Item_RunesOfTheBlight", "Item_MinorTotem", "Item_Intelligence5"}

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
  if NumberInInventory(inventory, "Item_HealthPotion") < 1 and not endGame then
    return "Item_HealthPotion"
  elseif NumberInInventory(inventory, "Item_Bottle") <= 0 then
    if NumberInInventory(inventory, "Item_HealthPotion") < 2 then
      return "Item_HealthPotion"
    else
      return "Item_Bottle"
    end
  elseif not HasBoots(inventory) then
    return "Item_Marchers"
  elseif NumberInInventory(inventory, "Item_Steamboots") <= 0 then
    if NumberInInventory(inventory, "Item_BlessedArmband") <= 0 then
      return "Item_BlessedArmband"
    elseif NumberInInventory(inventory, "Item_GlovesOfHaste") <= 0 then
      return "Item_GlovesOfHaste"
    end
  elseif NumberInInventory(inventory, "Item_Replenish") <= 0 then
    if NumberInInventory(inventory, "Item_Intelligence5") <= 0 then
      return "Item_Intelligence5"
    elseif NumberInInventory(inventory, "Item_BrainOfMaliken") <= 0 then
      return "Item_BrainOfMaliken"
    end
  elseif NumberInInventory(inventory, "Item_Shield2") <= 0 then
    if NumberInInventory(inventory, "Item_Beastheart") <= 0 then
      return "Item_Beastheart"
    elseif NumberInInventory(inventory, "Item_Lifetube") <= 0 then
      return "Item_Lifetube"
    elseif NumberInInventory(inventory, "Item_IronBuckler") <= 0 then
      endGame = true
      return "Item_IronBuckler"
    end
  elseif NumberInInventory(inventory, "Item_Summon") <= 0 then
    if NumberInInventory(inventory, "Item_NeophytesBook") <= 0 then
      return "Item_NeophytesBook"
    elseif NumberInInventory(inventory, "Item_BlessedArmband") <= 0 then
      return "Item_BlessedArmband"
    else
      return "Item_Summon"
    end
  elseif NumberInInventory(inventory, "Item_Dawnbringer") <= 0 then
    if NumberInInventory(inventory, "Item_Frozenlight") <= 0 then
      if NumberInInventory(inventory, "Item_Lightbrand") <= 0 then
        if NumberInInventory(inventory, "Item_NeophytesBook") <= 0 then
          return "Item_NeophytesBook"
        elseif NumberInInventory(inventory, "Item_ApprenticesRobe") <= 0 then
          return "Item_ApprenticesRobe"
        else
          return "Item_Lightbrand"
        end
      elseif NumberInInventory(inventory, "Item_Strength6") <= 0 then
        if NumberInInventory(inventory, "Item_MightyBlade") <= 0 then
          return "Item_MightyBlade"
        elseif NumberInInventory(inventory, "Item_BlessedArmband") <= 0 then
          return "Item_BlessedArmband"
        else
          return "Item_Strength6"
        end
      end
    elseif NumberInInventory(inventory, "Item_Sicarius") <= 0 then
      if NumberInInventory(inventory, "Item_Quickblade") <= 0 then
        return "Item_Quickblade"
      elseif NumberInInventory(inventory, "Item_Fleetfeet") <= 0 then
        return "Item_Fleetfeet"
      else
        return "Item_Sicarius"
      end
    end
  end
end

-- Staff of the masters, Restoration stone, Beheheart,

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

behaviorLib.pushingStrUtilMul = 1

pollywog.skills = {}
local skills = pollywog.skills

pollywog.tSkills = {
  0, 2, 0, 1, 0,
  3, 0, 1, 1, 1,
  3, 2, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}


function pollywog:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilMorph = unitSelf:GetAbility(1)
    skills.abilTongue = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end

pollywog.SkillBuildOld = pollywog.SkillBuild
pollywog.SkillBuild = pollywog.SkillBuildOverride

function pollywog:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  SellItems()
end

pollywog.onthinkOld = pollywog.onthink
pollywog.onthink = pollywog.onthinkOverride

function pollywog:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)
  --eventsLib.printCombatEvent(EventData)
  if EventData.Type == "Ability" then
    if EventData.InflictorName == "Ability_PollywogPriest2" then
      self.trapTarget = EventData.TargetUnit
    elseif EventData.InflictorName == "Ability_PollywogPriest4" then
      self.trapTongue = true
    end
  end
end
pollywog.oncombateventOld = pollywog.oncombatevent
pollywog.oncombatevent = pollywog.oncombateventOverride


local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilNuke:CanActivate() then
    nUtil = nUtil + 15
  end

  if skills.abilUltimate:CanActivate() and skills.abilMorph:CanActivate() and skills.abilTongue:CanActivate() then
    nUtil = nUtil + 50
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride


local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return pollywog.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then

    local abilMorph = skills.abilMorph
    if abilMorph:CanActivate() and unitSelf:GetMana() > 400 then
      local nRange = abilMorph:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilMorph, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end

    local abilNuke = skills.abilNuke
    if not bActionTaken and abilNuke:CanActivate() then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end

  end

  if not bActionTaken then
    return pollywog.harassExecuteOld(botBrain)
  end
end
pollywog.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function WardTrapBehaviorUtility(botBrain)
  local unitTarget = botBrain.trapTarget
  local abilUltimate = skills.abilUltimate
  if core.unitSelf:IsChanneling() then
    return 200
  end

  if unitTarget then
    if(unitTarget:HasState("State_PollywogPriest_Ability2") and abilUltimate:CanActivate() or botBrain.trapTongue) then
      return 200
    end
  end
  return 0
end

local function WardTrapBehaviorExecute(botBrain)
  local target = botBrain.trapTarget
  local abilUltimate = skills.abilUltimate
  local abilTongue = skills.abilTongue
  if core.unitSelf:IsChanneling() then
    return true
  end
  if target then
    if abilUltimate:CanActivate() then
      return core.OrderAbilityPosition(botBrain, abilUltimate, target:GetPosition())
    elseif abilTongue:CanActivate() then
      core.BotEcho("KIELI")
      return core.OrderAbilityEntity(botBrain, abilTongue, target)
    end
  end
  botBrain.trapTarget = nil
  botBrain.trapTongue = false
  return false
end

local WardTrapBehavior = {}
WardTrapBehavior["Utility"] = WardTrapBehaviorUtility
WardTrapBehavior["Execute"] = WardTrapBehaviorExecute
WardTrapBehavior["Name"] = "Ward trapping"
tinsert(behaviorLib.tBehaviors, WardTrapBehavior)

local function EmptyBottle(botBrain)
  local bottle = core.itemBottle
  return bottle and bottle:GetActiveModifierKey() == "bottle_empty"
end

local runeTakingUtilityOld = behaviorLib.RuneTakingBehavior["Utility"]
local function runeTakingUtilityOverride(botBrain)
  local teambot = core.teamBotBrain
  if EmptyBottle(botBrain) then
    return runeTakingUtilityOld(botBrain)
  end
  return 0
end
behaviorLib.RuneTakingBehavior["Utility"] = runeTakingUtilityOverride

local FindItemsOld = core.FindItems
local function funcFindItemsOverride(botBrain)
  local bUpdated = FindItemsOld(botBrain)

  if core.itemBottle ~= nil and not core.itemBottle:IsValid() then
    core.itemBottle = nil
  end

  if bUpdated and not core.itemBottle then

    local inventory = core.unitSelf:GetInventory(true)
    for slot = 1, 12, 1 do
      local curItem = inventory[slot]
      if curItem then
        if core.itemBottle == nil and curItem:GetName() == "Item_Bottle" then
          core.itemBottle = core.WrapInTable(curItem)
        end
      end
    end
  end
  return bUpdated
end
core.FindItems = funcFindItemsOverride
