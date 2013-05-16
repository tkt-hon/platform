local _G = getfenv(0)
local magmus = _G.object

runfile 'bots/magmus/magmus_main.lua'
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = magmus.core, magmus.behaviorLib
