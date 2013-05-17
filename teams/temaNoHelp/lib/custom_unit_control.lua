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

local function SearchPBMinions(botBrain)
  local tAllyCreepsNearby = core.AssessLocalUnits(botBrain).AllyCreeps
  local unitSelf = core.unitSelf
  local sPlayer = unitSelf:GetOwnerPlayer()
  for _, creep in pairs(tAllyCreepsNearby) do
    if creep and creep:IsValid() and creep:GetOwnerPlayer() == sPlayer and (creep:GetTypeName() == "Pet_NecroRanged" or creep:GetTypeName() == "Pet_NecroMelee") then
      core.OrderFollow(botBrain, creep, unitSelf)
    end
  end
end

local oncombateventOld = herobot.oncombatevent
local function oncombateventOverride(self, EventData)
  oncombateventOld(self, EventData)
  if EventData.Type == "Item" then
    if EventData.InflictorName == "Item_Bottle" then
      local bottle = core.itemBottle
      if bottle:GetActiveModifierKey() == "bottle_3" then
        SearchIllues(self)
      end
    elseif EventData.InflictorName == "Item_Summon" then
      SearchPBMinions(self)
    end
  end
end
herobot.oncombatevent = oncombateventOverride
