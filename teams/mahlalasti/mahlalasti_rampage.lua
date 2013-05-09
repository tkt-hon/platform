local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = rampage.core, rampage.behaviorLib
local BotEcho = core.BotEcho

local tinsert = _G.table.insert
-- muutettu itemeitä lanelle, defaultin manabattery ei ehkä optimi kun ei ole castereita vastassa
behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_IronBuckler", "Item_LoggersHatchet" }
behaviorLib.LaneItems = {"Item_Scarab", "Item_Marchers", "Item_Lifetube" }
behaviorLib.MidItems = { "Item_EnhancedMarchers", "Item_Shield2"}
behaviorLib.LateItems = { "Item_PortalKey", "Item_DaemonicBreastplate" }

local CHARGE_NONE, CHARGE_STARTED, CHARGE_TIMER, CHARGE_WARP = 0, 1, 2, 3

rampage.charged = CHARGE_NONE

rampage.skills = {}
local skills = rampage.skills

-- Tarkka Skill Up -järjestys
-- Sama buildi kun defaultilla atm
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

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function rampage:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- Tämänhetkisen Behaviorin tulostus All-chattiin
  local matchtime = HoN.GetMatchTime()
  if matchtime ~= 0 and matchtime % 2000 == 0 then
    self:Chat("Current behavior: " .. core.GetCurrentBehaviorName(self))
  end
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

local function CustomHarassUtilityFnOverride(hero)
  local unitSelf = core.unitSelf
  local nUtil = 0
  -- Onko vihu oman tornin rangella (ts. löytyykö 600 unitin radiukselta vihun ympärillä allyTower)
  local EnemyInsideAlliedTowerRange = core.GetClosestAllyTower(hero:GetPosition(), 600)
  -- Ollaanko itse vihollistornin rangella (:---D)
  local SelfInsideEnemyTowerRange = core.GetClosestEnemyTower(unitSelf:GetPosition(),600)

  if EnemyInsideAlliedTowerRange then 
   nUtil = nUtil + 60
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

  if SelfInsideEnemyTowerRange then
    nUtil = nUtil - 50
  end  

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

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
  HoN.DrawDebugLine (unitSelf:GetPosition(), unitTarget:GetPosition(),true,"green")
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
      utility = 40
    end
    if unitTarget:GetManaPercent() < 30 then
      utility = utility + 5
    end
    local level = unitTarget:GetLevel()
    local ownLevel = unitSelf:GetLevel()
    if level < ownLevel then
      utility = utility + 10 * (ownLevel - level)
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

function behaviorLib.bigPurseUtility(botBrain)

    local level = core.unitSelf:GetLevel()
    local multiplier = level*0.18
    if level < 5 then
    rampage.purseMax = 1000
    rampage.purseMin = 600
    elseif level >= 5 then
    rampage.purseMax = 1650*multiplier
    rampage.purseMin = 700*multiplier
end
    local bDebugEchos = false
     
    local Clamp = core.Clamp
    local m = (100/(rampage.purseMax - rampage.purseMin))
    nUtil = m*botBrain:GetGold() - m*rampage.purseMin
    nUtil = Clamp(nUtil,0,100)
 
    if bDebugEchos then core.BotEcho("Bot return Priority:" ..nUtil) end
 
    return nUtil
end
 
-- Execute
function behaviorLib.bigPurseExecute(botBrain)
    local unitSelf = core.unitSelf
 
    local wellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
    core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, wellPos, false) 
 end
 
behaviorLib.bigPurseBehavior = {}
behaviorLib.bigPurseBehavior["Utility"] = behaviorLib.bigPurseUtility
behaviorLib.bigPurseBehavior["Execute"] = behaviorLib.bigPurseExecute
behaviorLib.bigPurseBehavior["Name"] = "bigPurse"
tinsert(behaviorLib.tBehaviors, behaviorLib.bigPurseBehavior)


--Kairus101's last hitter
function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) 
--called pretty much constantly 
   unitSelf=core.unitSelf
    local bDebugEchos = false
    -- predictive last hitting, don't just wait and react when they have 1 hit left (that would be stupid. T_T)
 
 
    local unitSelf = core.unitSelf
    local nDamageAverage = unitSelf:GetFinalAttackDamageMin()+40 --make the hero go to the unit when it is 40 hp away
    core.FindItems(botBrain)
    if core.itemHatchet then
        nDamageAverage = nDamageAverage * core.itemHatchet.creepDamageMul
    end   
    -- [Difficulty: Easy] Make bots worse at last hitting
    if core.nDifficulty == core.nEASY_DIFFICULTY then
        nDamageAverage = nDamageAverage + 120
    end
    if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
        local nTargetHealth = unitEnemyCreep:GetHealth()
        if nDamageAverage >= nTargetHealth then
            local bActuallyLH = true
            if bDebugEchos then BotEcho("Returning an enemy") end
            return unitEnemyCreep
        end
    end
 
 
    if unitAllyCreep then
        local nTargetHealth = unitAllyCreep:GetHealth()
        if nDamageAverage >= nTargetHealth then
            local bActuallyDeny = true
 
 
            --[Difficulty: Easy] Don't deny
            if core.nDifficulty == core.nEASY_DIFFICULTY then
                bActuallyDeny = false
            end           
 
 
            -- [Tutorial] Hellbourne *will* deny creeps after **** gets real
            if core.bIsTutorial and core.bTutorialBehaviorReset == true and core.myTeam == HoN.GetHellbourneTeam() then
                bActuallyDeny = true
            end
 
 
            if bActuallyDeny then
                if bDebugEchos then BotEcho("Returning an ally") end
                return unitAllyCreep
            end
        end
    end
    return nil
end
 
 
function KaiAttackCreepsExecuteOverride(botBrain)
    local unitSelf = core.unitSelf
    local currentTarget = core.unitCreepTarget
 
 
    if currentTarget and core.CanSeeUnit(botBrain, currentTarget) then       
        local vecTargetPos = currentTarget:GetPosition()
        local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
        local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)
         
        local nDamageAverage = unitSelf:GetFinalAttackDamageMin()if core.itemHatchet then
nDamageAverage = nDamageAverage * core.itemHatchet.creepDamageMul
end
 
 
        if currentTarget ~= nil then
            if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and nDamageAverage>=currentTarget:GetHealth() then --only kill if you can get gold
                --only attack when in nRange, so not to aggro towers/creeps until necessary, and move forward when attack is on cd
                core.OrderAttackClamp(botBrain, unitSelf, currentTarget)
            elseif (nDistSq > nAttackRangeSq) then
                local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
                core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false) --moves hero to target
            else
                core.OrderHoldClamp(botBrain, unitSelf, false) --this is where the magic happens. Wait for the kill.
            end
        end
    else
        return false
    end
end
object.AttackCreepsExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.AttackCreepsBehavior["Execute"] = KaiAttackCreepsExecuteOverride


