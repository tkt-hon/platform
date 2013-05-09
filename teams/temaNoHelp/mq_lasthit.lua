local function GetExpectedDamageOnCreep(unitTargetCreep)

  local bDebugEchos = false


  local unitSelf = core.unitSelf
  local nDamageMin = unitSelf:GetFinalAttackDamageMin()
  local nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()


  local vecTargetPos = unitTargetCreep:GetPosition()
  local nProjectileTravelTime = Vector3.Distance2D(unitSelf:GetPosition(), vecTargetPos) / nProjectileSpeed
  local nTotalTimeToDamage = nProjectileTravelTime * 1000 + unitSelf:GetAdjustedAttackActionTime()


  local nTargetHealth = unitTargetCreep:GetHealth()


  local nExpectedCreepDamage = 0
  local nExpectedTowerDamage = 0
  local tNearbyAttackingCreeps = nil
  local tNearbyAttackingTowers = nil


  if unitTargetCreep:GetTeam() == unitSelf:GetTeam() then
    if bDebugEchos then BotEcho("Creep is allied") end
    tNearbyAttackingCreeps = core.localUnits['EnemyCreeps']
    tNearbyAttackingTowers = core.localUnits['EnemyTowers']
  else
    if bDebugEchos then BotEcho("Creep is enemy") end
    tNearbyAttackingCreeps = core.localUnits['AllyCreeps']
    tNearbyAttackingTowers = core.localUnits['AllyTowers']
  end


  --Determine the damage expcted on the creep by other creeps
  local nCreepsAttacking = 0
  local nTowersAttacking = 0
  for i, unitCreep in pairs(tNearbyAttackingCreeps) do
    local nDistanceToTarget = Vector3.Distance2D(unitCreep:GetPosition(), vecTargetPos)
    local nCreepRange = unitCreep:GetAttackRange()

    if unitCreep:GetAttackTarget() == unitTargetCreep then
      local nCreepAttacks = 0
      local nCreepTotalTimeToDamage = unitCreep:GetAdjustedAttackActionTime()
      if bDebugEchos then BotEcho("nCreepTotalTimeToDamage just calculated: " .. nCreepTotalTimeToDamage) end


      --Melee creeps have a range of 90
      if bDebugEchos then BotEcho("nCreepRange: " .. nCreepRange) end
      if nCreepRange > 90 then
        if bDebugEchos then BotEcho("nDistanceToTarget: " .. nDistanceToTarget) end
        if bDebugEchos then BotEcho("unitCreep:GetAttackProjectileSpeed(): " .. unitCreep:GetAttackProjectileSpeed()) end
        local nCreepProjectileTravelTime = nDistanceToTarget / unitCreep:GetAttackProjectileSpeed()
        nCreepTotalTimeToDamage = nCreepTotalTimeToDamage + nCreepProjectileTravelTime * 1000


        if bDebugEchos then BotEcho("nCreepTotalTimeToDamage including projectile: " .. nCreepTotalTimeToDamage) end
        if bDebugEchos then BotEcho("nCreepProjectileTravelTime * 1000: " .. nCreepProjectileTravelTime * 1000) end
        if bDebugEchos then BotEcho("nCreepProjectileTravelTime: " .. nCreepProjectileTravelTime) end
      else
        if bDebugEchos then BotEcho("No creep projectile") end
      end


      --We adjusted nCreepTotalTimeToDamage to the correct value above
      --So no change to nCreepTotalTimeToDamage if IsAttackReady()
      if not unitCreep:IsAttackReady() then


        --Creep's attack isn't ready


        --[[
        |---------attackCooldown--------|   1700 (except for a few heroes)
        |--attackDuration--|            |   1000 (except for a few heroes)
        |-------|  (attackActionTime)   |   variable, usually 300-500
        ^  (when the attack goes off)

        |-------|                       | == "windup"
        |       |----------|            | == "followThough"
        |                  |------------| == "idle"

        the whole thing is scaled down with increased attack speed
        creeps follow the same pattern
        --]]
        local nWindupTime = unitCreep:GetAdjustedAttackActionTime()
        local nFollowThroughTime = unitCreep:GetAdjustedAttackDuration() - nWindupTime
        local nIdleTime = unitCreep:GetAdjustedAttackCooldown() - unitCreep:GetAdjustedAttackDuration()
        if bDebugEchos then BotEcho("nWindupTime: " .. nWindupTime) end
        if bDebugEchos then BotEcho("nFollowThroughTime: " .. nFollowThroughTime) end
        if bDebugEchos then BotEcho("nIdleTime: " .. nIdleTime) end


        local sAttackSequenceProgress = core.GetAttackSequenceProgress(unitCreep)


        if sAttackSequenceProgress == "windup" then
          --Assume the entire windup process is about to finish
          --That means that the damage is being applied NOW
          -- and it will take a full cycle before damage is applied again


          --Thus nCreepTotalTimeToDamage is 0 (since it happens now)
          nCreepTotalTimeToDamage = nWindupTime
          if bDebugEchos then BotEcho("windup") end


        elseif sAttackSequenceProgress == "followThough" then
          --Assume the entire windup process is about to finish
          --That means that the damage was applied nFollowThroughTime ms ago
          -- and that it will take an idle and windup cycle before damage is applied again


          --Thus we need to add nIdleTime to nCreepTotalTimeToDamage
          nCreepTotalTimeToDamage = nCreepTotalTimeToDamage + nIdleTime
          if bDebugEchos then BotEcho("followThrough") end


        elseif sAttackSequenceProgress == "idle" then
          --Assume the entire idle process is about to finish
          --That means that this is essentially the same as IsAttackReady() being true


          --So no change to nCreepTotalTimeToDamage
          if bDebugEchos then BotEcho("idle") end
        else


          if bDebugEchos then BotEcho("Unknown sAttackSequenceProgress: " .. sAttackSequenceProgress) end
        end
      else


        if bDebugEchos then BotEcho("IsAttackReady()") end


      end
      --  if bDebugEchos then BotEcho("nCreepTotalTimeToDamage: " .. nCreepTotalTimeToDamage) end
      --if bDebugEchos then BotEcho end("nTotalTimeToDamage: " .. nTotalTimeToDamage) end


      --If the creep won't be able to do damage before us, don't count any attacks
      if nCreepTotalTimeToDamage < nTotalTimeToDamage then
        --Otherwise, it will clearly have 1 attack
        --And it will also do damage the equivalent of once more every AttackCooldown
        -- AFTER that initial attack
        if bDebugEchos then BotEcho("nCreepAttacks: " .. nCreepAttacks)
          if bDebugEchos then BotEcho("nCreepAttacks: 1 + " .. math.floor((nTotalTimeToDamage - nCreepTotalTimeToDamage) / unitCreep:GetAdjustedAttackCooldown())) end
          if bDebugEchos then BotEcho("nTotalTimeToDamage - nCreepTotalTimeToDamage: " .. nTotalTimeToDamage - nCreepTotalTimeToDamage)  end
          if bDebugEchos then BotEcho("unitCreep:GetAdjustedAttackCooldown(): " .. unitCreep:GetAdjustedAttackCooldown()) end
          nCreepAttacks = 1 + math.floor((nTotalTimeToDamage - nCreepTotalTimeToDamage) / unitCreep:GetAdjustedAttackCooldown())
        end


        if bDebugEchos then BotEcho("nCreepAttacks: " .. nCreepAttacks) end
        nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
        nCreepsAttacking = nCreepsAttacking + 1
      end
    end


    for i, unitTower in pairs(tNearbyAttackingTowers) do
      local nDistanceToTarget = Vector3.Distance2D(unitTower:GetPosition(), vecTargetPos)
      local nTowerRange = unitTower:GetAttackRange()
      if nDistanceToTarget < nTowerRange and unitTower:GetAttackTarget() == unitTargetCreep then
        local nTowerAttacks = 0
        local nTowerTotalTimeToDamage = unitTower:GetAdjustedAttackActionTime()


        local nTowerProjectileTravelTime = nDistanceToTarget / unitTower:GetAttackProjectileSpeed()
        nTowerTotalTimeToDamage = nTowerTotalTimeToDamage + nTowerProjectileTravelTime * 1000


        --We adjusted nTowerTotalTimeToDamage to the correct value above
        --So no change to nTowerTotalTimeToDamage if IsAttackReady()
        if not unitTower:IsAttackReady() then


          --Tower's attack isn't ready


          --[[
          |---------attackCooldown--------|   1700 (except for a few heroes)
          |--attackDuration--|            |   1000 (except for a few heroes)
          |-------|  (attackActionTime)   |   variable, usually 300-500
          ^  (when the attack goes off)

          |-------|                       | == "windup"
          |       |----------|            | == "followThough"
          |                  |------------| == "idle"

          the whole thing is scaled down with increased attack speed
          Towers follow the same pattern
          --]]
          local nWindupTime = unitTower:GetAdjustedAttackActionTime()
          local nFollowThroughTime = unitTower:GetAdjustedAttackDuration() - nWindupTime
          local nIdleTime = unitTower:GetAdjustedAttackCooldown() - unitTower:GetAdjustedAttackDuration()


          local sAttackSequenceProgress = core.GetAttackSequenceProgress(unitTower)


          if sAttackSequenceProgress == "windup" then
            --Assume the entire windup process is about to finish
            --That means that the damage is being applied NOW
            -- and it will take a full cycle before damage is applied again


            --Thus nTowerTotalTimeToDamage is 0 (since it happens now)
            nTowerTotalTimeToDamage = 0


          elseif sAttackSequenceProgress == "followThough" then
            --Assume the entire windup process is about to finish
            --That means that the damage was applied nFollowThroughTime ms ago
            -- and that it will take an idle and windup cycle before damage is applied again


            --Thus we need to add nIdleTime to nTowerTotalTimeToDamage
            nTowerTotalTimeToDamage = nTowerTotalTimeToDamage + nIdleTime


          elseif sAttackSequenceProgress == "idle" then
            --Assume the entire idle process is about to finish
            --That means that this is essentially the same as IsAttackReady() being true


            --So no change to nTowerTotalTimeToDamage
          end


        end


        --If the Tower won't be able to do damage before us, don't count any attacks
        if nTowerTotalTimeToDamage < nTotalTimeToDamage then
          --Otherwise, it will clearly have 1 attach
          --And it will also do damage the equivalent of once more every AttackCooldown
          -- AFTER that initial attack
          nTowerAttacks = 1 + math.floor((nTotalTimeToDamage - nTowerTotalTimeToDamage) / unitTower:GetAdjustedAttackCooldown())
        end
        nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
        nTowersAttacking = nTowersAttacking + 1
      end
    end


    if nCreepsAttacking > 0 then
      if bDebugEchos then BotEcho("Expected creep damage is: " .. nExpectedCreepDamage) end
    end
    if nTowersAttacking > 0 then
      if bDebugEchos then BotEcho("Expected tower damage is: " .. nExpectedTowerDamage) end
    end


    return nExpectedCreepDamage + nExpectedTowerDamage


  end


  function behaviorLib.GetCreepAttackTarget(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
    local unitSelf = core.unitSelf
    if botBrain:GetGold() > 3000 then
      local wellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
      core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, wellPos, false)
    end


    core.nHarassBonus = 0


    local bDebugEchos = true
    -- no predictive last hitting, just wait and react when they have 1 hit left
    -- prefers LH over deny


    local unitSelf = core.unitSelf
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()


    if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
      local nTargetHealth = unitEnemyCreep:GetHealth()
      local nExpectedDamage = GetExpectedDamageOnCreep(unitEnemyCreep)

      if nDamageMin >= (nTargetHealth - nExpectedDamage) then
        local bActuallyLH = true

        -- [Tutorial] Make DS not mess with your last hitting before **** gets real
        if core.bIsTutorial and core.bTutorialBehaviorReset == false and core.unitSelf:GetTypeName() == "Hero_Shaman" then
          bActuallyLH = false
        end

        if bActuallyLH then
          if bDebugEchos then BotEcho("Returning an enemy") end
          return unitEnemyCreep
        end
      end
    end


    if unitAllyCreep then
      local nTargetHealth = unitAllyCreep:GetHealth()
      local nExpectedDamage = GetExpectedDamageOnCreep(unitAllyCreep)

      if nDamageMin >= (nTargetHealth - nExpectedDamage) then
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
    local nDamageMin = unitSelf:GetFinalAttackDamageMin()


    if unitCreepTarget and core.CanSeeUnit(botBrain, unitCreepTarget) then
      local vecTargetPos = unitCreepTarget:GetPosition()
      local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
      local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitCreepTarget, true)


      if unitCreepTarget ~= nil then


        local nExpectedDamage = GetExpectedDamageOnCreep(unitCreepTarget)


        if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() and nDamageMin>=(unitCreepTarget:GetHealth() - nExpectedDamage) then --only kill if you can get gold
          --only attack when in nRange, so not to aggro towers/creeps until necessary, and move forward when attack is on cd
          core.OrderAttackClamp(botBrain, unitSelf, unitCreepTarget)
        elseif (nDistSq > nAttackRangeSq * (0.6*0.6)) then
          --SR is a ranged hero - get somewhat closer to creep to slow down projectile travel time
          --BotEcho("MOVIN OUT")
          local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
          core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)
        else
          core.OrderHoldClamp(botBrain, unitSelf, false)
        end
      end
    else
      return false
    end
  end
end
