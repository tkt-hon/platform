local _G = getfenv(0)
local teambot = _G.object

runfile 'bots/teams/drop-table-bots/droptable-teambot.lua'
local core = teambot.core

teambot.myName = 'Drop Table Bots'

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function teambot:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
teambot.onthinkOld = teambot.onthink
teambot.onthink = teambot.onthinkOverride

function teambot:BuildLanesOverride()
    local time = HoN.GetMatchTime()
    p(time)
    p(core.MinToMS(2))
    if not time or time > core.MinToMS(2) then
        return self:BuildLanesOld()
    end

    self:BuildLanesOld()
    p("---- Avoiding berberi -----")

    local paskaLane
    if core.myTeam == HoN.GetLegionTeam() then
        paskaLane = "tTopLane"
    else
        paskaLane = "tBottomLane"
    end

    for i, bot in pairs(self[paskaLane]) do
        self.tMiddleLane[i] = bot
        p("Moving " .. bot:GetTypeName() .. " to mid")
    end
    self[paskaLane] = {}
    self:PrintLanes(self.tTopLane, self.tMiddleLane, self.tBottomLane)		
end
teambot.BuildLanesOld = teambot.BuildLanes
teambot.BuildLanes = teambot.BuildLanesOverride
