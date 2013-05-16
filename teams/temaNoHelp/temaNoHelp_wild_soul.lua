local _G = getfenv(0)
local wildsoul = _G.object

local tinsert, tremove, max = _G.table.insert, _G.table.remove, _G.math.max

wildsoul.heroName = "Hero_Yogi"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/temaNoHelp/lib/courier.lua'
runfile 'bots/teams/temaNoHelp/lib/shopping.lua'
runfile 'bots/teams/temaNoHelp/lib/lasthitting.lua'


local core, behaviorLib, eventsLib, shopping, courier = wildsoul.core, wildsoul.behaviorLib, wildsoul.eventsLib, wildsoul.shopping, wildsoul.courier

core.unitBooboo = nil

local function AssignBooboo(botBrain)
  local tCreeps = core.AssessLocalUnits(botBrain).AllyCreeps
  local sPlayer = core.unitSelf:GetOwnerPlayer()
  for _, creep in pairs(tCreeps) do
    if creep:GetTypeName() == "Pet_Yogi_Ability1" and creep:GetOwnerPlayer() == sPlayer then
      core.unitBooboo = creep
    end
  end
end

local ultDuration = HoN.GetMatchTime()-500

behaviorLib.StartingItems = { "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_IronBuckler", "Item_RunesOfTheBlight", "Item_HealthPotion"}

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
  if NumberInInventory(inventory, "Item_HealthPotion") < 3 then
    return "Item_HealthPotion"
  elseif NumberInInventory(inventory, "Item_LifeSteal5") + NumberInInventory(inventory, "Item_ManaRegen3") <= 0 then
    if NumberInInventory(inventory, "Item_GuardianRing") <= 0 then
      return "Item_GuardianRing"
    elseif NumberInInventory(inventory, "Item_Scarab") <= 0 then
      return "Item_Scarab"
    end
  elseif not HasBoots(inventory) then
    return "Item_Marchers"
  elseif NumberInInventory(inventory, "Item_Steamboots") <= 0 then
    if NumberInInventory(inventory, "Item_BlessedArmband") <= 0 then
      return "Item_BlessedArmband"
    elseif NumberInInventory(inventory, "Item_GlovesOfHaste") <= 0 then
      return "Item_GlovesOfHaste"
    end
  elseif NumberInInventory(inventory, "Item_LifeSteal5") <= 0 then
    if NumberInInventory(inventory, "Item_TrinketOfRestoration") <= 0 then
      return "Item_TrinketOfRestoration"
    elseif NumberInInventory(inventory, "Item_HungrySpirit") <= 0 then
      return "Item_HungrySpirit"
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

behaviorLib.pushingStrUtilMul = 1

wildsoul.skills = {}
local skills = wildsoul.skills

wildsoul.tSkills = {
  0, 2, 0, 2, 0,
  3, 0, 2, 2, 1,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}


function wildsoul:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilBear == nil then
    skills.abilBear = unitSelf:GetAbility(0)
    skills.abilWild = unitSelf:GetAbility(1)
    skills.abilBoost = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end

wildsoul.SkillBuildOld = wildsoul.SkillBuild
wildsoul.SkillBuild = wildsoul.SkillBuildOverride

function wildsoul:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  SellItems()
  -- custom code here
end

wildsoul.onthinkOld = wildsoul.onthink
wildsoul.onthink = wildsoul.onthinkOverride

function wildsoul:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)
  if EventData.Type == "Ability" then
    if EventData.InflictorName == "Ability_Yogi1" and not core.Booboo then
      AssignBooboo(self)
    end
  end
  -- custom code here
end
-- override combat event trigger function.
wildsoul.oncombateventOld = wildsoul.oncombatevent
wildsoul.oncombatevent = wildsoul.oncombateventOverride

local function BearBehaviorUtility(botBrain)
  if skills.abilBear:CanActivate() then
    return 100
  end
  return 0
end

local function BearBehaviorExecute(botBrain)
  return core.OrderAbility(botBrain, skills.abilBear)
end

local BearBehavior = {}
BearBehavior["Utility"] = BearBehaviorUtility
BearBehavior["Execute"] = BearBehaviorExecute
BearBehavior["Name"] = "Bear using"
tinsert(behaviorLib.tBehaviors, BearBehavior)

local function UltiBehaviorUtility(botBrain)
  if skills.abilUltimate:CanActivate() and not (core.unitSelf:HasState("State_Yogi_Ability4") or core.unitSelf:HasState("State_Yogi_Ability4_HD")) then
    return 100
  end
  return 0
end

local function UltiBehaviorExecute(botBrain)
  return core.OrderAbility(botBrain, skills.abilUltimate)
end

local UltiBehavior = {}
UltiBehavior["Utility"] = UltiBehaviorUtility
UltiBehavior["Execute"] = UltiBehaviorExecute
UltiBehavior["Name"] = "Ulti using"
tinsert(behaviorLib.tBehaviors, UltiBehavior)

local function WildBehaviorUtility(botBrain)
  if skills.abilWild:CanActivate() and (not core.unitSelf:HasState("State_Yogi_Ability2") or core.unitBooboo and core.unitBooboo:IsAlive() and not core.unitBooboo:HasState("State_Yogi_Ability2")) then
    return 100
  end
  return 0
end

local function WildBehaviorExecute(botBrain)
  return core.OrderAbility(botBrain, skills.abilWild)
end

local WildBehavior = {}
WildBehavior["Utility"] = WildBehaviorUtility
WildBehavior["Execute"] = WildBehaviorExecute
WildBehavior["Name"] = "Wild using"
tinsert(behaviorLib.tBehaviors, WildBehavior)


