local _G = getfenv(0)
local defiler = _G.object

defiler.heroName = "Hero_Defiler"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = defiler.core, defiler.behaviorLib
