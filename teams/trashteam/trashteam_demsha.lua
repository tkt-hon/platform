local _G = getfenv(0)
local shaman = _G.object

shaman.heroName = "Hero_Shaman"

runfile 'bots/core_herobot.lua'

local tinsert = _G.table.insert

local core, behaviorLib = shaman.core, shaman.behaviorLib

UNIT = 0x0000001
BUILDING = 0x0000002
HERO = 0x0000004
POWERUP = 0x0000008
GADGET = 0x0000010
ALIVE = 0x0000020
CORPSE = 0x0000040

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_HealthPotion", "Item_DuckBoots", "Item_MinorTotem", "Item_PretendersCrown" }
behaviorLib.LaneItems = { "Item_HealthPotion", "Item_IronShield","Item_HealthPotion", "Item_Marchers", "Item_Steamboots", "Item_WhisperingHelm" }
behaviorLib.MidItems = { "Item_ManaBurn2", "Item_Evasion", "Item_Immunity", "Item_Stealth" }
behaviorLib.LateItems = { "Item_LifeSteal4", "Item_Sasuke" }

shaman.skills = {}
local skills = shaman.skills

core.itemGeoBane = nil
shaman.AdvTarget = nil
shaman.AdvTargetHero = nil

shaman.tSkills = {
  1, 2, 1, 2, 1,
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
function shaman:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilNuke == nil then
    skills.abilNuke = unitSelf:GetAbility(0)
    skills.abilBounce = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
    skills.taunt = unitSelf:GetAbility(8)
  end
  shaman:SkillBuildOld()
end
shaman.SkillBuildOld = shaman.SkillBuild
shaman.SkillBuild = shaman.SkillBuildOverride


------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function shaman:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  local unitSelf = self.core.unitSelf
  if shaman.AdvTarget and shaman.AdvTargetHero and false then
    HoN.DrawDebugLine(unitSelf:GetPosition(), shaman.AdvTarget:GetPosition(), true, "red")
    HoN.DrawDebugLine(shaman.AdvTarget:GetPosition(), shaman.AdvTargetHero:GetPosition(), true, "blue")
  end
  -- custom code here
end
shaman.onthinkOld = shaman.onthink
shaman.onthink = shaman.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function shaman:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
  local nAddBonus = 0

   if nAddBonus > 0 then
        core.DecayBonus(self)
        core.nHarassBonus = core.nHarassBonus + nAddBonus
    end
end
-- override combat event trigger function.
local function IsSiege(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end

local function closeToEnemyTowerDist(unit)
  local unitSelf = unit
  local myPos = unitSelf:GetPosition()
  local myTeam = unitSelf:GetTeam()

  local unitsInRange = HoN.GetUnitsInRadius(myPos, 3000, ALIVE + BUILDING)
  for _,unit in pairs(unitsInRange) do
    if unit and not(myTeam == unit:GetTeam()) then
      if unit:GetTypeName() == "Building_HellbourneTower" then
        return Vector3.Distance2DSq(myPos, unit:GetPosition())
      end
    end
  end
  return 3000
end

local function GetHeroToUlti(botBrain, myPos, radius)
  local unitsLocal = HoN.GetUnitsInRadius(myPos, radius, ALIVE + HERO)
  local vihunmq = nil

  for key,unit in pairs(unitsLocal) do
    if unit ~= nil and not (botBrain:GetTeam() == unit:GetTeam()) then
      vihunmq = unit
    end
  end

  if not vihunmq then
    return nil
  end
  return vihunmq
end

local function AreThereMaxTwoEnemyUnitsClose(botBrain, myPos, range)
  local unitsLocal = HoN.GetUnitsInRadius(myPos, range, ALIVE + UNIT)
  local count = 0
  for _,unit in pairs(unitsLocal) do
    if unit and not (botBrain:GetTeam() == unit:GetTeam()) then
      if not IsSiege(unit) then
        count = count +1
      end
    end
  end

  return count <= 1
end

local function UltimateBehaviorUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local distToEneTo = closeToEnemyTowerDist(unitSelf)
  local modifier = 0
  if distToEneTo < 650*650 then
    modifier = 70
  end

  local abilUlti = unitSelf:GetAbility(3)
  local myPos = unitSelf:GetPosition()
  local vihu = GetHeroToUlti(botBrain, myPos, abilUlti:GetRange() * 0.5)
  local vihuMax = GetHeroToUlti(botBrain, myPos, abilUlti:GetRange())
  if vihu then
    local canUlti = AreThereMaxTwoEnemyUnitsClose(botBrain, vihu:GetPosition(), abilUlti:GetRange()*2)
    if abilUlti:CanActivate() and vihu and canUlti  then
      return 90 -modifier
    end
  end
  if abilUlti:CanActivate() and vihuMax and vihuMax:GetHealth() < 200 then
    return 95 - (modifier * 0.5)
  end
  return 0
end

local function UltimateBehaviorExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local abilUlti = unitSelf:GetAbility(3)
  return core.OrderAbility(botBrain, abilUlti, false)
end

local UltimateBehavior = {}
UltimateBehavior["Utility"] = UltimateBehaviorUtility
UltimateBehavior["Execute"] = UltimateBehaviorExecute
UltimateBehavior["Name"] = "Using ultimate properly"
tinsert(behaviorLib.tBehaviors, UltimateBehavior)

shaman.oncombateventOld = shaman.oncombatevent
shaman.oncombatevent = shaman.oncombateventOverride


local function heroIsInRange(botBrain,enemyCreep, range)
  local creepPos = enemyCreep:GetPosition()
  local unitsInRange = HoN.GetUnitsInRadius(creepPos, range, ALIVE + HERO)
  for _,unit in pairs(unitsInRange) do
    if unit and not (botBrain:GetTeam() == unit:GetTeam()) then
      shaman.AdvTargetHero = unit
      return true
    end
  end
  return false
end

local function shouldWeHarassHero(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local myPos = unitSelf:GetPosition()
  local allyTeam = botBrain:GetTeam()
  local heroes = HoN.GetUnitsInRadius(myPos, 4000, ALIVE+HERO)
  for _,unit in pairs(heroes) do
    if unit and not (allyTeam == unit:GetTeam()) then
      -- core.BotEcho("asdasd: " .. tostring(unit:GetHealthPercent()))
      if unit:GetHealthPercent() < 0.2 then
        return false
      else
        return true
      end
    end
  end
end

local function AdvHarassUtility(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local distToEneTo = closeToEnemyTowerDist(unitSelf)
  local modifier = 0
  if distToEneTo < 650*650 then
    modifier = 80
  end

  -- 1500 = 0
  -- 600 = 100
  local atkRange = unitSelf:GetAttackRange()
  if not shouldWeHarassHero(botBrain)  then
    return 0
  end
  local myPos = unitSelf:GetPosition()
  local allUnits = HoN.GetUnitsInRadius(myPos, atkRange*2, ALIVE + UNIT)
  local allUnitsMax = HoN.GetUnitsInRadius(myPos, 2000, ALIVE + UNIT)
  local potentialCreep = nil
  local unitCount = 0
  for _,unit in pairs(allUnitsMax) do
    if unit and not (botBrain:GetTeam() == unit:GetTeam()) then
      unitCount = unitCount + 1
    end
  end
  --core.BotEcho("Units around: " .. tostring(unitCount))
  if unitCount > 0 and unitCount < unitSelf:GetAbility(1):GetLevel() then -- less creeps than our bounce
    for _,unit in pairs(allUnits) do
      if unit and unit:GetHealthPercent() <= 0.3 then
        return 0
      end
      if unit and not (botBrain:GetTeam() == unit:GetTeam()) and unit:GetHealthPercent() > 0.55 then
        if heroIsInRange(botBrain, unit, atkRange * 0.8) then
          shaman.AdvTarget = unit
          --botBrain.core.BotEcho("HARASS VITTUUU")
          return 100 - modifier
        end
      end
    end
  end
  return 0
end

local function AdvHarassExecute(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local targetCreep = shaman.AdvTarget
  return core.OrderAttackClamp(botBrain, unitSelf, targetCreep)
end

local AdvHarassBehavior = {}
AdvHarassBehavior["Utility"] = AdvHarassUtility
AdvHarassBehavior["Execute"] = AdvHarassExecute
AdvHarassBehavior["Name"] = "Using bounce to harass properly"
tinsert(behaviorLib.tBehaviors, AdvHarassBehavior)


local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilNuke:CanActivate() then
    nUtil = nUtil + 12*skills.abilNuke:GetLevel()
  end

  local ultiCost = skills.abilUltimate:GetManaCost()
  local nukeCost = skills.abilNuke:GetManaCost()
  local myMana = hero:GetMana()
  if myMana > ultiCost + nukeCost*1.5 then
    nUtil = nUtil + 20
  end
  nUtil = nUtil * (hero:GetHealthPercent()*0.5 + 0.4)

  if myMana-nukeCost < nukeCost + ultiCost and (not skills.abilUltimate:CanActivate() or skills.abilUltimate:GetLevel() < 1) then
    nUtil = nUtil*0.5
  end
  local distToEneTo = closeToEnemyTowerDist(hero)
  local modifier = 0
  if distToEneTo < 650*650 then
    modifier = 80
  end
  return nUtil-modifier
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return shaman.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())
  local nLastHarassUtility = behaviorLib.lastHarassUtil

  local bActionTaken = false
  local magicReduc = unitTarget:GetMagicArmor()
  magicReduc = 1 - (magicReduc*0.06)/(1+0.06*magicReduc)

  local abilNuke = skills.abilNuke
  local ultiCost = skills.abilUltimate:GetManaCost()
  local nukeCost = skills.abilNuke:GetManaCost()
  local myMana = unitSelf:GetMana()
  local nukeDmg = abilNuke:GetLevel() * 75 * magicReduc

  if abilNuke:CanActivate() then
    local nRange = abilNuke:GetRange()
    if nTargetDistanceSq < (nRange*nRange) and unitTarget:GetHealth()-nukeDmg > 300 and myMana-nukeCost > nukeCost+ultiCost then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
    elseif nTargetDistanceSq < (nRange*nRange) and unitTarget:GetHealth()-nukeDmg < 300 and myMana-nukeCost > ultiCost then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
    elseif nTargetDistanceSq < (nRange*nRange) and unitTarget:GetHealth() <= nukeDmg then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilNuke, unitTarget)
    else
      bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
    end
  end

  if not bActionTaken then
    return shaman.harassExecuteOld(botBrain)
  end
end
shaman.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
