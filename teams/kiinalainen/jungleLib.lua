----------------------------------------------
--                JungleLib                 --
----------------------------------------------
--     Created by Kairus101 for legoBot     --
----------------------------------------------

local _G = getfenv(0)
local object = _G.object

object.jungleLib = object.jungleLib or {}
local jungleLib, eventsLib, core, behaviorLib = object.jungleLib, object.eventsLib, object.core, object.behaviorLib

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog


local Hellbourne = HoN.GetHellbourneTeam()
local legion = HoN.GetLegionTeam()

jungleLib.jungleSpots={
--Leigon
{pos=Vector3.Create(7200,3600),  description="L closest to well"      ,difficulty=100 ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(6700,4000)	,corpseBlocking=false, side=legion },
{pos=Vector3.Create(7800,4500),  description="L easy camp"            ,difficulty=30  ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(7800,5200)	,corpseBlocking=false, side=legion },
{pos=Vector3.Create(9800,4200),  description="L mid-jungle hard camp" ,difficulty=100 ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(9800,3500)	,corpseBlocking=false, side=legion },
{pos=Vector3.Create(11100,3250), description="L pullable camp"        ,difficulty=55  ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(11100,2700)	,corpseBlocking=false, side=legion },
{pos=Vector3.Create(11300,4400), description="L camp above pull camp" ,difficulty=55  ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(11300,3800)	,corpseBlocking=false, side=legion },
{pos=Vector3.Create(4900,8100),  description="L ancients"             ,difficulty=250 ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(5500,7800)	,corpseBlocking=false, side=legion },
--Hellbourne
{pos=Vector3.Create(9400,11200), description="H closest to well"      ,difficulty=100 ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(8800,11300)	,corpseBlocking=false, side=Hellbourne },
{pos=Vector3.Create(7800,11600), description="H easy camp"            ,difficulty=30  ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(7400,12200)	,corpseBlocking=false, side=Hellbourne },
{pos=Vector3.Create(6500,10400), description="H below easy camp"      ,difficulty=55  ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(6700,11000)	,corpseBlocking=false, side=Hellbourne },
{pos=Vector3.Create(5100,12450), description="H pullable camp"        ,difficulty=55  ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(5100,13100)	,corpseBlocking=false, side=Hellbourne },
{pos=Vector3.Create(4000,11500), description="H far hard camp"        ,difficulty=100 ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(4400,11700)	,corpseBlocking=false, side=Hellbourne },
{pos=Vector3.Create(12300,5600), description="H ancients"             ,difficulty=250 ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(12300,6400)	,corpseBlocking=false, side=Hellbourne }
}
jungleLib.minutesPassed=-1
jungleLib.stacking=0

