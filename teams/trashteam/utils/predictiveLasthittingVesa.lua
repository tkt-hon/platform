local _G = getfenv(0)
local lastHitter = _G.object

local core, behaviorLib = lastHitter.core, lastHitter.behaviorLib

local BotEcho = core.BotEcho


DmgInfo = {m = 0.0, c = 0.0, hpList = {}, timeList = {}, lastUpdateTime = 0}

function DmgInfo:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function DmgInfo:update(hp)
	local timeNow = HoN.GetMatchTime()
	
	if self.hpList and self.hpList[#self.hpList] - hp > 0 then
		table.insert(self.hpList, hp)
		table.insert(self.timeList, timeNow)
	end
end

function DmgInfo:LeastSquaresFit()
  if #self.timeList > 1 then
  	local xsum,ysum,xxsum,yysum,xysum = 0.0,0.0,0.0,0.0,0.0
  	local m,c,d
  	local n = #self.timeList
  
  	for i = 1,n do
  		local x,y = self.timeList[i],self.hpList[i]
  		xsum = xsum + x
  		ysum = ysum + y
  		xxsum = xxsum + x*x
  		yysum = yysum + y*y
  		xysum = xysum + x*y
  	end
  
  	d = n*xxsum - xsum*xsum
  	m = (n*xysum - xsum*ysum)/d
  	c = (xxsum*ysum - xysum*xsum)/d
  
  	self.m = m
    self.c = c
  end
end


function initTracking(botBrain)
	botBrain.trackedCreeps = botBrain.trackedCreeps or {}
	botBrain.focusCreeps = botBrain.focusCreeps or {}
end


function updateCreepHistory(botBrain,unit)
	updateAllCreepHistory()

	if botBrain.trackedCreeps[unit] then
		botBrain.trackedCreeps[unit]:update(unit:GetHealth())
	else
		local hp = {unit:GetHealth()}
		local time = {HoN.GetMatchTime()}
		botBrain.trackedCreeps[unit] = DmgInfo:new{hpList = hp, timeList = time}
	end
	
end


function updateCreepHistory(botBrain)
	updateAllCreepHistory()

	local unitsLocal = HoN.GetUnitsInRadius(lastHitter:GetPosition(), 1000, ALIVE + UNIT)
	for _,unit in pairs(unitsLocal) do
		if botBrain.trackedCreeps[unit] then
			botBrain.trackedCreeps[unit]:update(unit:GetHealth())
		else
			local hp = {unit:GetHealth()}
			local time = {HoN.GetMatchTime()}
			botBrain.trackedCreeps[unit] = DmgInfo:new{hpList = hp, timeList = time}
		end
	end
end


function updateAllCreepHistory(botBrain)
	for unit, v in pairs(botBrain.trackedCreeps) do
		local dmgInfo = botBrain.trackedCreeps[unit]
    if unit:GetHealth() == 0 then
			botBrain.trackedCreeps[unit] = nil
		else
      dmgInfo:LeastSquaresFit()
    end

    if dmgInfo.m ~= 0.0 and dmgInfo.c ~= 0.0 then
      BotEcho(string.format("		- %s dead in: %g", tostring(unit), -dmgInfo.c/dmgInfo.m-HoN.GetMatchTime()))
      local lifeExpectancy = -dmgInfo.c/dmgInfo.m-HoN.GetMatchTime()
      if lifeExpectancy < 3000 then
        botBrain.focusCreeps[unit] = lifeExpectancy
      end
    end
	end
end
