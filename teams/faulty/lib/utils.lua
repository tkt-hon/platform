-- Common utils shared between heroes
local _G = getfenv(0)
local herobot = _G.object

local core = herobot.core

--------------------------------------------------------------------------------
-- Returns the number of creeps in given radius around center point
--
-- @param botBrain
-- @param circle center
-- @param radius of the circle
--
-- @return number of enemy creeps in radius
function NearbyEnemyCreepCountUtility(botBrain, center, radius)
	local count = 0
	local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
	for _, unit in pairs(unitsLocal.EnemyCreeps) do
		count = count + 1
	end
	return count
end


--------------------------------------------------------------------------------
-- Returns the number of enemy heroes in given radius around center point
--
-- @param botBrain
-- @param circle center
-- @param radius of the circle
--
-- @return number of enemy heroes in radius
function NearbyEnemyHeroCountUtility(botBrain, center, radius)
	local count = 0
	local unitsLocal = core.AssessLocalUnits(botBrain, center, radius)
	for _, unit in pairs(unitsLocal.EnemyHeroes) do
		count = count + 1
	end
	return count
end


--------------------------------------------------------------------------------
-- Hero state value, if hero in full health and mana, return value close to zero
-- if close to death, value close to mana val + health val
--
-- @param heroUnit
-- @param mana value
-- @param health value
--
-- @return hero val
function HeroStateValueUtility(heroUnit, nNoManaVal, nNoHealthVal)
	local nHealthPercent = heroUnit:GetHealthPercent()
	local nManaPercent   = heroUnit:GetManaPercent()

	local nRet = 0
	if nHealthPercent ~= nil then
		nRet = nRet + (1 - nHealthPercent) * nNoHealthVal
	end
	if nManaPercent ~= nil then
		nRet = nRet + (1 - nManaPercent) * nNoManaVal
	end
	return nRet
end
