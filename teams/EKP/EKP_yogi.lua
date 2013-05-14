local _G = getfenv(0)
local yogi = _G.object

yogi.heroName = "Hero_Yogi"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = yogi.core, yogi.behaviorLib