jungleLib.creepDifficulty={
	Neutral_Catman_leader=40,
	Neutral_Catman=20,
	Neutral_VagabondLeader=30,
	Neutral_Minotaur=15,
	Neutral_Ebula=3,
	Neutral_HunterWarrior=-5,
	Neutral_snotterlarge=-1,
	Neutral_snottling=-3,
	Neutral_SkeletonBoss=-5,
	Neutral_AntloreHealer=5,
	Neutral_WolfCommander=15,
}
local checkFrequency=250
jungleLib.lastCheck=0
function jungleLib.assess(botBrain)
	--NEUTRAL SPAWNING
	local time=HoN.GetMatchTime()
	if (time<=jungleLib.lastCheck+checkFrequency)then return end --framskip
	jungleLib.lastCheck=time
	
	local mins=-1
	if time then
		mins,secs=jungleLib.getTime()
		if (mins==0 and secs==30) or (mins~=jungleLib.minutesPassed and mins~=0) then --SPAWNING
			for i=1,#jungleLib.jungleSpots do
				if (not jungleLib.jungleSpots[i].corpseBlocking) then --it won't spawn with corpse in way.
					jungleLib.jungleSpots[i].stacks=1 --assume something spawned. If not, it will be removed later if not.
				end
				jungleLib.jungleSpots[i].corpseBlocking=false
			end
			if (jungleLib.stacking~=0) then --add stack if stacking.
				jungleLib.jungleSpots[jungleLib.stacking].stacks=jungleLib.jungleSpots[jungleLib.stacking].stacks+1
			end
			jungleLib.stacking=0
		end
	end
	jungleLib.minutesPassed=mins

	--CHECK NEUTRAL SPAWN CAMPS
	local debug=false
	
	for i=1,#jungleLib.jungleSpots do
		if (debug) then
			if (jungleLib.jungleSpots[i].stacks==0) then
				core.DrawXPosition(jungleLib.jungleSpots[i].pos, 'green')
			else
				core.DrawXPosition(jungleLib.jungleSpots[i].pos, 'red')
			end
		end
	
		if (HoN.CanSeePosition(jungleLib.jungleSpots[i].pos))then
			jungleLib.jungleSpots[i].creepDifficulty=0
			local nUnitsNearCamp=0
			local uUnits=HoN.GetUnitsInRadius(jungleLib.jungleSpots[i].pos, 600, core.UNIT_MASK_ALIVE + core.UNIT_MASK_UNIT)
			for key, unit in pairs(uUnits) do
				if unit:GetTeam() ~= core.myTeam and unit:GetTeam() ~= core.enemyTeam then
					nUnitsNearCamp=nUnitsNearCamp+1
					core.DrawXPosition(unit:GetPosition(), 'red')
					creepDifficulty=jungleLib.creepDifficulty[unit:GetTypeName()] --add difficult units
					if addedDifficulty then jungleLib.jungleSpots[i].creepDifficulty=jungleLib.jungleSpots[i].creepDifficulty+creepDifficulty end
				end
			end
			--local localNeutrals = core.NumberElements(core.localUnits["neutrals"]) --to not confuse with minions
			if jungleLib.jungleSpots[i].stacks~=0 and nUnitsNearCamp==0 then --we can see the camp, nothing is there.
				if (debug) then BotEcho("Camp "..jungleLib.jungleSpots[i].description.." is empty. Are they all dead? "..jungleLib.jungleSpots[i].stacks) end
				if secs>37 then jungleLib.jungleSpots[i].corpseBlocking=true end --perhaps add to this. This is a corpse check.
				jungleLib.jungleSpots[i].stacks=0
			end
			if (nUnitsNearCamp~=0 and jungleLib.jungleSpots[i].stacks==0 ) then --this shouldn't be true. New units should be made on the minute.
				if (debug) then BotEcho("Camp "..jungleLib.jungleSpots[i].description.." isn't empty, but I thought it was... Maybe I pulled it too far?") end
				jungleLib.jungleSpots[i].stacks=1
			end
		end
	end
end

function jungleLib.getNearestCampPos(pos,minimumDifficulty,maximumDifficulty, side)
	minimumDifficulty=minimumDifficulty or 0
	maximumDifficulty=maximumDifficulty or 999
	
	local nClosestCamp = -1
	local nClosestSq = 9999*9999
	for i=1,#jungleLib.jungleSpots do
		if side == nil or jungleLib.jungleSpots[i].side == side then
			local dist=Vector3.Distance2DSq(pos, jungleLib.jungleSpots[i].pos)
			local difficulty=jungleLib.jungleSpots[i].difficulty+jungleLib.jungleSpots[i].creepDifficulty
			if dist<nClosestSq and jungleLib.jungleSpots[i].stacks~=0 and difficulty>minimumDifficulty and difficulty<maximumDifficulty then
				nClosestSq=dist
				nClosestCamp=i
			end
		end
	end
	if (nClosestCamp~=-1 and jungleLib.jungleSpots[nClosestCamp].stacks>0) then return jungleLib.jungleSpots[nClosestCamp].pos, nClosestCamp end
	return nil
end

function jungleLib.getTime()
local time=HoN.GetMatchTime()
	if time then
		mins=floor(time/60000)
		secs=floor((time-60000*mins)/1000)
	end
	return mins or -1,secs or -1
end

function jungleLib.stack(botBrain)
	vSelfPos=core.unitSelf:GetPosition()
	campPos=jungleLib.getNearestCampPos(vSelfPos)
	local dist=Vector3.Distance2DSq(campPos, vSelfPos)
	--UNFINISHED
end

---------------------------------------
--          Jungle Behavior          --
---------------------------------------
--
-- Utility: 21
-- This is effectively an "idle" behavior
--
-- Execute:
-- Move to unoccupied camps
-- Attack strongest Neutral until they are all dead
--

-------- Global Constants & Variables --------
behaviorLib.nCreepAggroUtility = 0
behaviorLib.nRecentDamageMul = 0.20

jungleLib.nStacking = 0 -- 0 = not, 1 = waiting/attacking 2, = running away
jungleLib.nStackingCamp = 0

jungleLib.currentMaxDifficulty = 70

-------- Behavior Functions --------
function jungleUtility(botBrain)
        if HoN.GetRemainingPreMatchTime() and HoN.GetRemainingPreMatchTime()>40000 then
                return 0
        end
        -- Wait until level 9 to start grouping/pushing/defending
        behaviorLib.nTeamGroupUtilityMul = 0.13 + core.unitSelf:GetLevel() * 0.01
        behaviorLib.pushingCap = 13 + core.unitSelf:GetLevel()
        behaviorLib.nTeamDefendUtilityVal = 13 + core.unitSelf:GetLevel()
        return 21
