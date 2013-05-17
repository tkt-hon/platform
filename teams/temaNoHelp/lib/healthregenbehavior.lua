local _G = getfenv(0)
local object = _G.object

local max, tinsert, abs = _G.math.max, _G.table.insert, _G.math.abs

local core, behaviorLib, eventsLib = object.core, object.behaviorLib, object.eventsLib

local Clamp = core.Clamp

behaviorLib.nBottleUtility = 0
behaviorLib.nPowerSupplyUtility = 0

function behaviorLib.BottleUtilFn(nHealthMissing)
  --Roughly 20+ when we are down 138 hp (which is when we want to use a rune)
  -- Fn which crosses 20 at x=138 and is 30 at roughly x=600, convex down

  local nHealAmount = 150
  local nUtilityThreshold = 20

  local vecPoint = Vector3.Create(nHealAmount, nUtilityThreshold)
  local vecOrigin = Vector3.Create(-1000, -20)

  local nUtility = core.ATanFn(nHealthMissing, vecPoint, vecOrigin, 100)
  return nUtility
end

function behaviorLib.PowerSupplyUtilFn(nHealthMissing)
  --Roughly 20+ when we are down 138 hp (which is when we want to use a rune)
  -- Fn which crosses 20 at x=138 and is 30 at roughly x=600, convex down
  if nHealthMissing > 10 then
    return 100
  end
  return 0
end

function behaviorLib.UseHealthRegenUtility(botBrain)
  StartProfile("Init")

  local nUtility = 0
  local nCurrentTime = HoN.GetGameTime()
  local unitSelf = core.unitSelf
  local vecPos = unitSelf:GetPosition()
  local nHealth = unitSelf:GetHealth()
  local nMaxHealth = unitSelf:GetMaxHealth()
  local nHealthMissing = nMaxHealth - nHealth
  local nHalfSafeTreeAngle = behaviorLib.safeTreeAngle / 2

  local nHealthPotUtility = 0
  local nBlightsUtility = 0
  local nBottleUtility = 0
  local nPowerSupplyUtility = 0
  StopProfile()

  if unitSelf:HasState("State_PowerupRegen") then
    return 0
  end

  StartProfile("Health pot")
  local tInventory = unitSelf:GetInventory()
  local idefHealthPotion = core.idefHealthPotion
  local tHealthPots = core.InventoryContains(tInventory, idefHealthPotion:GetName())
  if #tHealthPots > 0 and not unitSelf:HasState(idefHealthPotion.stateName) then
    nHealthPotUtility = behaviorLib.HealthPotUtilFn(nHealthMissing)
  end
  StopProfile()

  StartProfile("Runes")
  local idefBlights = core.idefBlightStones
  local tBlights = core.InventoryContains(tInventory, idefBlights:GetName())
  if #tBlights > 0 and not unitSelf:HasState(idefBlights.stateName) then
    local bSafeTrees = false

    local tTrees = core.localTrees
    local funcRadToDeg = core.RadToDeg
    local funcAngleBetween = core.AngleBetween

    nBlightsUtility = behaviorLib.RunesOfTheBlightUtilFn(nHealthMissing)

    if nBlightsUtility < behaviorLib.runeUtilIntercept then
      nBlightsUtility = 0 --no need to report if it isn't a meaningful value
    end
  end
  StopProfile()

  StartProfile("Bottle")
  local tBottles = core.InventoryContains(tInventory, "Item_Bottle")
  local notEmptyBottles = false
  if #tBottles > 0 and not unitSelf:HasState("State_Bottle") and tBottles[1]:GetActiveModifierKey() ~= "bottle_empty" then
    nBottleUtility = behaviorLib.BottleUtilFn(nHealthMissing)
  end
  StopProfile()

  StartProfile("PowerSupply")
  local tPower = core.InventoryContains(tInventory, "Item_PowerSupply")
  if #tPower > 0 and tPower[1]:CanActivate() then
    nPowerSupplyUtility = behaviorLib.PowerSupplyUtilFn(nHealthMissing)
  end
  StopProfile()

  StartProfile("End")
  nUtility = max(nHealthPotUtility, nBlightsUtility, nBottleUtility)
  nUtility = Clamp(nUtility, 0, 100)

  if nBlightsUtility == 0 and nHealthPotUtility == 0 and nBottleUtility == 0 then
    nUtility = 0
  end

  behaviorLib.nHealthPotUtility = nHealthPotUtility
  behaviorLib.nBlightsUtility = nBlightsUtility
  behaviorLib.nBottleUtility = nBottleUtility
  behaviorLib.nPowerSupplyUtility = nPowerSupplyUtility

  return nUtility
