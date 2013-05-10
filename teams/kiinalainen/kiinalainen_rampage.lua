local _G = getfenv(0)
local rampage = _G.object
local tinsert = _G.table.insert

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_kiinalainen_herobot.lua'

local core, behaviorLib = rampage.core, rampage.behaviorLib

local tinsert = _G.table.insert

local CHARGE_NONE, CHARGE_STARTED, CHARGE_TIMER, CHARGE_WARP = 0, 1, 2, 3
rampage.charged = CHARGE_NONE

local ULTI_NONE, ULTI_ON = 0, 1
rampage.ulti = ULTI_NONE

rampage.skills = {}
local skills = rampage.skills

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_IronBuckler", "Item_LoggersHatchet" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Lifetube", "Item_ManaBattery" }
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_PowerSupply", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }

rampage.tSkills = {
  1, 2, 1, 0, 1,
  3, 1, 2, 2, 2,
  3, 0, 0, 0, 4,
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

rampage.tSkills = {
  1, 2, 1, 0, 1,
  3, 1, 2, 2, 2,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_IronBuckler", "Item_LoggersHatchet" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_Lifetube", "Item_ManaBattery" }
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2", "Item_PowerSupply", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }

function rampage.CustomHarassHeroUtilityOverride(botBrain)
  local nUtil = behaviorLib.HarassHeroUtility(botBrain)

  local unitSelf = core.unitSelf
  local selfPos = unitSelf:GetPosition()
  local selfHealth = unitSelf:GetHealth()
  local tLocalUnits = core.AssessLocalUnits(botBrain, selfPos, 600)

  if tLocalUnits.EnemyHeroes then
    local tEnemies = tLocalUnits.EnemyHeroes
    local nTotalEnemyHealth = nil
    for k,v in pairs(tEnemies) do
      nTotalEnemyHealth = nTotalEnemyHealth or 0 + v:GetHealth()
    end
    if (nTotalEnemyHealth or 9999 < unitSelf:GetHealth()) then
      nUtil = nUtil + (unitSelf:GetHealth() - nTotalEnemyHealth) * 0.05
    end
  end

  if skills.abilBash:IsReady() then
    nUtil = nUtil + 10
  end

  if skills.abilCharge:CanActivate() then
    nUtil = nUtil + 20
  end

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil + 50
  end

  return nUtil
end
behaviorLib.HarassHeroBehavior["Utility"] = rampage.CustomHarassHeroUtilityOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.abilBash:IsReady() then
    nUtil = nUtil + 10
  end

  if skills.abilCharge:CanActivate() then
    nUtil = nUtil + 20
  end

  if skills.abilUltimate:CanActivate() then
    nUtil = nUtil + 50
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride
----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  if EventData.Type == "Ability" and EventData.InflictorName == "Ability_Rampage1" then
    self.charged = CHARGE_STARTED
  elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Timer" then
    if self.charged == CHARGE_STARTED then
      self.charged = CHARGE_NONE
    end
  elseif EventData.Type == "State" and EventData.StateName == "State_Rampage_Ability1_Warp" then
    self.charged = CHARGE_WARP
  elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Warp" then
    self.charged = CHARGE_NONE
  elseif EventData.Type == "Death" then
    self.charged = CHARGE_NONE
  end

end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride

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

    if abilUltimate:CanActivate() then
      local nRange = abilUltimate:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
      end
    end

    if abilCharge:CanActivate() then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, unitTarget)
    end

    if abilSlow:CanActivate() then
      local nRange = 300
      if nTargetDistanceSq < (nRange * nRange) then
        return core.OrderAbility(botBrain, abilSlow)
      end
    end

  end

  if not bActionTaken then
    return rampage.harassExecuteOld(botBrain)
  end
end
rampage.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local function ChargeTarget(botBrain, unitSelf, abilCharge)
  local tEnemyHeroes = HoN.GetHeroes(core.enemyTeam)
  local utility = 0
  local unitTarget = nil
  local nTarget = 0
  for nUID, unit in pairs(tEnemyHeroes) do
    if core.CanSeeUnit(botBrain, unit) and unit:IsAlive() and (not unitTarget or unit:GetHealth() < unitTarget:GetHealth()) then
      unitTarget = unit
      nTarget = nUID
    end
  end
  if unitTarget then
    local damageLevels = {100,140,180,220}
    local chargeDamage = damageLevels[abilCharge:GetLevel()]
    local estimatedHP = unitTarget:GetHealth() - chargeDamage
    if estimatedHP < 200 then
      utility = 20
    end
    if unitTarget:GetManaPercent() < 30 then
      utility = utility + 5
    end
    local level = unitTarget:GetLevel()
    local ownLevel = unitSelf:GetLevel()
    if level < ownLevel then
      utility = utility + 5 * (ownLevel - level)
    else
      utility = utility - 10 * (ownLevel - level)
    end
    local vecTarget = unitTarget:GetPosition()
    for nUID, unit in pairs(tEnemyHeroes) do
      if nUID ~= nTarget and core.CanSeeUnit(botBrain, unit) and Vector3.Distance2DSq(vecTarget, unit:GetPosition()) < (500 * 500) then
        utility = utility - 5
      end
    end
  end
  return unitTarget, utility
end

local function ChargeUtility(botBrain)
  local abilCharge = skills.abilCharge
  local unitSelf = core.unitSelf
  if rampage.charged ~= CHARGE_NONE then
    return 9999
  end
  if not abilCharge:CanActivate() then
    return 0
  end
  local unitTarget, utility = ChargeTarget(botBrain, unitSelf, abilCharge)
  if unitTarget then
    rampage.chargeTarget = unitTarget
    return utility
  end
  return 0
end

local function ChargeExecute(botBrain)
  local bActionTaken = false
  if botBrain.charged ~= CHARGE_NONE then
    return true
  end
  if not rampage.chargeTarget then
    return false
  end
  local abilCharge = skills.abilCharge
  if abilCharge:CanActivate() then
    bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, rampage.chargeTarget)
  end
  return bActionTaken
end

local ChargeBehavior = {}
ChargeBehavior["Utility"] = ChargeUtility
ChargeBehavior["Execute"] = ChargeExecute
ChargeBehavior["Name"] = "Charge like a boss"
tinsert(behaviorLib.tBehaviors, ChargeBehavior)
