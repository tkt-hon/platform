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
      local armor = unitCreepTarget:GetArmor()
      local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)

    --Get projectile info
    local nProjectileTravelTime = 0.5
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
            nExpectedCreepDamage = nExpectedCreepDamage + (unitCreep:GetFinalAttackDamageMin() +1)* nCreepAttacks
        end
    end


    --Determine the damage expected on the creep by other towers
    for i, unitTower in pairs(tNearbyAttackingTowers) do
        if unitTower:GetAttackTarget() == unitCreepTarget then
            local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
            nExpectedTowerDamage = nExpectedTowerDamage + (unitTower:GetFinalAttackDamageMin() +1) * nTowerAttacks
        end
    end


    return dmgReduc*(nExpectedCreepDamage + nExpectedTowerDamage)
end


function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
    local bDebugEchos = false


    --Get info about self
    local unitSelf = core.unitSelf
    local hornedDmg = {0, 60, 80, 100, 120}
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()
    local horned = hornedDmg[unitSelf:GetAbility(2):GetLevel()+1]



    if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
      local nTargetHealth = unitEnemyCreep:GetHealth()
      local armor = unitEnemyCreep:GetArmor() -- 5
      local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
      nDamageMin = nDamageMin*dmgReduc
      horned = horned*dmgReduc
        --Only attack if, by the time our attack reaches the target
        -- the damage done by other sources brings the target's health
        -- below our minimum damage
        if nDamageMin+horned >= (nTargetHealth - dmgReduc * GetAttackDamageOnCreep(botBrain, unitEnemyCreep)) then
            if bDebugEchos then BotEcho("Returning an enemy") end
            return unitEnemyCreep
        end
    end


    if unitAllyCreep then
        local nTargetHealth = unitAllyCreep:GetHealth()
      local armor = unitAllyCreep:GetArmor() -- 5
      local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
      nDamageMin = nDamageMin*dmgReduc


        --Only attack if, by the time our attack reaches the target
        -- the damage done by other sources brings the target's health
        -- below our minimum damage
        if nDamageMin >= (nTargetHealth - dmgReduc * GetAttackDamageOnCreep(botBrain, unitAllyCreep)) then
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
        local hornedDmg = {0,60, 80, 100, 120}
        local nDamageMin = unitSelf:GetFinalAttackDamageMin()
        local horned = hornedDmg[unitSelf:GetAbility(2):GetLevel()+1]
        local armor = unitCreepTarget:GetArmor()
        local dmgReduc = 1 - (armor*0.06)/(1+0.06*armor)
        nDamageMin = nDamageMin*dmgReduc
        horned = horned * dmgReduc

        --Only attack if, by the time our attack reaches the target
        -- the damage done by other sources brings the target's health
        -- below our minimum damage, and we are in range and can attack right now
        if not (unitCreepTarget:GetTeam() == botBrain:GetTeam()) then
          nDamageMin = nDamageMin + horned
        end
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
object.AttackCreepsExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteOverride
