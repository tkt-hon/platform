local _G = getfenv(0)
local plaguerider = _G.object
local nuketime = HoN.GetMatchTime()

local tinsert, tremove, max = _G.table.insert, _G.table.remove, _G.math.max


plaguerider.heroName = "Hero_DiseasedRider"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/temaNoHelp/lib/courier.lua'
runfile 'bots/teams/temaNoHelp/lib/shopping.lua'
runfile 'bots/teams/temaNoHelp/lib/lasthitting.lua'
runfile 'bots/teams/temaNoHelp/lib/ranges.lua'

local core, behaviorLib, shopping, courier = plaguerider.core, plaguerider.behaviorLib, plaguerider.shopping, plaguerider.courier

behaviorLib.StartingItems = { "Item_HealthPotion", "Item_RunesOfTheBlight", "Item_MinorTotem",  "Item_TrinketOfRestoration"}

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
  elseif NumberInInventory(inventory, "Item_DaemonicBreastplate") <= 0 then
    if NumberInInventory(inventory, "Item_SolsBulwark") <= 0 then
      if NumberInInventory(inventory, "Item_Ringmail") < 2 then
        return "Item_Ringmail"
      else
        return "Item_SolsBulwark"
      end
    elseif NumberInInventory(inventory, "Item_Warpcleft") <= 0 then
      return "Item_Warpcleft"
    elseif NumberInInventory(inventory, "Item_Ringmail") <= 0 then
      return "Item_Ringmail"
    elseif NumberInInventory(inventory, "Item_DaemonicBreastplate") <= 0 then
      return "Item_DaemonicBreastplate"
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

plaguerider.skills = {}
local skills = plaguerider.skills

