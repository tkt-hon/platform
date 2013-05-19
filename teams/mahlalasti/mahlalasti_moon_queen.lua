local _G = getfenv(0)
local moonqueen = _G.object

moonqueen.heroName = "Hero_Krixi"

runfile 'bots/core_herobot.lua'
runfile 'bots/teams/mahlalasti/banter.lua'
runfile 'bots/teams/mahlalasti/mahlalasti_courier.lua'

local core, behaviorLib = moonqueen.core, moonqueen.behaviorLib

local tinsert = _G.table.insert

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "2 Item_DuckBoots", "2 Item_MinorTotem" }
behaviorLib.LaneItems = { "Item_MysticVestments", "Item_Marchers", "Item_Steamboots", "Item_WhisperingHelm" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }


behaviorLib.pushingStrUtilMul = 1

moonqueen.skills = {}
local skills = moonqueen.skills

core.itemGeoBane = nil

moonqueen.tSkills = {
  0, 4, 0, 4, 0,
  3, 0, 1, 2, 1,
  3, 1, 1, 1, 2,
  3, 2, 4, 4, 4,
  4, 4, 4, 4, 4
}

function moonqueen:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilBounce = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
moonqueen.SkillBuildOld = moonqueen.SkillBuild
moonqueen.SkillBuild = moonqueen.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function moonqueen:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
  local matchtime = HoN.GetMatchTime()
  --if matchtime ~= 0 and matchtime % 2000 == 0 then
  --  self:Chat("Current behavior: " .. core.GetCurrentBehaviorName(self))
  --end

  if matchtime == 1000 then
    self:Chat("Just got kicked out of my house for being an atheist at 17. Any advice?")
  end
  if matchtime > 0 and matchtime % 5000 == 0 then
    behaviorLib.ShopExecute(self)
  end
  self:onthinkCourier()
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

local function NearbyCreepCount(botBrain, center, radius)
  local count = 0
  local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
  local enemies = unitsLocal.EnemyCreeps
  for _,unit in pairs(enemies) do
    count = count + 1
  end
  return count
end

local function CustomHarassUtilityFnOverride(hero, botBrain)
  local level = core.unitSelf:GetLevel()
  local mana = core.unitSelf:GetMana()
  local nUtil = 0

  nUtil = 9 + (level*0.3)

  if skills.abilNuke:CanActivate() then
    -- vaihdettu 5->5.5 JH
    nUtil = nUtil + 5.5*skills.abilNuke:GetLevel()
  end

  local creeps = NearbyCreepCount(moonqueen, hero:GetPosition(), 700)

  if skills.abilUltimate:CanActivate() and creeps < 3 then
    nUtil = nUtil + 100
  end
  --moonqueen:Chat("Current nUtil: " .. nUtil)

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return moonqueen.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local itemGeoBane = core.itemGeoBane
    if not bActionTaken then
      if itemGeoBane then
        if itemGeoBane:CanActivate() then
          bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemGeoBane)
        end
      end
    end

    local abilUltimate = skills.abilUltimate
    if not bActionTaken and nLastHarassUtility > 50 then
      if abilUltimate:CanActivate() then
        local nRange = 700
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbility(botBrain, abilUltimate)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end

    local abilNuke = skills.abilNuke
    if abilNuke:CanActivate() then
      local nRange = abilNuke:GetRange() + 50
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end
  end

  if not bActionTaken then
    return moonqueen.harassExecuteOld(botBrain)
  end
end
moonqueen.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function DPSPushingUtilityOverride(myHero)
  local modifier = 1 + myHero:GetAbility(1):GetLevel()*2
  return moonqueen.DPSPushingUtilityOld(myHero) * modifier
end
moonqueen.DPSPushingUtilityOld = behaviorLib.DPSPushingUtility
behaviorLib.DPSPushingUtility = DPSPushingUtilityOverride

local function funcFindItemsOverride(botBrain)
  local bUpdated = moonqueen.FindItemsOld(botBrain)

  if core.itemGeoBane ~= nil and not core.itemGeoBane:IsValid() then
    core.itemGeoBane = nil
  end

  if bUpdated then
    if core.itemGeoBane then
      return
    end

    local inventory = core.unitSelf:GetInventory(true)
    for slot = 1, 12, 1 do
      local curItem = inventory[slot]
      if curItem then
        if core.itemGeoBane == nil and curItem:GetName() == "Item_ManaBurn2" and not curItem:IsRecipe() then
          core.itemGeoBane = core.WrapInTable(curItem)
        end
      end
    end
  end
  return bUpdated
end
moonqueen.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride



function behaviorLib.bigPurseUtility(botBrain)


  local level = core.unitSelf:GetLevel()
  local multiplier = level*0.18
  if level < 6 then
    moonqueen.purseMax = 1000
    moonqueen.purseMin = 600
  elseif level >= 5 then
    moonqueen.purseMax = 1650*multiplier
    moonqueen.purseMin = 700*multiplier
  end
  local bDebugEchos = false

  local Clamp = core.Clamp
  local m = (100/(moonqueen.purseMax - moonqueen.purseMin))
  nUtil = m*botBrain:GetGold() - m*moonqueen.purseMin
  nUtil = Clamp(nUtil,0,100)

  if bDebugEchos then core.BotEcho("Bot return Priority:" ..nUtil) end

  return nUtil
end

-- Execute
function behaviorLib.bigPurseExecute(botBrain)
  local mana = core.unitSelf:GetManaPercent()
  local unitSelf = core.unitSelf


  local wellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()

  core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, wellPos, false)
end




behaviorLib.bigPurseBehavior = {}
behaviorLib.bigPurseBehavior["Utility"] = behaviorLib.bigPurseUtility
behaviorLib.bigPurseBehavior["Execute"] = behaviorLib.bigPurseExecute
behaviorLib.bigPurseBehavior["Name"] = "bigPurse"
tinsert(behaviorLib.tBehaviors, behaviorLib.bigPurseBehavior)

function behaviorLib.useManaGenUtility(botBrain)
  local nOwnMana = core.unitSelf:GetMana()
  local tInventory = core.unitSelf:GetInventory()
  local idefManaPotion = HoN.GetItemDefinition("Item_ManaPotion")
  local tManaPots = core.InventoryContains(tInventory, idefManaPotion:GetName())
  if #tManaPots > 0 and nOwnMana < 120  then
    nUtil = 99
    --moonqueen:Chat("ManaUtility" .. nUtil)
    return nUtil
  end
  --core.BotEcho("ManaUtility" .. nUtil)
  nUtil = 0
  return nUtil
end

function behaviorLib.useManaGenExecute(botBrain)
  local nOwnMana = core.unitSelf:GetMana()
  local tInventory = core.unitSelf:GetInventory()
  local idefManaPotion = HoN.GetItemDefinition("Item_ManaPotion")
  local tManaPots = core.InventoryContains(tInventory, idefManaPotion:GetName())
  core.OrderItemEntityClamp(botBrain, core.unitSelf, tManaPots[1], core.unitSelf)
  --moonqueen:Chat("Trying to execute...")
  core.BotEcho("Used ManaGen!")
  return
end

behaviorLib.useManaGenBehavior = {}
behaviorLib.useManaGenBehavior["Utility"] = behaviorLib.useManaGenUtility
behaviorLib.useManaGenBehavior["Execute"] = behaviorLib.useManaGenExecute
behaviorLib.useManaGenBehavior["Name"] = "useMana"
tinsert(behaviorLib.tBehaviors, behaviorLib.useManaGenBehavior)
