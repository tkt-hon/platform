local _G = getfenv(0)
local herobot = _G.object

local core, eventsLib = herobot.core, herobot.eventsLib

local function SearchIllues(botBrain)
  local tAllyHeroesNearby = core.AssessLocalUnits(botBrain).AllyHeroes
  local unitSelf = core.unitSelf
  local sPlayer = unitSelf:GetOwnerPlayer()
  local nMyUID = unitSelf:GetUniqueID()
  local sType = unitSelf:GetTypeName()
  for nUID, hero in pairs(tAllyHeroesNearby) do
    if hero and hero:IsValid() and hero:GetOwnerPlayer() == sPlayer and nMyUID ~= nUID and hero:GetTypeName() == sType then
      core.OrderFollow(botBrain, hero, unitSelf)
    end
  end
end

local oncombateventOld = herobot.oncombatevent
local function oncombateventOverride(self, EventData)
  oncombateventOld(self, EventData)
  if EventData.Type == "Item" and EventData.InflictorName == "Item_Bottle" then
    local bottle = core.itemBottle
    if bottle:GetActiveModifierKey() == "bottle_3" then
      SearchIllues(self)
    end
  end
end
herobot.oncombatevent = oncombateventOverride
