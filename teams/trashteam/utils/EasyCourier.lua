local _G = getfenv(0)
local easyCourier = _G.object

local core, behaviorLib = easyCourier.core, easyCourier.behaviorLib

local BotEcho = core.BotEcho

UNIT = 0x0000001
BUILDING = 0x0000002
HERO = 0x0000004
POWERUP = 0x0000008
GADGET = 0x0000010
ALIVE = 0x0000020
CORPSE = 0x0000040

easyCourier.courier = nil

local heroWasClose = false
local delivering = false      -- on our way to deliver items to hero
local waitingForHero = false  -- waiting for hero to come to safe spot to get items
local returning = true       -- returning from successful delivery
local idle = false             -- waiting for hero to buy items
local deliverLocationLegion = Vector3.Create(6479,6533,0) -- these are fine?
local deliverLocationHell = Vector3.Create(8950, 8197,0) -- these are fine?
local deliverLoc = nil

local function currentState()
  if delivering then
    return "delivering"
  elseif idle then
    return "idling"
  elseif returning then
    return "returning"
  elseif waitingForHero then
    return "waitingForHero"
  end
  return "lol"
end

local function GetCourier(teamId) -- DONE(berb)
  local allUnits = HoN.GetUnitsInRadius(Vector3.Create(), 99999, ALIVE + UNIT)
  for key, unit in pairs(allUnits) do
    local typeName = unit:GetTypeName()
    if unit:GetTeam() == teamId and
       (typeName == "Pet_GroundFamiliar" or
        typeName == "Pet_FlyngCourier") and
        unit:IsValid() then
      return unit
    end
  end
  return nil
end

local function hasItems() -- DONE(?)
  local courInv = easyCourier.courier:GetInventory()
  for slot = 1,6,1 do
    local current = courInv[slot]
    if current then
      return true
    end
  end
  return false
end

local function hasDeliverableItems(botBrain) -- DONE(?)
  local unitSelf = botBrain.core.unitSelf
  local stash = unitSelf:GetInventory(true)
  for slot = 7,12,1 do
    local current = stash[slot]
    if current then
      return true
    end
  end
  return false
end

local function GetItemsFromStash(botBrain) -- DONE(?)
  local courInv = easyCourier.courier:GetInventory()
  local unitSelf = botBrain.core.unitSelf
  local stash = unitSelf:GetInventory(true)
  for slot = 7,12,1 do
    local current = stash[slot]
    if current then
      easyCourier.courier:SwapItems(slot, slot-6)
    end
  end
end

local function getDeliverLoc(botBrain) -- DONE
  if botBrain:GetTeam() == 1 then
    return deliverLocationLegion
  end
  return deliverLocationHell
end

local function closeToDeliveryLoc(botBrain) -- DONE(?)
  if not deliverLoc then
    deliverLoc = getDeliverLoc(botBrain)
  end
  local cLoc = easyCourier.courier:GetPosition()
  local length = Vector3.Distance2D(cLoc, deliverLoc)
  if length < 400 then
    return true
  end
  return false
end

local function drawAround(botBrain)
  local courierPos = easyCourier.courier:GetPosition()
  local asd = HoN.GetUnitsInRadius(courierPos, 900, 0x0000004 + 0x0000020)
  for uid, unit in pairs(asd) do
    local unitPos = unit:GetPosition()
    HoN.DrawDebugLine(courierPos, unitPos, true, "Red")
  end
end

local function heroIsClose(botBrain) -- DONE(?)
  local courierPos = easyCourier.courier:GetPosition()
  local asd = HoN.GetUnitsInRadius(courierPos, 800,  0x0000004 + 0x0000020)
  for uid, unit in pairs(asd) do
    local unitPos = unit:GetPosition()
    if unit:GetTeam() == botBrain:GetTeam() then
      return true
    end
  end
  return false
end

local function CourierTick(botBrain)
  if not easyCourier.courier or not easyCourier.courier:IsValid() then
    easyCourier.courier = GetCourier(botBrain:GetTeam())
    if not easyCourier.courier then
      return false
    end
  end
  drawAround(botBrain)
  local curBeha = easyCourier.courier:GetBehavior()
  if curBeha then
    local jobType = curBeha:GetType()
    botBrain.core.BotEcho("type of action on courier: " .. tostring(jobType))
    if idle then -- DONE(?) -- buggy if buying is slow and all items end up on silly pos
      -- check for job, hero has items to be delivered.
      if hasDeliverableItems(botBrain) or hasItems() then
        idle = false
        delivering = true
        GetItemsFromStash(botBrain)
        return true
      end
    elseif delivering then -- DONE(?)
      if closeToDeliveryLoc(botBrain) or heroIsClose(botBrain) then
        delivering = false
        waitingForHero = true
        easyCourier.waitingHero = true
        -- lol fixed? ordering Move to cur pos
        botBrain:OrderPosition(easyCourier.courier, "Move", easyCourier.courier:GetPosition())
        return true
      else
        if not (jobType == "Move") then
          botBrain:OrderPosition(easyCourier.courier, "Move", getDeliverLoc(botBrain))
          return true
        end
      end
    elseif waitingForHero then -- DONE(?)
      if heroWasClose and not hasItems()  then
        heroWasClose = false
        waitingForHero = false
        returning = true
        easyCourier.waitingHero = false
      elseif not heroWasClose then
        if heroIsClose(botBrain) then
        botBrain.core.BotEcho("Is hero close:" ..  tostring(heroIsClose(botBrain)))
          local deliver = easyCourier.courier:GetAbility(2)
          botBrain:OrderAbility(deliver)
          heroWasClose = true
          return true
        end
      elseif hasItems() then
        heroWasClose = false
        returning = false
        delivering = true
        waitingForHero = false
      end
    elseif returning then -- DONE(?)
      if easyCourier.courier:CanAccessStash() then
        returning = false
        idle = true
        return true
      elseif not hasItems() then
        botBrain:OrderAbility(easyCourier.courier:GetAbility(3))
      else
        delivering = true
        idle = false
        returning = false
      end
    end
    return true
  else
    return false
  end
end


easyCourier.waitingHero = false

function CourierUtils()
  local func = {}
  func.tick = CourierTick
  func.waitingHero = false
  func.GetState = currentState
  return func
end

