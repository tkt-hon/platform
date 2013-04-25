local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/core_teambot.lua'
runfile 'bots/utils/rune_controlling/team.lua'

Utils_RuneControlling_Team.Initialize(teambot)

teambot.bGroupAndPush = false

local core = teambot.core

teambot.myName = 'Default Team'

function teambot:GetMemoryUnit(unit)
  return unit and self.tMemoryUnits[unit:GetUniqueID()]
end

function teambot.FindBestLaneSoloOverride(tAvailableHeroes)
  if core.NumberElements(tAvailableHeroes) == 0 then
    return nil, nil
  end

  local unitBestUnit = nil
  for _, unit in pairs(tAvailableHeroes) do
    local memUnit = teambot:GetMemoryUnit(unit)
    if memUnit then
      if memUnit.isMid and memUnit.isGanker then
        return unit
      elseif memUnit.isMid and memUnit.isCarry then
        unitBestUnit = unit
      end
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

local function tfind(table, value)
  for _, v in ipairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

local tGankers = {
  "Hero_Rampage"
}
local tCarries = {
  "Hero_Krixi"
}
local tMidHeros = {
  "Hero_Rampage",
  "Hero_Krixi"
}
local tSuiciders = {
  "Hero_DiseasedRider"
}

function teambot:CreateMemoryUnitOverride(unit)
  local original = self:CreateMemoryUnitOld(unit)
  if original then
    local unitType = unit:GetTypeName()
    if tfind(tGankers, unitType) then
      original.isGanker = true
    end
    if tfind(tCarries, unitType) then
      original.isCarry = true
    end
    if tfind(tMidHeros, unitType) then
      original.isMid = true
    end
    if tfind(tSuiciders, unitType) then
      original.isSuicide = true
    end
  end
  return original
end
teambot.CreateMemoryUnitOld = teambot.CreateMemoryUnit
teambot.CreateMemoryUnit = teambot.CreateMemoryUnitOverride
