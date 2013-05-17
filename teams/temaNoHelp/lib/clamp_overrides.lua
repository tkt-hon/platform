local _G = getfenv(0)
local herobot = _G.object

local core = herobot.core

core.nextOrderTimes = {}

function core.NextOrderTime(unit, value)
  local nUID = unit:GetUniqueID()
  if value then
    core.nextOrderTimes[nUID] = value
  else
    return core.nextOrderTimes[nUID] or 0
  end
end

function core.OrderAttackClamp(botBrain, unit, unitTarget, bQueueCommand)
  if herobot.bRunCommands == false or herobot.bAttackCommands == false then
    return false
  end

  if bQueueCommand == nil then
    bQueueCommand = false
  end

  local curTimeMS = HoN.GetGameTime()
  --stagger updates so we don't have permajitter
  if curTimeMS < core.NextOrderTime(unit) then
    return true
  end

  local queue = "None"
  if bQueueCommand then
    queue = "Back"
  end

  botBrain:OrderEntity(unit.object or unit, "Attack", unitTarget.object or unitTarget, queue)

  core.NextOrderTime(unit, curTimeMS + core.timeBetweenOrders)
  return true
end

function core.OrderMoveToUnitClamp(botBrain, unit, unitTarget, bInterruptAttacks, bQueueCommand)
  if herobot.bRunCommands == false or herobot.bMoveCommands == false then
    return false
  end

  --stagger updates so we don't have permajitter
  local curTimeMS = HoN.GetGameTime()
  if curTimeMS < core.NextOrderTime(unit) then
    return true
  end

  core.OrderMoveToUnit(botBrain, unit, unitTarget, bInterruptAttacks, bQueueCommand)

  core.NextOrderTime(unit, curTimeMS + core.timeBetweenOrders)
  return true
end

function core.OrderHoldClamp(botBrain, unit, bInterruptAttacks, bQueueCommand)
  if herobot.bRunCommands == false or herobot.bMoveCommands == false then
    return false
  end

  local curTimeMS = HoN.GetGameTime()
  --stagger updates so we don't have permajitter
  if curTimeMS < core.NextOrderTime(unit) then
    return true
  end

  core.OrderHold(botBrain, unit, bInterruptAttacks, bQueueCommand)

  core.NextOrderTime(unit, curTimeMS + core.timeBetweenOrders)
  return true
end

function core.OrderMoveToPosClamp(botBrain, unit, position, bInterruptAttacks, bQueueCommand)
  if herobot.bRunCommands == false or herobot.bMoveCommands == false then
    return false
  end

  local curTimeMS = HoN.GetGameTime()
  if curTimeMS < core.NextOrderTime(unit) then
    return true
  end

  if Vector3.Distance2DSq(unit:GetPosition(), position) > core.distSqTolerance then
    core.OrderMoveToPos(botBrain, unit, position, bInterruptAttacks, bQueueCommand)
  end

  core.NextOrderTime(unit, curTimeMS + core.timeBetweenOrders)
  return true
end

function core.OrderMoveToPosAndHoldClamp(botBrain, unit, position, bInterruptAttacks, bQueueCommand)
  if herobot.bRunCommands == false or herobot.bMoveCommands == false then
    return false
  end

  local curTimeMS = HoN.GetGameTime()
  if curTimeMS < core.NextOrderTime(unit) then
    return true
  end

  core.OrderMoveToPosAndHold(botBrain, unit, position, bInterruptAttacks, bQueueCommand)

  core.NextOrderTime(unit, curTimeMS + core.timeBetweenOrders)
  return true
end

function core.OrderAttackPositionClamp(botBrain, unit, position, bInterruptAttacks, bQueueCommand)
  if herobot.bRunCommands == false or herobot.bMoveCommands == false then
    return false
  end

  local curTimeMS = HoN.GetGameTime()
  if curTimeMS < core.NextOrderTime(unit) then
    return true
  end

  core.OrderAttackPosition(botBrain, unit, position, bInterruptAttacks, bQueueCommand)

  core.NextOrderTime(unit, curTimeMS + core.timeBetweenOrders)
  return true
end

function core.OrderItemEntityClamp(botBrain, unit, item, entity, bInterruptAttacks, bQueueCommand)
  if herobot.bRunCommands == false or herobot.bOtherCommands == false then
    return false
  end

  if bQueueCommand == nil then
    bQueueCommand = false
  end

  if bInterruptAttacks == nil then
    bInterruptAttacks = true
  end

  if not bInterruptAttacks then
    local status = core.GetAttackSequenceProgress(unit)
    if status == "windup" then
      return true
    end
  end

  local curTimeMS = HoN.GetGameTime()
  --stagger updates so we don't have permajitter
  if curTimeMS < core.NextOrderTime(unit) then
    return
  end

  local queue = "None"
  if bQueueCommand then
    queue = "Back"
  end

  botBrain:OrderItemEntity(item.object or item, entity.object or entity, queue)

  core.NextOrderTime(unit, curTimeMS + core.timeBetweenOrders)
  return true
end

function core.OrderItemClamp(botBrain, unit, item, bInterruptAttacks, bQueueCommand)
  if herobot.bRunCommands == false or herobot.bOtherCommands == false then
    return false
  end

  if bQueueCommand == nil then
    bQueueCommand = false
  end

  if bInterruptAttacks == nil then
    bInterruptAttacks = true
  end

  if not bInterruptAttacks then
    local status = core.GetAttackSequenceProgress(unit)
    if status == "windup" then
      return true
    end
  end

  local curTimeMS = HoN.GetGameTime()
  --stagger updates so we don't have permajitter
  if curTimeMS < core.NextOrderTime(unit) then
    return true
  end

  local queue = "None"
  if bQueueCommand then
    queue = "Back"
  end

  botBrain:OrderItem(item.object or item, queue)

  core.NextOrderTime(unit, curTimeMS + core.timeBetweenOrders)
  return true
end
