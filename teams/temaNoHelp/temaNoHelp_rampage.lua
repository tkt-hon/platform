local _G = getfenv(0)
local rampage = _G.object
local stunDuration = 0
local tinsert, tremove, max = _G.table.insert, _G.table.remove, _G.math.max
rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/temaNoHelp/lib/courier.lua'
runfile 'bots/teams/temaNoHelp/lib/shopping.lua'

local core, behaviorLib, shopping = rampage.core, rampage.behaviorLib, rampage.shopping
behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_MinorTotem", "Item_MinorTotem", "Item_MinorTotem", "Item_IronBuckler" }

--rampage.bReportBehavior = true
--rampage.bDebugUtility = true

local function PreGameItems()
  for _, item in ipairs(behaviorLib.StartingItems) do
    tremove(behaviorLib.StartingItems, 1)
    return item
  end
end

local function NumberInInventory(inventory, name)
  return shopping.NumberStackableElements(core.InventoryContains(inventory, name, false, true)) + shopping.NumberStackableElements(rampage.courier.CourierContains(name))
end

local function HasBoots(inventory)
  local boots = {
    "Item_Marchers",
    "Item_EnhancedMarchers",
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
  elseif NumberInInventory(inventory, "Item_ManaRegen3") <= 0 then
    if NumberInInventory(inventory, "Item_GuardianRing") <= 0 then
      return "Item_GuardianRing"
    elseif NumberInInventory(inventory, "Item_Scarab") <= 0 then
      return "Item_Scarab"
    end
  elseif NumberInInventory(inventory, "Item_EnhancedMarchers") <= 0 then
    if NumberInInventory(inventory, "Item_Punchdagger") < 2 then
      return "Item_Punchdagger"
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
    return "Item_DaemonicBreastplate"
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
    return core.NumberElements(core.InventoryContains(inventory, "Item_GuardianRing")) > 0
  elseif item == "Item_Punchdagger" then
    return core.NumberElements(core.InventoryContains(inventory, item)) > 0
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
  local courier = rampage.courier
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

---------------------------------------------------------------
--            SkillBuild override                            --
-- Handles hero skill building. To customize just write own  --
---------------------------------------------------------------
-- @param: none
-- @return: none
rampage.skills = {}
local skills = rampage.skills

rampage.tSkills = {
  2, 1, 2, 0, 2,
  3, 2, 1, 0, 1,
  3, 1, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
function rampage:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilCharge == nil then
    skills.abilCharge = unitSelf:GetAbility(0)
    skills.abilSlow = unitSelf:GetAbility(1)
    skills.abilBash = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
rampage.SkillBuildOld = rampage.SkillBuild
rampage.SkillBuild = rampage.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function rampage:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  SellItems()
  -- custom code here
end
rampage.onthinkOld = rampage.onthink
rampage.onthink = rampage.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0
  local unitTarget = behaviorLib.heroTarget
  local time = HoN.GetMatchTime()
  local creepLane = core.GetFurthestCreepWavePos(core.tMyLane, core.bTraverseForward)
  local myPos = core.unitSelf:GetPosition()
--jos potu käytössä niin ei agroilla
  if core.unitSelf:HasState(core.idefHealthPotion.stateName) then
    core.BotEcho("POTUU")
	return -10000
  end

--jos tornin rangella ni ei mennä
  if core.GetClosestEnemyTower(hero:GetPosition(), 715) then
    return -10000
  end

 -- local unitsNearby = core.AssessLocalUnits(rampage, hero:GetPosition(),500)
--jos ei omia creeppejä 500 rangella, niin ei aggroa
 -- if core.NumberElements(unitsNearby.AllyCreeps) == 0 then
 --   return 0
--  end

  if unitTarget and unitTarget:GetHealth() < 250 and core.unitSelf:GetHealth() > 400 then
    return 100
  end

--timeri päälle kun vihu stunnissa, että voidaan hakata autoattack
  if unitTarget and unitTarget:IsStunned() then
   stunDuration = time
  end

  if time - stunDuration < 1 then
    return 30
  end

-- Jos bash valmis niin aggro
  if skills.abilBash:IsReady() then
    return 70
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function RetreatFromThreatUtilityOverride(botBrain)

  local selfPosition = core.unitSelf:GetPosition()

  if core.GetClosestEnemyTower(selfPosition, 715) then
    return 10000
  end

  return behaviorLib.RetreatFromThreatUtility(botBrain)
end
behaviorLib.RetreatFromThreatBehavior["Utility"] = RetreatFromThreatUtilityOverride


local function HarassHeroExecuteOverride(botBrain)
  local abilCharge = skills.abilCharge
  local abilUltimate = skills.abilUltimate
  local abilSlow = skills.abilSlow

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return rampage.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false


  if core.CanSeeUnit(botBrain, unitTarget) then

      if unitTarget and unitTarget:GetHealth() < 250 then
        --charge
        if abilCharge:CanActivate() then
          bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, unitTarget)
        end
        --slowi
        if abilSlow:CanActivate() then
        local nRange = 300
          if nTargetDistanceSq < (nRange * nRange) then
            return core.OrderAbility(botBrain, abilSlow)
          end
        end

      end
	  --ulti
      if abilUltimate:CanActivate() and unitTarget:GetHealth() < 400 then
        local nRange = abilUltimate:GetRange()
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
		  rampage.ultitime = HoN.GetMatchTime()
		  rampage.ultitarget = unitTarget
        end
      end
  end

  if not bActionTaken then
    return rampage.harassExecuteOld(botBrain)
  end
end
rampage.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function UltimateBehaviorUtility(botBrain)
  local unitTarget = rampage.ultitarget
  local time = HoN.GetMatchTime()
  if unitTarget then
	if unitTarget:HasState("State_Rampage_Ability4") and time < rampage.ultitime + 2350 then
	  return 99999
	end
  end
  return 0
end

local function UltimateBehaviorExecute(botBrain)
  local bActionTaken = core.OrderMoveToPosClamp(botBrain, core.unitSelf, core.GetClosestAllyTower(core.unitSelf:GetPosition(), nMaxDist):GetPosition(), false, false)
  return bActionTaken
end

local UltimateBehavior = {}
UltimateBehavior["Utility"] = UltimateBehaviorUtility
UltimateBehavior["Execute"] = UltimateBehaviorExecute
UltimateBehavior["Name"] = "MASA DUMSERIS"
tinsert(behaviorLib.tBehaviors, UltimateBehavior)

local function ChargeBehaviorUtility(botBrain)
  local unitSelf = core.unitSelf
  if unitSelf:HasState("State_Rampage_Ability1_Sight") or unitSelf:HasState("State_Rampage_Ability1_Warp") or unitSelf:HasState("State_Rampage_Ability1_Timer") then
    return 99999
  end

  return 0
end

local function ChargeBehaviorExecute(botBrain)
  return true
end

local ChargeBehavior = {}
ChargeBehavior["Utility"] = ChargeBehaviorUtility
ChargeBehavior["Execute"] = ChargeBehaviorExecute
ChargeBehavior["Name"] = "PESSI CHARGETTU"
tinsert(behaviorLib.tBehaviors, ChargeBehavior)

function behaviorLib.HealthPotUtilFn(nHealthMissing)
	--Roughly 20+ when we are down 400 hp
	--  Fn which crosses 20 at x=400 and 40 at x=650, convex down
	if nHealthMissing > 350 then
	  return 100
	end
	return 0
end

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
    BotEcho("PositionSelfExecute - nil desired position")
    return false
  end
end
behaviorLib.PositionSelfBehavior["Execute"] = behaviorLib.PositionSelfExecute
