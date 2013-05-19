local _G = getfenv(0)
local herobot = _G.object

herobot.myName = herobot:GetName()

herobot.bRunLogic = true
herobot.bRunBehaviors = true
herobot.bUpdates = true
herobot.bUseShop = true

herobot.bRunCommands = true
herobot.bMoveCommands = true
herobot.bAttackCommands = true
herobot.bAbilityCommands = true
herobot.bOtherCommands = true

herobot.bReportBehavior = false
herobot.bDebugUtility = false

herobot.logger = {}
herobot.logger.bWriteLog = false
herobot.logger.bVerboseLog = false

herobot.core = {}
herobot.eventsLib = {}
herobot.metadata = {}
herobot.behaviorLib = {}
herobot.skills = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, behaviorLib = herobot.core, herobot.behaviorLib

object.tSkills = {
  0, 1, 0, 1, 0,
  3, 0, 1, 1, 2,
  3, 2, 2, 2, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}

function herobot:SkillBuild()
  core.VerboseLog("skillbuild()")

  local unitSelf = self.core.unitSelf
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local nlev = unitSelf:GetLevel()
  local nlevpts = unitSelf:GetAbilityPointsAvailable()
  local nStartPoint = 1+nlev-nlevpts
  for i = nStartPoint, nlev do
    unitSelf:GetAbility( self.tSkills[i] ):LevelUp()
  end
end

local function GetAttackDamageOnCreep(botBrain, unitCreepTarget)
  if not unitCreepTarget or not core.CanSeeUnit(botBrain, unitCreepTarget) then
    return nil
  end


  local unitSelf = core.unitSelf


  --Get info about the target we are about to attack
  local vecSelfPos = unitSelf:GetPosition()
  local vecTargetPos = unitCreepTarget:GetPosition()
  local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
  local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)
  local nTargetHealth = unitCreepTarget:GetHealth()
  local nDamageMin = unitSelf:GetFinalAttackDamageMin()
  --print(vecSelfPos, "|", vecTargetPos, "|", nDistSq, "|", nAttackRangeSq, "|", nTargetHealth, "|", nDamageMin)

  --Get projectile info
  local nProjectileSpeed = 9000
  if unitSelf:GetAttackType() == "ranged" then
    nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()
  end
  local nProjectileTravelTime = Vector3.Distance2D(vecSelfPos, vecTargetPos) / nProjectileSpeed
  if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end

  local nExpectedCreepDamage = 0
  local nExpectedTowerDamage = 0
  local tNearbyAttackingCreeps = nil
  local tNearbyAttackingTowers = nil


  --Get the creeps and towers on the opposite team
  -- of our target
  if unitCreepTarget:GetTeam() == unitSelf:GetTeam() then
    tNearbyAttackingCreeps = core.localUnits['EnemyCreeps']
    tNearbyAttackingTowers = core.localUnits['EnemyTowers']
  else
    tNearbyAttackingCreeps = core.localUnits['AllyCreeps']
    tNearbyAttackingTowers = core.localUnits['AllyTowers']
  end


  --Determine the damage expected on the creep by other creeps
  for i, unitCreep in pairs(tNearbyAttackingCreeps) do
    if unitCreep:GetAttackTarget() == unitCreepTarget then
      local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
      nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
    end
  end


  --Determine the damage expected on the creep by other towers
  for i, unitTower in pairs(tNearbyAttackingTowers) do
    if unitTower:GetAttackTarget() == unitCreepTarget then
      local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
      nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
    end
  end


  return nExpectedCreepDamage + nExpectedTowerDamage
end


function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
  local bDebugEchos = false


  --Get info about self
  local unitSelf = core.unitSelf
  local nDamageMin = unitSelf:GetFinalAttackDamageMin()


  if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
    local nTargetHealth = unitEnemyCreep:GetHealth()
    --Only attack if, by the time our attack reaches the target
    -- the damage done by other sources brings the target's health
    -- below our minimum damage
    if nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitEnemyCreep)) then
      if bDebugEchos then BotEcho("Returning an enemy") end
      return unitEnemyCreep
    end
  end


  if unitAllyCreep then
    local nTargetHealth = unitAllyCreep:GetHealth()


    --Only attack if, by the time our attack reaches the target
    -- the damage done by other sources brings the target's health
    -- below our minimum damage
    if nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitAllyCreep)) then
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


function herobot.AttackCreepsExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  local unitCreepTarget = core.unitCreepTarget


  if unitCreepTarget and core.CanSeeUnit(botBrain, unitCreepTarget) then
    --Get info about the target we are about to attack
    local vecSelfPos = unitSelf:GetPosition()
    local vecTargetPos = unitCreepTarget:GetPosition()
    local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)
    local nTargetHealth = unitCreepTarget:GetHealth()
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()

    --Only attack if, by the time our attack reaches the target
    -- the damage done by other sources brings the target's health
    -- below our minimum damage, and we are in range and can attack right now
    if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitCreepTarget)) then
      core.OrderAttackClamp(botBrain, unitSelf, unitCreepTarget)


      --Otherwise get within 70% of attack range if not already
      -- This will decrease travel time for the projectile
    elseif (nDistSq > nAttackRangeSq * 0.5) then
      local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
      core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)


      --If within a good range, just hold tight
    else
      core.OrderHoldClamp(botBrain, unitSelf, false)
    end
  else
    return false
  end
end
herobot.AttackCreepsExecuteOld = behaviorLib.AttackCreepsBehavior["Execute"]
behaviorLib.AttackCreepsBehavior["Execute"] = herobot.AttackCreepsExecuteOverride
