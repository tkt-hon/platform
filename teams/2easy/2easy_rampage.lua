local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = rampage.core, rampage.behaviorLib
local tinsert = _G.table.insert

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_LoggersHatchet", "Item_IronBuckler" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_EnhancedMarchers", "Item_Shield2"}
behaviorLib.MidItems = {"Item_LifeSteal5"}
behaviorLib.LateItems = {}

rampage.skills = {}
local skills = rampage.skills

rampage.tSkills = {
  2, 1, 2, 0, 2,
  3, 2, 1, 1, 1,
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

-- Harass Utility
local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 15
  if skills.abilBash:IsReady() then
    nUtil = nUtil + 25
  end
  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

-- Harass Execute
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

    if abilCharge:CanActivate() and unitTarget.GetHealthPercent() < 0.25 then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, unitTarget)
    end

  end

  if not bActionTaken then
    return rampage.harassExecuteOld(botBrain)
  end
end
rampage.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

-- Use hatchet

local function advancedThinkUtility(botBrain)
        return 95; --always ridiculously important. Though, this rarly returns true.
end

local function advancedThinkExecute(botBrain)
        local unitSelf = core.unitSelf
        local vecSelfPos = unitSelf:GetPosition()
        local vecWellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
        local distToWellSq=Vector3.Distance2DSq(vecSelfPos, vecWellPos)
        local bActionTaken=false
       
        --remove invalid hatchet item.
        if core.itemHatchet ~= nil and not core.itemHatchet:IsValid() then
                core.itemHatchet = nil
        end
        --hatchet
        if not bActionTaken and core.unitCreepTarget and core.itemHatchet and core.itemHatchet:CanActivate() and --can activate
          Vector3.Distance2DSq(unitSelf:GetPosition(), core.unitCreepTarget:GetPosition()) <= 600*600 and --in range of hatchet.
          unitSelf:GetBaseDamage()*(1-core.unitCreepTarget:GetPhysicalResistance())>core.unitCreepTarget:GetHealth() and --low enough hp, killable
          string.find(core.unitCreepTarget:GetTypeName(), "Creep") then-- viable creep (this makes it ignore minions etc, some of which aren't hatchetable.)
                bActionTaken=botBrain:OrderItemEntity(core.itemHatchet.object or core.itemHatchet, core.unitCreepTarget.object or core.unitCreepTarget, false)--use hatchet.
        end
       
        return bActionTaken
end
behaviorLib.advancedThink = {}
behaviorLib.advancedThink["Utility"] = advancedThinkUtility
behaviorLib.advancedThink["Execute"] = advancedThinkExecute
behaviorLib.advancedThink["Name"] = "advancedThink"
tinsert(behaviorLib.tBehaviors, behaviorLib.advancedThink)

-- Creep Attack Target Override
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
