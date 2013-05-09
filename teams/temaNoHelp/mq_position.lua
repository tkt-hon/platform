function behaviorLib.PositionSelfCreepWave(botBrain, unitCurrentTarget)
  local bDebugLines = false
  local bDebugEchos = false
  local nLineLen = 150

  if core.GetClosestEnemyTower(core.unitSelf:GetPosition(), 715) then
    return core.GetClosestAllyTower(core.unitSelf:GetPosition(), 2000)
  end

  --if botBrain.myName == "ShamanBot" then bDebugLines = true bDebugEchos = true end

  if bDebugEchos then BotEcho("PositionCreepWave") end

  --Vector-based relative position logic
  local unitSelf = core.unitSelf

  --Don't run our calculations if we're basically in the same spot
  if unitSelf.bIsMemoryUnit and unitSelf.storedTime == behaviorLib.nLastPositionTime then
    --BotEcho("early exit")
    return behaviorLib.vecLastDesiredPosition
  end

  local vecMyPos = unitSelf:GetPosition()
  local tLocalUnits = core.localUnits

  --Local references for improved performance
  local nHeroInfluencePercent = behaviorLib.nHeroInfluencePercent
  local nPositionHeroInfluenceMul = behaviorLib.nPositionHeroInfluenceMul
  local nCreepPushbackMul = behaviorLib.nCreepPushbackMul
  local vecLaneForward = object.vecLaneForward
  local vecLaneForwardOrtho = object.vecLaneForwardOrtho
  local funcGetThreat  = behaviorLib.GetThreat
  local funcGetDefense = behaviorLib.GetDefense
  local funcLethalityUtility = behaviorLib.LethalityDifferenceUtility
  local funcDistanceThreatUtility = behaviorLib.DistanceThreatUtility
  local funcGetAbsoluteAttackRangeToUnit = core.GetAbsoluteAttackRangeToUnit
  local funcV3Normalize = Vector3.Normalize
  local funcV3Dot = Vector3.Dot
  local funcAngleBetween = core.AngleBetween
  local funcRotateVec2DRad = core.RotateVec2DRad

  local nMyThreat =  funcGetThreat(unitSelf)
  local nMyDefense = funcGetDefense(unitSelf)
  local vecBackUp = behaviorLib.PositionSelfBackUp()


  local nExtraThreat = 0.0
  if unitSelf:HasState("State_HealthPotion") then
    if unitSelf:GetHealthPercent() < 0.95 then
      nExtraThreat = 10.0
    end
  end

  --Stand appart from enemies
  local vecTotalEnemyInfluence = Vector3.Create()
  local tEnemyUnits = core.CopyTable(tLocalUnits.EnemyUnits)
  core.teamBotBrain:AddMemoryUnitsToTable(tEnemyUnits, core.enemyTeam, vecMyPos)

  StartProfile('Loop')
  for nUID, unitEnemy in pairs(tEnemyUnits) do
    StartProfile('Setup')
    local bIsHero = unitEnemy:IsHero()
    local vecEnemyPos = unitEnemy:GetPosition()
    local vecTheirRange = funcGetAbsoluteAttackRangeToUnit(unitEnemy, unitSelf)
    local vecTowardsMe, nEnemyDist = funcV3Normalize(vecMyPos - vecEnemyPos)

    local nDistanceMul = funcDistanceThreatUtility(nEnemyDist, vecTheirRange, unitEnemy:GetMoveSpeed(), false) / 100

    local vecEnemyInfluence = Vector3.Create()
    StopProfile()

    if not bIsHero then
      StartProfile('Creep')

      --stand away from creeps
      if bDebugEchos then BotEcho('  creep unit: ' .. unitEnemy:GetTypeName()) end
      vecEnemyInfluence = vecTowardsMe * (nDistanceMul + nExtraThreat)

      StopProfile()
    else
      StartProfile('Hero')

      --stand away from enemy heroes
      if bDebugEchos then BotEcho('  hero unit: ' .. unitEnemy:GetTypeName()) end
      local vecHeroDir = vecTowardsMe

      local vecBackwards = funcV3Normalize(vecBackUp - vecMyPos)
      vecHeroDir = vecHeroDir * nHeroInfluencePercent + vecBackwards * (1 - nHeroInfluencePercent)

      --Calculate their lethality utility
      local nThreat = funcGetThreat(unitEnemy)
      local nDefense = funcGetDefense(unitEnemy)
      local nLethalityDifference = (nThreat - nMyDefense) - (nMyThreat - nDefense)
      local nBaseMul = 1 + (Clamp(funcLethalityUtility(nLethalityDifference), 0, 100) / 50)
      local nLength = nBaseMul * nDistanceMul

      vecEnemyInfluence = vecHeroDir * nLength * nPositionHeroInfluenceMul
      StopProfile()
    end

    StartProfile('Common')

    --enemies should not push you forward, flip it across the orthogonal line
    if vecLaneForward and funcV3Dot(vecEnemyInfluence, vecLaneForward) > 0 then
      local vecX = Vector3.Create(1,0)
      local nLaneOrthoAngle = funcAngleBetween(vecLaneForwardOrtho, vecX)

      local nInfluenceOrthoAngle = funcAngleBetween(vecEnemyInfluence, vecLaneForwardOrtho)

      local vecRelativeInfluence = funcRotateVec2DRad(vecEnemyInfluence, -nLaneOrthoAngle)
      if vecRelativeInfluence.y < 0 then
        nInfluenceOrthoAngle = -nInfluenceOrthoAngle
      end

      vecEnemyInfluence = funcRotateVec2DRad(vecEnemyInfluence, -nInfluenceOrthoAngle*2)
      --core.DrawDebugArrow(creepPos, creepPos + vecFlip * nLineLen, 'blue')
    end

    if not bIsHero then
      vecEnemyInfluence = vecEnemyInfluence * nCreepPushbackMul
    end

    --vecTotalEnemyInfluence.AddAssign(vecEnemyInfluence)
    vecTotalEnemyInfluence = vecTotalEnemyInfluence + vecEnemyInfluence

    if bDebugLines then core.DrawDebugArrow(vecEnemyPos, vecEnemyPos + vecEnemyInfluence * nLineLen, 'teal') end
    if bDebugEchos and unitEnemy then BotEcho(unitEnemy:GetTypeName()..': '..tostring(vecEnemyInfluence)) end

    StopProfile()
  end

  --stand appart from allies a bit
  StartProfile('Allies')
  local tAllyHeroes = tLocalUnits.AllyHeroes
  local vecTotalAllyInfluence = Vector3.Create()
  local nAllyInfluenceMul = behaviorLib.nAllyInfluenceMul
  local nPositionSelfAllySeparation = behaviorLib.nPositionSelfAllySeparation
  for nUID, unitAlly in pairs(tAllyHeroes) do
    local vecAllyPos = unitAlly:GetPosition()
    local vecCurrentAllyInfluence, nDistance = funcV3Normalize(vecMyPos - vecAllyPos)
    if nDistance < nPositionSelfAllySeparation then
      vecCurrentAllyInfluence = vecCurrentAllyInfluence * (1 - nDistance/nPositionSelfAllySeparation) * nAllyInfluenceMul

      --vecTotalAllyInfluence.AddAssign(vecCurrentAllyInfluence)
      vecTotalAllyInfluence = vecTotalAllyInfluence + vecCurrentAllyInfluence

      if bDebugLines then core.DrawDebugArrow(vecMyPos, vecMyPos + vecCurrentAllyInfluence * nLineLen, 'white') end
    end
  end
  StopProfile()

  --stand near your target
  StartProfile('Target')
  local vecTargetInfluence = Vector3.Create()
  local nTargetMul = behaviorLib.nTargetPositioningMul
  if unitCurrentTarget ~= nil and botBrain:CanSeeUnit(unitCurrentTarget) then
    local nMyRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitCurrentTarget)
    local vecTargetPosition = unitCurrentTarget:GetPosition()
    local vecToTarget, nTargetDist = funcV3Normalize(vecTargetPosition - vecMyPos)
    local nLength = 1
    if not unitCurrentTarget:IsHero() then
      nLength = nTargetDist / nMyRange
      if bDebugEchos then BotEcho('  nLength calc - nTargetDist: '..nTargetDist..'  nMyRange: '..nMyRange) end
    end

    nLength = Clamp(nLength, 0, 25)

    --Hack: get closer if they are critical health and we are out of nRange
    if unitCurrentTarget:GetHealth() < (core.GetFinalAttackDamageAverage(unitSelf) * 3) then --and nTargetDist > nMyRange then
      nTargetMul = behaviorLib.nTargetCriticalPositioningMul
    end

    vecTargetInfluence = vecToTarget * nLength * nTargetMul
    if bDebugEchos then BotEcho('  target '..unitCurrentTarget:GetTypeName()..': '..tostring(vecTargetInfluence)..'  nLength: '..nLength) end
  else
    if bDebugEchos then BotEcho("PositionSelfCreepWave - target is nil") end
  end
  StopProfile()

  --sum my influences
  local vecDesiredPos = vecMyPos
  local vecDesired = vecTotalEnemyInfluence + vecTargetInfluence + vecTotalAllyInfluence
  local vecMove = vecDesired * core.moveVecMultiplier

  if bDebugEchos then BotEcho('vecDesiredPos: '..tostring(vecDesiredPos)..'  vCreepInfluence: '..tostring(vecTotalEnemyInfluence)..'  vecTargetInfluence: '..tostring(vecTargetInfluence)) end

  --minimum move distance threshold
  if Vector3.LengthSq(vecMove) >= core.distSqTolerance then
    vecDesiredPos = vecDesiredPos + vecMove
  end

  behaviorLib.nLastPositionTime = unitSelf.storedTime
  behaviorLib.vecLastDesiredPosition = vecDesiredPos

  --debug
  if bDebugLines then
    if vecLaneForward then
      local offset = vecLaneForwardOrtho * (nLineLen * 3)
      core.DrawDebugArrow(vecMyPos + offset, vecMyPos + offset + vecLaneForward * nLineLen, 'white')
      core.DrawDebugArrow(vecMyPos - offset, vecMyPos - offset + vecLaneForward * nLineLen, 'white')
    end

    core.DrawDebugArrow(vecMyPos, vecMyPos + vecTotalEnemyInfluence * nLineLen, 'cyan')

    if unitCurrentTarget ~= nil and botBrain:CanSeeUnit(unitCurrentTarget) then
      local color = 'cyan'
      if nTargetMul ~= behaviorLib.nTargetPositioningMul then
        color = 'orange'
      end
      core.DrawDebugArrow(vecMyPos, vecMyPos + vecTargetInfluence * nLineLen, color)
    end

    core.DrawXPosition(vecDesiredPos, 'blue')

    core.DrawDebugArrow(vecMyPos, vecMyPos + vecDesired * nLineLen, 'blue')
    --core.DrawDebugArrow(vecMyPos, vecMyPos + vProjection * nLineLen)
  end

  return vecDesiredPos
end
