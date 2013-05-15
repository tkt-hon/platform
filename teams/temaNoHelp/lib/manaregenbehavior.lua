local _G = getfenv(0)
local object = _G.object

local max, tinsert, abs = _G.math.max, _G.table.insert, _G.math.abs

local core, behaviorLib, eventsLib = object.core, object.behaviorLib, object.eventsLib

local Clamp = core.Clamp

behaviorLib.nManaPotUtility = 0
behaviorLib.nRoSUtility = 0
behaviorLib.nBottleManaUtility = 0

function behaviorLib.BottleManaUtilFn(nManaMissing)
  local nManaAmount = 50
  local nUtilityThreshold = 20

  local vecPoint = Vector3.Create(nManaAmount, nUtilityThreshold)
  local vecOrigin = Vector3.Create(-1000, -20)

  local nUtility = core.ATanFn(nManaMissing, vecPoint, vecOrigin, 100)
  return nUtility
end

function behaviorLib.RoSUtilFn(nManaMissing)
  local nManaAmount = 135
  local nUtilityThreshold = 20

  local vecPoint = Vector3.Create(nManaAmount, nUtilityThreshold)
  local vecOrigin = Vector3.Create(-1000, -20)

  local nUtility = core.ATanFn(nManaMissing, vecPoint, vecOrigin, 100)
  return nUtility
end

function behaviorLib.UseManaRegenUtility(botBrain)
  StartProfile("Init")

  local nUtility = 0
  local nCurrentTime = HoN.GetGameTime()
  local unitSelf = core.unitSelf
  local vecPos = unitSelf:GetPosition()
  local nMana = unitSelf:GetMana()
  local nMaxMana = unitSelf:GetMaxMana()
  local nManaMissing = nMaxMana - nMana

  local nManaPotUtility = 0
  local nRoSUtility = 0
  local nBottleUtility = 0
  StopProfile()

  if unitSelf:HasState("State_PowerupRegen") then
    return 0
  end

  StartProfile("Mana pot")
  local tInventory = unitSelf:GetInventory()
  local idefManaPotion = core.idefManaPotion
  local tManaPots = core.InventoryContains(tInventory, "Item_ManaPotion")
  if #tManaPots > 0 and not unitSelf:HasState("State_ManaPotion") then
    nManaPotUtility = behaviorLib.ManaPotUtilFn(nManaMissing)
  end
  StopProfile()

  StartProfile("Ring of Sorcery")
  local tRoSs = core.InventoryContains(tInventory, "Item_Replenish")
  if #tRoSs > 0 and tRoSs[1]:CanActivate() then
    nRoSUtility = behaviorLib.RoSUtilFn(nManaMissing)
  end
  StopProfile()

  StartProfile("Bottle")
  local tBottles = core.InventoryContains(tInventory, "Item_Bottle")
  local notEmptyBottles = false
  if #tBottles > 0 and not unitSelf:HasState("State_Bottle") and tBottles[1]:GetActiveModifierKey() ~= "bottle_empty" then
    nBottleUtility = behaviorLib.BottleManaUtilFn(nManaMissing)
  end
  StopProfile()

  StartProfile("End")
  if nRoSUtility > 0 then
    nManaPotUtility = 0
    nBottleUtility = 0
  end
  nUtility = max(nManaPotUtility, nRoSUtility, nBottleUtility)
  nUtility = Clamp(nUtility, 0, 100)

  if nRoSUtility == 0 and nManaPotUtility == 0 and nBottleUtility == 0 then
    nUtility = 0
  end

  behaviorLib.nManaPotUtility = nManaPotUtility
  behaviorLib.nRoSUtility = nRoSUtility
  behaviorLib.nBottleUtility = nBottleUtility

  return nUtility
end

function behaviorLib.UseManaRegenExecute(botBrain)
  local unitSelf = core.unitSelf
  local vecSelfPos = unitSelf:GetPosition()
  local tInventory = unitSelf:GetInventory()

  local tRoSs = core.InventoryContains(tInventory, "Item_Replenish")
  local tManaPots = core.InventoryContains(tInventory, "Item_ManaPotion")
  local tBottles = core.InventoryContains(tInventory, "Item_Bottle")

  if behaviorLib.nRoSUtility > behaviorLib.nManaPotUtility and behaviorLib.nRoSUtility > behaviorLib.nBottleUtility then
    if #tRoSs > 0 and tRoSs[1]:CanActivate() then
      core.OrderItemClamp(botBrain, unitSelf, tRoSs[1])
      return
    end
  elseif behaviorLib.nManaPotUtility > behaviorLib.nRoSUtility and behaviorLib.nManaPotUtility > behaviorLib.nBottleUtility then
    if not unitSelf:HasState(idefManaPotion.stateName) and #tManaPots > 0 then
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
        core.OrderItemEntityClamp(botBrain, unitSelf, tManaPots[1], unitSelf)
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

behaviorLib.UseManaRegenBehavior = {}
behaviorLib.UseManaRegenBehavior["Utility"] = behaviorLib.UseManaRegenUtility
behaviorLib.UseManaRegenBehavior["Execute"] = behaviorLib.UseManaRegenExecute
behaviorLib.UseManaRegenBehavior["Name"] = "UseManaRegen"
tinsert(behaviorLib.tBehaviors, behaviorLib.UseManaRegenBehavior)