plaguerider.tSkills = {
  2, 0, 2, 0, 0,
  3, 0, 2, 2, 1,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function plaguerider:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilDeny == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilShield = unitSelf:GetAbility(1)
    skills.abilDeny = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
plaguerider.SkillBuildOld = plaguerider.SkillBuild
plaguerider.SkillBuild = plaguerider.SkillBuildOverride


local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0
  local unitTarget = behaviorLib.heroTarget
  --jos potu käytössä niin ei agroilla
  if core.unitSelf:HasState(core.idefHealthPotion.stateName) then
    return -10000
  end

  if skills.abilNuke:CanActivate() then
    nUtil = nUtil + 15
    local damages = {50,100,125,175}
    if hero:GetHealth() < damages[skills.abilNuke:GetLevel()] then
      return 40
    end
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

------------------------------DENY SKILL START----------------------------------------------------------


local function IsSiege(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end

local function GetUnitToDenyWithSpell(botBrain, myPos, radius)
  local unitsLocal = core.AssessLocalUnits(botBrain, myPos, radius)
  local allies = unitsLocal.AllyCreeps
  local unitTarget = nil
  local nDistance = 0

  for _,unit in pairs(allies) do
    local nNewDistance = Vector3.Distance2DSq(myPos, unit:GetPosition())
    if not IsSiege(unit) and (not unitTarget or nNewDistance < nDistance) and unit:GetHealth() > 435 then
      unitTarget = unit
      nDistance = nNewDistance
    end
  end
  return unitTarget
end

local function IsUnitCloserThanEnemies(botBrain, myPos, unit)
  local unitsLocal = core.AssessLocalUnits(botBrain, myPos, Vector3.Distance2DSq(myPos, unit:GetPosition()))
  return core.NumberElements(unitsLocal.EnemyHeroes) <= 0
end

local function DenyBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = skills.abilDeny
  local myPos = unitSelf:GetPosition()
  local unit = GetUnitToDenyWithSpell(botBrain, myPos, abilDeny:GetRange())

  --jos tornin rangella ni ei mennä
  if core.GetClosestEnemyTower(core.unitSelf:GetPosition(), 715) then
    return -10000
  end
  if core.unitSelf:GetLevel() > 1 and core.unitSelf:GetManaPercent() > 95 then
    return -10000
  end


  if abilDeny:CanActivate() and unit and IsUnitCloserThanEnemies(botBrain, myPos, unit) then
    plaguerider.denyTarget = unit
    return 30
  end
  return 0
end

local function DenyBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilDeny = skills.abilDeny
  local target = plaguerider.denyTarget
  if target then
    return core.OrderAbilityEntity(botBrain, abilDeny, target, false)
  end
  return false
end

local DenyBehavior = {}
DenyBehavior["Utility"] = DenyBehaviorUtility
DenyBehavior["Execute"] = DenyBehaviorExecute
DenyBehavior["Name"] = "Denying creep with spell"
tinsert(behaviorLib.tBehaviors, DenyBehavior)
------------------------------DENY SKILL END----------------------------------------------------------

------------------------------NUKE & ULT SKILL START----------------------------------------------------------



local function UltiBehaviorUtility(botBrain)
  if core.unitSelf:GetLevel() < 6 then
    return 0
  end
  --jos tornin rangella ni ei mennä
  if core.GetClosestEnemyTower(core.unitSelf:GetPosition(), 715) then
    return -10000
  end

  local unitsLocal = core.AssessLocalUnits(botBrain)
  local enemies = unitsLocal.EnemyCreeps
  if core.NumberElements(enemies) == 1 then
    return 70
  end
  return 0
end

local function UltiBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local ulti = skills.abilUltimate
  local unitsLocal = core.AssessLocalUnits(botBrain)
  local enemies = unitsLocal.EnemyHeroes
  local target = nil
  for _, unit in pairs(enemies) do
    target = unit
  end
  if target then
    return core.OrderAbilityEntity(botBrain, ulti, target)
  end
  return false
end

local UltiBehavior = {}
UltiBehavior["Utility"] = UltiBehaviorUtility
UltiBehavior["Execute"] = UltiBehaviorExecute
UltiBehavior["Name"] = "Ulti to the creeps like a baus"
tinsert(behaviorLib.tBehaviors, UltiBehavior)


local function HarassHeroExecuteOverride(botBrain)
  local time = HoN.GetMatchTime()
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return plaguerider.harassExecuteOld(botBrain)
  end


  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local abilNuke = skills.abilNuke
    if skills.abilUltimate:CanActivate() and unitTarget:GetHealth() < 200 then
      local nRange = skills.abilUltimate:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, skills.abilUltimate, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end

    --mätetään nukeja ennen nelosleveliä koko ajan
    if abilNuke:CanActivate() and not core.GetClosestEnemyTower(unitSelf:GetPosition(), 701) and core.unitSelf:GetLevel() < 4 then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
        nuketime = HoN.GetMatchTime()
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
    --pyritään säästelemään manaa kolmoslevelin jälkeen kuitenkin jos tappoon mahollisuus niin go


    if abilNuke:CanActivate() and not core.GetClosestEnemyTower(unitSelf:GetPosition(), 701) and core.unitSelf:GetMana() > 150 and core.unitSelf:GetLevel() > 3 then
      local nRange = abilNuke:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
        nuketime = HoN.GetMatchTime()
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
    if time > nuketime + 30000 then
      local nuke = skills.abilNuke
      local unitsLocal = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 1000)
      if unitsLocal ~= nil then
        local enemies = unitsLocal.EnemyCreeps
        local target = nil
        for _, unit in pairs(enemies) do
          target = unit
          if target:GetHealth() > 200 then
            nuketime = HoN.GetMatchTime()
            return core.OrderAbilityEntity(botBrain, nuke, target)
          end
        end
      end
    end

  end

  if not bActionTaken then
    return plaguerider.harassExecuteOld(botBrain)
  end
end
plaguerider.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
------------------------------NUKE & ULT SKILL END----------------------------------------------------------

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function plaguerider:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  SellItems()
  -- custom code here
end
plaguerider.onthinkOld = plaguerider.onthink
plaguerider.onthink = plaguerider.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function plaguerider:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  local nAddBonus = 0

  if EventData.Type == "Ability" then
    if EventData.InflictorName == "Ability_DiseasedRider4" then
      nAddBonus = nAddBonus + 100
    end
  end

  if nAddBonus > 0 then
    core.DecayBonus(self)
    core.nHarassBonus = core.nHarassBonus + nAddBonus
  end

  -- custom code here
end
-- override combat event trigger function.
plaguerider.oncombateventOld = plaguerider.oncombatevent
plaguerider.oncombatevent = plaguerider.oncombateventOverride

local function RetreatFromThreatUtilityOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget
  local selfPosition = core.unitSelf:GetPosition()
  if unitTarget ~= nil then
    if core.unitSelf:GetHealth() + 50 < unitTarget:GetHealth() then
      return 10000
    end
  end

  if core.GetClosestEnemyTower(selfPosition, 715) then
    return 10000
  end

  return behaviorLib.RetreatFromThreatUtility(botBrain)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = RetreatFromThreatUtilityOverride

function behaviorLib.PositionSelfExecute(botBrain)
  local unitSelf = core.unitSelf
  local vecMyPosition = unitSelf:GetPosition()

  if core.unitSelf:IsChanneling() then
    return
  end

  local vecDesiredPos = vecMyPosition
  vecDesiredPos, _ = behaviorLib.PositionSelfLogic(botBrain)

  if vecDesiredPos then
    return behaviorLib.MoveExecute(botBrain, vecDesiredPos)
  else
    return false
  end
end
behaviorLib.PositionSelfBehavior["Execute"] = behaviorLib.PositionSelfExecute

function behaviorLib.HealthPotUtilFn(nHealthMissing)
  --Roughly 20+ when we are down 400 hp
  --  Fn which crosses 20 at x=400 and 40 at x=650, convex down
  if nHealthMissing > 225 then
    return 100
  end
  return 0
end
