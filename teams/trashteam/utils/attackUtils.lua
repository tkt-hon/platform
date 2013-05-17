local _G = getfenv(0)
local lastHitter = _G.object

local core, behaviorLib = lastHitter.core, lastHitter.behaviorLib

local BotEcho = core.BotEcho

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
    local armor = unitCreepTarget:GetArmor()
    local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
    nDamageMin = nDamageMin*dmgReduc


    --Get projectile info
    local nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()
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
        if core.CanSeeUnit(botBrain, unitCreep) and unitCreep:GetAttackTarget() == unitCreepTarget then
            local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
            nExpectedCreepDamage = nExpectedCreepDamage + (unitCreep:GetFinalAttackDamageMin() +1)* nCreepAttacks
        end
    end


    --Determine the damage expected on the creep by other tower
    for i, unitTower in pairs(tNearbyAttackingTowers) do
        if core.CanSeeUnit(botBrain, unitTower) and unitTower:GetAttackTarget() == unitCreepTarget then
            local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
            nExpectedTowerDamage = nExpectedTowerDamage + (unitTower:GetFinalAttackDamageMin() +1) * nTowerAttacks
        end
    end


    return dmgReduc*(nExpectedCreepDamage + nExpectedTowerDamage)
end


function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
    local bDebugEchos = false

    local unitSelf = core.unitSelf
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()
    local mostHealth = 0
    local backupUnit = nil


    if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
      local nTargetHealth = unitEnemyCreep:GetHealth()
      local armor = unitEnemyCreep:GetArmor()
      local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
      nDamageMin = nDamageMin*dmgReduc
      local healthAfter = nTargetHealth - dmgReduc * GetAttackDamageOnCreep(botBrain, unitEnemyCreep)
      if mostHealth < nTargetHealth then
        backupUnit = unitEnemyCreep
        mostHealth = nTargetHealth
      end
      if nDamageMin >= healthAfter then
        if bDebugEchos then BotEcho("Returning an enemy") end
        return unitEnemyCreep
      end
    end

    if unitAllyCreep and core.CanSeeUnit(botBrain, unitAllyCreep) then
      local nTargetHealth = unitAllyCreep:GetHealth()
      local armor = unitAllyCreep:GetArmor() -- 5
      local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
      nDamageMin = nDamageMin*dmgReduc
      local healthAfter = nTargetHealth - dmgReduc * GetAttackDamageOnCreep(botBrain, unitAllyCreep)
      if mostHealth < nTargetHealth then
        backupUnit = unitAllyCreep
        mostHealth = nTargetHealth
      end
      if nDamageMin >= healthAfter then
        if bDebugEchos then BotEcho("Returning an ally") end
        return unitAllyCreep
      end
    end
    if backupUnit and backupUnit:GetHealthPercent() < 0.6 then
      backupUnit = nil
    end

    return backupUnit
end


function AttackCreepsExecuteOverride(botBrain)
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
        local armor = unitCreepTarget:GetArmor()
        local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
        nDamageMin = nDamageMin*dmgReduc

        if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitCreepTarget)+8) then
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
object.AttackCreepsExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteOverride
