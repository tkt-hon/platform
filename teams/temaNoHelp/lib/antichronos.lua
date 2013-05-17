local _G = getfenv(0)
local teambot = _G.object

local core = teambot.core

teambot.antichronos = teambot.antichronos or {}
local antichronos = teambot.antichronos

local activeUltimates = {}
local ultiRanges = {500, 550, 600}

local function LocateChronosUltimate()
  local tUnits = HoN.GetUnitsInRadius(Vector3.Create(), 99999, core.UNIT_MASK_ALIVE + core.UNIT_MASK_GADGET)
  local ulties = {}
  for nUID, unit in pairs(tUnits) do
    if unit:GetTypeName() == "Gadget_Chronos_Ability4_Reveal" then
      ulties[nUID] = unit
    end
  end
  return ulties
end

function antichronos.UltiLocator()
  activeUltimates = LocateChronosUltimate()
end

function antichronos.GetBetterPosition(vecUnit, vecWanted)
  for _, ulti in pairs(activeUltimates) do
    local range = ultiRanges[ulti:GetLevel()]
    local vecUlti = ulti:GetPosition()
    if Vector3.Distance2DSq(vecWanted, vecUnit) <= range * range then
      return vecWanted + Vector3.Normalize(vecUnit - vecUnit) * (range + 50)
    end
  end
  return vecWanted
end

function antichronos.IsDangerZone(spot)
  for _, ulti in pairs(activeUltimates) do
    local range = ultiRanges[ulti:GetLevel()]
    if Vector3.Distance2DSq(spot, ulti:GetPosition()) <= range * range then
      return true
    end
  end
  return false
end

local onthinkOld = teambot.onthink
local function onthinkOverride(self, tGameVariables)
  onthinkOld(self, tGameVariables)

  antichronos.UltiLocator()
end
teambot.onthink = onthinkOverride
