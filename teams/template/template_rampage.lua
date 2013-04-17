local _G = getfenv(0)
local herobot = _G.object

herobot.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'

--function herobot:onpickframe()
--end

--function herobot:onthink(tGameVariables)
--end

--function herobot:oncombatevent(EventData)
--end

-- or:
herobot.UseOriginal()
