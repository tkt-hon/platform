local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/core_teambot.lua'
runfile 'bots/utils/rune_controlling/team.lua'

Utils_RuneControlling_Team.Initialize(teambot)

teambot.bGroupAndPush = false

local core = teambot.core

teambot.myName = 'Default Team'

local function IsGanker(unit)
  return unit:GetTypeName() == "Hero_Rampage"
end

local function IsMidCarry(unit)
  return unit:GetTypeName() == "Hero_Krixi"
end

function teambot.FindBestLaneSoloOverride(tAvailableHeroes)
  if core.NumberElements(tAvailableHeroes) == 0 then
    return nil, nil
  end

  local unitBestUnit = nil
  for _, unit in pairs(tAvailableHeroes) do
    if IsGanker(unit) then
      local memUnit = teambot.tMemoryUnits[unit:GetUniqueID()]
      memUnit.isGanker = true
      return unit
    elseif IsMidCarry(unit) then
      unitBestUnit = unit
    end
  end

  return unitBestUnit or teambot.FindBestLaneSoloOld(tAvailableHeroes)
end
teambot.FindBestLaneSoloOld = teambot.FindBestLaneSolo
teambot.FindBestLaneSolo = teambot.FindBestLaneSoloOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function teambot:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  self.data.rune:Locate()
end
teambot.onthinkOld = teambot.onthink
teambot.onthink = teambot.onthinkOverride
