local _G = getfenv(0)
local teambot = _G.object

local core = teambot.core

teambot.antimagmus = teambot.antimagmus or {}
local antimagmus = teambot.antimagmus

local function EnemyTeamHasMagmus()
  local magmus = nil
  for _,v in pairs(teambot.tEnemyHeroes) do
    if v:GetTypeName() == "Hero_Magmar" then
      magmus = v
    end
  end
  return magmus and true or false
end

local function GetCounterSteamBathWardPosition()
  local tUnits = HoN.GetUnitsInRadius(Vector3.Create(), 99999, core.UNIT_MASK_ALIVE + core.UNIT_MASK_UNIT+ core.UNIT_MASK_HERO)
  for k, unit in pairs(tUnits) do
    if unit:GetTeam() ~= teambot.myTeam and unit:HasState("State_Magmar_Ability2_Damageeffects") then
      return unit:GetPosition()
    end
  end
  return nil
end

local function MagmusLocator()
  if antimagmus.bRunning == nil then
    antimagmus.bRunning = EnemyTeamHasMagmus()
    return
  elseif not antimagmus.bRunning then
    return
  end
  local wardPos = GetCounterSteamBathWardPosition()
  if wardPos then
    antimagmus.vecWardPosition = wardPos
    antimagmus.whenSpotted = HoN.GetMatchTime()
  end
end

function antimagmus.GetAntiMagmusWardSpot()
  if antimagmus.whenSpotted and antimagmus.whenSpotted > HoN.GetMatchTime() - 3000 then
    return antimagmus.vecWardPosition
  end
  return nil
end

local onthinkOld = teambot.onthink
local function onthinkOverride(self, tGameVariables)
  onthinkOld(self, tGameVariables)

  MagmusLocator()
end
teambot.onthink = onthinkOverride