end

function jungleExecute(botBrain)
        local unitSelf = core.unitSelf
        local debugMode=false

        local vecMyPos = unitSelf:GetPosition()
        local vecTargetPos, nCamp = jungleLib.getNearestCampPos(vecMyPos, 0, jungleLib.currentMaxDifficulty)
        if not vecTargetPos then
                if core.myTeam == HoN.GetHellbourneTeam() then
                        return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, jungleLib.jungleSpots[8].outsidePos)
                else
                        return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, jungleLib.jungleSpots[2].outsidePos)
                end
        end

        if debugMode then core.DrawDebugArrow(vecMyPos, vecTargetPos, 'green') end

        local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, vecTargetPos)
        if nTargetDistanceSq > (600 * 600) or jungleLib.nStacking ~= 0 then
                -- Move to the next camp
                local nMins, nSecs = jungleLib.getTime()
                if jungleLib.nStacking ~= 0 or ((nSecs > 40 or nMins == 0) and nTargetDistanceSq < (800 * 800) and nTargetDistanceSq > (400 * 400)) then
                        -- Stack the camp if possible
                        if nSecs < 53 and (nSecs > 40 or nMins == 0) then
                                -- Wait outside the camp
                                jungleLib.nStacking = 1
                                jungleLib.nStackingCamp = nCamp

                                return core.OrderMoveToPosAndHoldClamp(botBrain, core.unitSelf, jungleLib.jungleSpots[nCamp].outsidePos, false)
                        elseif jungleLib.nStacking == 1 and unitSelf:IsAttackReady() then
                                -- Attack the units in the camp
                                if nSecs >= 57 then 
                                        -- Missed our chance to stack
                                        jungleLib.nStacking = 0 
                                end

                                return core.OrderAttackPosition(botBrain, unitSelf, vecTargetPos,false,false)
                        elseif jungleLib.nStacking ~= 0 and nTargetDistanceSq < (1500 * 1500) and nSecs > 50 then
                                -- Move away from the units in the camp
                                jungleLib.nStacking = 2
                                local vecAwayPos = jungleLib.jungleSpots[jungleLib.nStackingCamp].pos + (jungleLib.jungleSpots[jungleLib.nStackingCamp].outsidePos - jungleLib.jungleSpots[jungleLib.nStackingCamp].pos) * 5
                                if debugMode then
                                        core.DrawXPosition(jungleLib.jungleSpots[jungleLib.nStackingCamp].pos, 'red')
                                        core.DrawXPosition(jungleLib.jungleSpots[jungleLib.nStackingCamp].outsidePos, 'red')
                                        core.DrawDebugArrow(jungleLib.jungleSpots[jungleLib.nStackingCamp].pos,vecAwayPos, 'green')
                                end

                                return core.OrderMoveToPosClamp(botBrain, core.unitSelf, vecAwayPos, false)
                        else
                                -- Finished stacking
                                jungleLib.nStacking = 0
                                return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecTargetPos)
                        end
                else
                        -- Otherwise just move to camp
                        return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecTargetPos)
                end
        else 
                -- Kill neutrals in the camp
                local tUnits = HoN.GetUnitsInRadius(vecMyPos, 800, core.UNIT_MASK_ALIVE + core.UNIT_MASK_UNIT)
                if tUnits then
                        -- Find the strongest unit in the camp
                        local nHighestHealth = 0
                        local unitStrongest = nil
                        for _, unitTarget in pairs(tUnits) do
                                if unitTarget:GetHealth() > nHighestHealth and unitTarget:IsAlive() then
                                        unitStrongest = unitTarget
                                        nHighestHealth = unitTarget:GetHealth()
                                end
                        end

                        -- Attack the strongest unit
                        if unitStrongest and unitStrongest:GetPosition() then
                                local nStrongestTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, unitStrongest:GetPosition())
                                return core.OrderAttackClamp(botBrain, unitSelf, unitStrongest, false)
                        else
                                return core.OrderAttackPosition(botBrain, unitSelf, vecTargetPos, false, false)
                        end
                end
        end

        return false
end
behaviorLib.jungleBehavior = {}
behaviorLib.jungleBehavior["Utility"] = jungleUtility
behaviorLib.jungleBehavior["Execute"] = jungleExecute
behaviorLib.jungleBehavior["Name"] = "jungle"
tinsert(behaviorLib.tBehaviors, behaviorLib.jungleBehavior)
