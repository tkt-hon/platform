local _G = getfenv(0)
local teambot = _G.object

function teambot.UseOriginal()
  runfile 'bots/teambot/teambotbrain.lua'
end
