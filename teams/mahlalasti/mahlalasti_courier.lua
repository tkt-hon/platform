-- Courier for 1v1

local _G = getfenv(0)
local object = _G.object
local core = object.core
local BotEcho = object.core.BotEcho

courier = {}

local M = {}

M.UNIT = 0x0000001
M.BUILDING = 0x0000002
M.HERO = 0x0000004
M.POWERUP = 0x0000008
M.GADGET = 0x0000010
M.ALIVE = 0x0000020
M.CORPSE = 0x0000040

MASKS = M

function HasCourier(bot)
	return bot.courier ~= nil
end
-- sfdsfdsdfsdfsdf

-- https://github.com/samitheberber/honbotstack/blob/master/utils/courier_controlling/selector.lua
local function GetCourier(bot)
  local teamId = bot:GetTeam()
  local allUnits = HoN.GetUnitsInRadius(Vector3.Create(), 99999, MASKS.ALIVE + MASKS.UNIT)
  for key, unit in pairs(allUnits) do
    local typeName = unit:GetTypeName()
    if unit:GetTeam() == teamId and core.IsCourier(unit) then
      return unit
    end
  end
  return nil
end

courier.GetCourier = GetCourier