end

function behaviorLib.UseHealthRegenExecute(botBrain)
  local bDebugLines = false

  local unitSelf = core.unitSelf
  local vecSelfPos = unitSelf:GetPosition()
  local tInventory = unitSelf:GetInventory()
  local idefBlights = core.idefBlightStones
  local idefHealthPotion = core.idefHealthPotion

  local tBlights = core.InventoryContains(tInventory, "Item_RunesOfTheBlight")
  local tHealthPots = core.InventoryContains(tInventory, "Item_HealthPotion")
  local tBottles = core.InventoryContains(tInventory, "Item_Bottle")

  if behaviorLib.nBlightsUtility > behaviorLib.nHealthPotUtility and behaviorLib.nBlightsUtility > behaviorLib.nBottleUtility then
    if #tBlights > 0 and not unitSelf:HasState(idefBlights.stateName) then
      --get closest tree
      local closestTree = nil
      local nClosestTreeDistSq = 9999*9999
      local vecLaneForward = object.vecLaneForward
      local vecLaneForwardNeg = -vecLaneForward
      local funcRadToDeg = core.RadToDeg
      local funcAngleBetween = core.AngleBetween
      local nHalfSafeTreeAngle = behaviorLib.safeTreeAngle / 2

      core.UpdateLocalTrees()
      local tTrees = core.localTrees
      for key, tree in pairs(tTrees) do
        vecTreePosition = tree:GetPosition()

        --"safe" trees are backwards
        if not vecLaneForward or abs(funcRadToDeg(funcAngleBetween(vecTreePosition - vecSelfPos, vecLaneForwardNeg)) ) < nHalfSafeTreeAngle then
          local nDistSq = Vector3.Distance2DSq(vecTreePosition, vecSelfPos)
          if nDistSq < nClosestTreeDistSq then
            closestTree = tree
            nClosestTreeDistSq = nDistSq
            if bDebugLines then
              core.DrawXPosition(vecTreePosition, 'yellow')
            end
          end
        end
      end

      if closestTree ~= nil then
        --BotEcho("Using blights!")
        core.OrderItemEntityClamp(botBrain, unitSelf, tBlights[1], closestTree)
        return
      end

      -- No good tree, so we failed to execute this behavior
      return false
    end
  elseif behaviorLib.nHealthPotUtility > behaviorLib.nBlightsUtility and behaviorLib.nHealthPotUtility > behaviorLib.nBottleUtility then
    if not unitSelf:HasState(idefHealthPotion.stateName) and #tHealthPots > 0 then
      --assess local units to see if they are in nRange, retreat until out of nRange * 1.15
      --also don't use if we are taking DOT damage
      local threateningUnits = {}
      local curTimeMS = HoN.GetGameTime()

      for id, unit in pairs(core.localUnits["EnemyUnits"]) do
        local absRange = core.GetAbsoluteAttackRangeToUnit(unit, unitSelf)
        local nDist = Vector3.Distance2D(vecSelfPos, unit:GetPosition())
        if nDist < absRange * 1.15 then
          local unitPair = {}
          unitPair[1] = unit
          unitPair[2] = (absRange * 1.15 - nDist)
          tinsert(threateningUnits, unitPair)
        end
      end

      --[[
      BotEcho(format("threateningUnits: %d recentDotCD: %d projectiles: %d",
      core.NumberElements(threateningUnits), (eventsLib.recentDotTime-curTimeMS), #eventsLib.incomingProjectiles["all"]
      )) --]]

      if core.NumberElements(threateningUnits) > 0 or eventsLib.recentDotTime > curTimeMS or #eventsLib.incomingProjectiles["all"] > 0 then
        --retreat. determine best "away from threat" vector
        local awayVec = Vector3.Create()
        local totalExcessRange = 0
        for key, unitPair in pairs(threateningUnits) do
          local unitAwayVec = Vector3.Normalize(vecSelfPos - unitPair[1]:GetPosition())
          awayVec = awayVec + unitAwayVec * unitPair[2]

          if bDebugLines then
            core.DrawDebugArrow(unitPair[1]:GetPosition(), unitPair[1]:GetPosition() + unitAwayVec * unitPair[2], 'teal')
          end
        end

        if core.NumberElements(threateningUnits) > 0 then
          awayVec = Vector3.Normalize(awayVec)
        end

        --average awayVec with "retreat" vector
        local retreatVec = Vector3.Normalize(behaviorLib.PositionSelfBackUp() - vecSelfPos)
        local moveVec = Vector3.Normalize(awayVec + retreatVec)

        core.OrderMoveToPosClamp(botBrain, unitSelf, vecSelfPos + moveVec * core.moveVecMultiplier, false)

      else
        --BotEcho("Using health potion!")
        core.OrderItemEntityClamp(botBrain, unitSelf, tHealthPots[1], unitSelf)
        return
      end
    end
  else
    if not unitSelf:HasState("State_Bottle") and #tBottles > 0 then
      --assess local units to see if they are in nRange, retreat until out of nRange * 1.15
      --also don't use if we are taking DOT damage
      local threateningUnits = {}
      local curTimeMS = HoN.GetGameTime()

      for id, unit in pairs(core.localUnits["EnemyUnits"]) do
        local absRange = core.GetAbsoluteAttackRangeToUnit(unit, unitSelf)
        local nDist = Vector3.Distance2D(vecSelfPos, unit:GetPosition())
        if nDist < absRange * 1.15 then
          local unitPair = {}
          unitPair[1] = unit
          unitPair[2] = (absRange * 1.15 - nDist)
          tinsert(threateningUnits, unitPair)
        end
      end

      if core.NumberElements(threateningUnits) > 0 or eventsLib.recentDotTime > curTimeMS or #eventsLib.incomingProjectiles["all"] > 0 then
        --retreat. determine best "away from threat" vector
        local awayVec = Vector3.Create()
        local totalExcessRange = 0
        for key, unitPair in pairs(threateningUnits) do
          local unitAwayVec = Vector3.Normalize(vecSelfPos - unitPair[1]:GetPosition())
          awayVec = awayVec + unitAwayVec * unitPair[2]

          if bDebugLines then
            core.DrawDebugArrow(unitPair[1]:GetPosition(), unitPair[1]:GetPosition() + unitAwayVec * unitPair[2], 'teal')
          end
        end

        if core.NumberElements(threateningUnits) > 0 then
          awayVec = Vector3.Normalize(awayVec)
        end

        --average awayVec with "retreat" vector
        local retreatVec = Vector3.Normalize(behaviorLib.PositionSelfBackUp() - vecSelfPos)
        local moveVec = Vector3.Normalize(awayVec + retreatVec)

        core.OrderMoveToPosClamp(botBrain, unitSelf, vecSelfPos + moveVec * core.moveVecMultiplier, false)
      else
        core.OrderItemClamp(botBrain, unitSelf, tBottles[1])
        return
      end
    end
  end

  return
end

behaviorLib.UseHealthRegenBehavior["Utility"] = behaviorLib.UseHealthRegenUtility
behaviorLib.UseHealthRegenBehavior["Execute"] = behaviorLib.UseHealthRegenExecute

local function HealAtWellUtilityOverrive(botBrain)
  local unitSelf = core.unitSelf
  local nUtility = behaviorLib.HealAtWellUtility(botBrain)
  local tInventory = unitSelf:GetInventory()
  local tHealthPots = core.InventoryContains(tInventory, "Item_HealthPotion")
  local tBottles = core.InventoryContains(tInventory, "Item_Bottle")
  local notEmptyBottles = false
  if #tBottles > 0 and tBottles[1]:GetActiveModifierKey() ~= "bottle_empty" or #tHealthPots > 0 then
    nUtility = nUtility / 2
  end
  return nUtility
end
behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellUtilityOverrive
