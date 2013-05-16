-- original wildsoul bot by Aleks_Dark
--####################################################################
--####################################################################
--#                                                                 ##
--#                       Bot Initiation                            ##
--#                                                                 ##
--####################################################################
--####################################################################

local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

runfile "bots/teams/kiinalainen/core_kiinalainen_herobot.lua"
runfile "bots/teams/kiinalainen/advancedShopping.lua"
runfile "bots/teams/kiinalainen/jungleLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
    = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
    = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

jungleLib = object.jungleLib or {}

BotEcho(object:GetName()..' loading Yogi_main...')

local itemHandler = object.itemHandler
--local shopping = object.shoppingHandler

BotEcho(object:GetName()..' DEBUG...')

--object.bReportBehavior = true -- DEBUG
--object.bDebugUtility = true -- DEBUG


--####################################################################
--####################################################################
--#                                                                 ##
--#                  bot constant definitions                       ##
--#                                                                 ##
--####################################################################
--####################################################################

-- hero_<hero>  to reference the internal hon name of a hero, Hero_Yogi ==wildsoul

behaviorLib.StartingItems  = 	{"Item_IronBuckler", "Item_LoggersHatchet", "Item_SwordOfTheHigh", "Item_Damage10", "Item_Marchers", "Item_EnhancedMarchers", "Item_Lightning1", "Item_Lightning2", "Item_Sicarius", "Item_StrengthAgility", "Item_FrostfieldPlate", "Item_BehemothsHeart"}
behaviorLib.LaneItems  = 		{}
behaviorLib.MidItems  = 		{}
behaviorLib.LateItems  = 		{}

--   item buy order. internal names
--behaviorLib.StartingItems  = 	{"Item_IronBuckler", "Item_LoggersHatchet"}
--behaviorLib.LaneItems  = 		{"Item_SwordOfTheHigh", "Item_Damage10"}
--behaviorLib.MidItems  = 		{"Item_Marchers", "Item_EnhancedMarchers"}
--behaviorLib.LateItems  = 		{"Item_Lightning1", "Item_Lightning2", "Item_Sicarius", "Item_StrengthAgility", "Item_FrostfieldPlate", "Item_BehemothsHeart"}

-- skillbuild table, 0=q, 1=w, 2=e, 3=r, 4=attri
object.tSkills ={
	0, 2, 0, 2, 0,
	2, 0, 3, 2, 1,
	1, 1, 1, 3, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4,
}

-- bonus agression points if a skill/item is available for use


-- bonus agression points that are applied to the bot upon successfully using a skill/item


--thresholds of aggression the bot must reach to use these abilities

--####################################################################
--####################################################################
--#                                                                 ##
--#   bot function overrides                                        ##
--#                                                                 ##
--####################################################################
--####################################################################


------------------------------
--     skills               --
------------------------------
-- @param: none
-- @return: none
function object:SkillBuild()
    core.VerboseLog("skillbuild()")

-- takes care at load/reload, <name_#> to be replaced by some convinient name.
    local unitSelf = self.core.unitSelf
    if  skills.abilQ == nil then
        skills.abilQ = unitSelf:GetAbility(0)
        skills.abilW = unitSelf:GetAbility(1)
        skills.abilE = unitSelf:GetAbility(2)
        skills.abilR = unitSelf:GetAbility(3)
        skills.abilAttributeBoost = unitSelf:GetAbility(4)
    end
    if unitSelf:GetAbilityPointsAvailable() <= 0 then
        return
    end


    local nlev = unitSelf:GetLevel()
    local nlevpts = unitSelf:GetAbilityPointsAvailable()
    for i = nlev, nlev+nlevpts do
        unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
    end
end

BotEcho("Loading onthink")

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
    self:onthinkOld(tGameVariables)
    jungleLib.assess(object)
    if not self.core.unitSelf:IsAlive() then
    	return
    end

	Booboo=false
	for key, unit in pairs(core.tControllableUnits["AllUnits"]) do
		if unit:GetTypeName()=="Pet_Yogi_Ability1" then
			Booboo=unit
		end
	end

	if not Booboo then
		if skills.abilQ:CanActivate() then
			core.OrderAbility(object, skills.abilQ)
		end
	else
		--pullExecute(object)
	end

    -- custom code here
end
object.onthinkOld = object.onthink
object.onthink  = object.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)

end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent     = object.oncombateventOverride


----------------------------------------------------------------------
--- Other  scripts
----------------------------------------------------------------------
--3000 gold adds 5 to return utility, 0% mana adds 11.
function HealAtWellUtilityOverride(botBrain)
	return object.HealAtWellUtilityOld(botBrain)*1.75+(botBrain:GetGold()*8/3000)+ 11-(core.unitSelf:GetManaPercent()*11)
end
object.HealAtWellUtilityOld = behaviorLib.HealAtWellBehavior["Utility"]
behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellUtilityOverride

function HealAtWellExecuteOverride(botBrain)
	if (object.itemEnergizer and object.itemEnergizer:CanActivate())then --when heading to base, use energizer
		core.OrderItemClamp(botBrain, unitSelf, object.itemEnergizer)
	end
	if (core.itemGhostMarchers and core.itemGhostMarchers:CanActivate())then --when heading to base, use boots
		core.OrderItemClamp(botBrain, unitSelf, core.itemGhostMarchers)
	end
	if (core.itemGhostMarchers and core.itemGhostMarchers:CanActivate())then --when heading to base, use boots
		core.OrderItemClamp(botBrain, unitSelf, core.itemGhostMarchers)
	end
	if (skills.abilQ:CanActivate()) then
		core.OrderAbility(botBrain, skills.abilQ)
	end
	if (skills.abilW:CanActivate()) then
		core.OrderAbility(botBrain, skills.abilW)
	end
    Booboo=false
    for key, unit in pairs(core.tControllableUnits["AllUnits"]) do
        if unit:GetTypeName()=="Pet_Yogi_Ability1" then
            Booboo=unit
            local tEnemyHeroes = core.localUnits["EnemyHeroes"]

            for id, hero in pairs(tEnemyHeroes) do
                if Vector3.Distance2D(core.unitSelf:GetPosition(), hero:GetPosition()) < 800 then
                    core.OrderAttack(botBrain, Booboo, hero)
                    return object.HealAtWellExecuteOld(botBrain)
                end
            end
            core.OrderFollow(botBrain, Booboo, core.unitSelf)
        end
    end

	return object.HealAtWellExecuteOld(botBrain)
end
object.HealAtWellExecuteOld = behaviorLib.HealAtWellBehavior["Execute"]
behaviorLib.HealAtWellBehavior["Execute"] = HealAtWellExecuteOverride

function debugUtility(botBrain)
	local inventory = core.unitSelf:GetInventory(false)
    for i,v in ipairs(inventory) do
    	if v then
    		return 0
    		--return 100
		end
    end
    return 0
end

local DROPPED = false

function debugExecute(botBrain)
	Booboo=false
	for key, unit in pairs(core.tControllableUnits["AllUnits"]) do
		if unit:GetTypeName()=="Pet_Yogi_Ability1" then
			Booboo=unit
		end
	end

	if not Booboo or Vector3.Distance2D(core.unitSelf:GetPosition(), Booboo:GetPosition()) > 200 then
		return false
	end

   local inventory2 = Booboo:GetInventory(false)
   for i,v in ipairs(inventory2) do
   		if not DROPPED then 
    		BotEcho("Boo: " .. v:GetSlot() .. ": " .. v:GetTypeName())
    	end
    end

   local inventory = core.unitSelf:GetInventory(false)
    for i,v in ipairs(inventory) do
    	if v then
    		if not DROPPED then 
    			BotEcho("Hero: " .. v:GetSlot() .. ": " .. v:GetTypeName())
    			--core.OrderDropItem(botBrain, core.unitSelf, Booboo:GetPosition(), v)
				core.OrderGiveItem(botBrain, core.unitSelf, Booboo, v)
			end
			DROPPED = true
			return true
		end
    end
    return false
end

behaviorLib.debugBehavior = {}
behaviorLib.debugBehavior["Utility"] = debugUtility
behaviorLib.debugBehavior["Execute"] = debugExecute
behaviorLib.debugBehavior["Name"] = "debug"
tinsert(behaviorLib.tBehaviors, behaviorLib.debugBehavior)

local PULL_STATE = 1
local PULL_RETURNING = false
local PULL_LEG = {Vector3.Create(2248, 9342), Vector3.Create(4284, 8875), Vector3.Create(10061, 13088), Vector3.Create(9938, 13648)}
local PULL_HB = {Vector3.Create(14223, 6516), Vector3.Create(7955, 5136), Vector3.Create(5637, 2195), Vector3.Create(5606, 1600)}
local PULL_STARTED = false
-- cg_drawSelectedStats true
function pullExecute(botBrain)
    -- Not pulling
    if PULL_STATE == 0 then
        return false
    end

    local path = {}
    if core.myTeam == HoN.GetHellbourneTeam() then
        path = PULL_HB
    else
        path = PULL_LEG
    end

    local Booboo=false
    for key, unit in pairs(core.tControllableUnits["AllUnits"]) do
            if unit:GetTypeName()=="Pet_Yogi_Ability1" then
                    Booboo=unit
            end
    end

    if not Booboo then
        return false
    end

    local unitSelf = core.unitSelf
    --core.OrderMoveToPosAndHold(botBrain, unitSelf, path[1]+Vector3.Create(-200,-200), false)
    local vecSelfPos = Booboo:GetPosition()
    --print(Vector3.Distance2D(vecSelfPos, path[PULL_STATE]).." Durr:"..PULL_STATE.." Hurr:"..tostring(PULL_RETURNING).."\n")
    if Vector3.Distance2D(vecSelfPos, path[PULL_STATE]) < 50 then
    	BotEcho("At position "..PULL_STATE)
        if PULL_RETURNING then
            PULL_STATE = PULL_STATE-1 -- Returned the creeps
            if PULL_STATE == 0 then
                PULL_RETURNING = false
                PULL_STATE = 1
                PULL_STARTED = false -- repeat forever?
            end
        else
            PULL_STATE = PULL_STATE+1 
            if PULL_STATE == 5 then -- Caught some creeps
                PULL_RETURNING = true
                PULL_STATE = 3
                PULL_STARTED = false
            end
        end
    else
        if PULL_STARTED then
            return true
        end
    end

    PULL_STARTED = true
    if PULL_STATE == 1 and PULL_RETURNING == false then
    	core.OrderMoveToPosAndHold(botBrain, Booboo, path[1], false, true)
    	core.OrderMoveToPosAndHold(botBrain, Booboo, path[2], false, true)
    	return core.OrderMoveToPosAndHold(botBrain, Booboo, path[3], false, true)
    elseif PULL_STATE == 3 and PULL_RETURNING == true then
    	core.OrderMoveToPosAndHold(botBrain, Booboo, path[3], false, true)
    	core.OrderMoveToPosAndHold(botBrain, Booboo, path[2], false, true)
    	return core.OrderMoveToPosAndHold(botBrain, Booboo, path[1], false, true)
    end

    if PULL_STATE == 4 then
		local time=HoN.GetMatchTime()
		if (time<=lastCheck+checkFrequency)then return end --framskip
		lastCheck=time
		
		local mins=-1
		if time then
			mins,secs=getTime()
			if secs==30 or secs==0 then --SPAWNING
				BotEcho("Getting creepsies :" .. secs)
				return core.OrderMoveToPosAndHoldClamp(botBrain, Booboo, path[PULL_STATE], false, false)
			end
		end
		minutesPassed=mins
    end

    --[[
    if PULL_STATE < 4 then
        return core.OrderMoveToPosAndHold(botBrain, Booboo, path[PULL_STATE], false, true)
    else
        return core.OrderMoveToPosAndHold(botBrain, Booboo, path[4], false, true)
    end
    ]]--

    return false
end

local function ClosestUnit(unit)
	local unitClosestHero = nil
	local nClosestHeroDistSq = 1100*1100 -- Not concerned if more than 900, since Booboo can't attack then, and their range not enough to harm. But predictive running....
    local units = HoN.GetUnitsInRadius(unit:GetPosition(), 1000, core.UNIT_MASK_ALIVE + core.UNIT_MASK_UNIT)
	for id, unitCreep in pairs(units) do
		if unitCreep ~= nil then
			if core.CanSeeUnit(botBrain, unitCreep) and unitHero:GetTeam()~=unit:GetTeam() then
				local nDistanceSq = Vector3.Distance2DSq(unitCreep:GetPosition(), unit:GetPosition())
				if nDistanceSq < nClosestHeroDistSq then
					nClosestHeroDistSq = nDistanceSq
					unitClosestHero = unitHero
				end
			end
		end
	end
        return unitClosestHero
end

local lastCheck=0
local checkFrequency=250
local minutesPassed=-1

function getTime()
	local time=HoN.GetMatchTime()
	if time then
		mins=floor(time/60000)
		secs=floor((time-60000*mins)/1000)
	end
	return mins or -1,secs or -1
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

-- easycamp on matala kuin mikä, vähän vaikeammat on 55.
jungleLib.currentMaxDifficulty = 61
-- jungleLib.currentMaxDifficulty asetus lennossa tilanteen mukaan lienee aika voittoisaa

--[[
jungleLib.jungleSpots={
--Leigon
{pos=Vector3.Create(7200,3600),  description="L closest to well"      ,difficulty=100 ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(6700,4000)    ,corpseBlocking=false, side=legion },
{pos=Vector3.Create(7800,4500),  description="L easy camp"            ,difficulty=30  ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(7800,5200)    ,corpseBlocking=false, side=legion },
{pos=Vector3.Create(9800,4200),  description="L mid-jungle hard camp" ,difficulty=100 ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(9800,3500)    ,corpseBlocking=false, side=legion },
{pos=Vector3.Create(11100,3250), description="L pullable camp"        ,difficulty=55  ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(11100,2700)   ,corpseBlocking=false, side=legion },
{pos=Vector3.Create(11300,4400), description="L camp above pull camp" ,difficulty=55  ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(11300,3800)   ,corpseBlocking=false, side=legion },
{pos=Vector3.Create(4900,8100),  description="L ancients"             ,difficulty=250 ,stacks=0, creepDifficulty=0 ,outsidePos=Vector3.Create(5500,7800)    ,corpseBlocking=false, side=legion },
}
]]--
jungleLib.creepDifficulty={
	Neutral_Catman_leader=40,
	Neutral_Catman=20,
	Neutral_VagabondLeader=30,
	Neutral_Minotaur=15,
	Neutral_Ebula=0,
	Neutral_HunterWarrior=5,
	Neutral_snotterlarge=-1,
	Neutral_snottling=-3,
	Neutral_SkeletonBoss=-5,
	Neutral_AntloreHealer=5,
	Neutral_WolfCommander=10,
	Neutral_Werebeast=0,
	Neutral_Vagabond=5,
	Neutral_VagabondAssassin=7,
	Neutral_Earthoc=-1,
	Neutral_Ogre_Leader=0,
	Neutral_Sporespitter=-2,
	Neutral_Goat=5,
	Neutral_Antling=-3,
	Neutral_Wolf=3,
	Neutral_Dragon=0,
	Neutral_DragonMaster=0,
}

local function jungleUtilityOverride(botBrain)
	local nUtility = 0

    jungleLib.currentMaxDifficulty = 80
	local level = core.unitSelf:GetLevel()
	if level < 3 then
		nUtility = 60
		if object.bDebugUtility == true then BotEcho("  JungleUtility: " .. nUtility) end
		return nUtility
	end

    local vecMyPos = core.unitSelf:GetPosition()
    local vecTargetPos, nCamp = jungleLib.getNearestCampPos(vecMyPos, 0, jungleLib.currentMaxDifficulty)
    if vecTargetPos then
    	local distanceToCamp = Vector3.Distance2D(vecMyPos, vecTargetPos)
    	nUtility = Clamp(70 - distanceToCamp/200, 0, 100) -- [0, 100]
    end

	if core.unitSelf:GetHealthPercent() < 0.15 then
		nUtility = 0
	end

    local Booboo=false
    for key, unit in pairs(core.tControllableUnits["AllUnits"]) do
            if unit:GetTypeName()=="Pet_Yogi_Ability1" then
                    Booboo=unit
                    if not skills.abilQ:CanActivate() then
                    	nUtility = nUtility*Booboo:GetHealthPercent()
                    end
                    local tInv = Booboo:GetInventory(false)
                    for _, item in pairs(tInv) do
                        if item:GetTypeName() == "Item_SwordOfTheHigh" or item:GetTypeName() == "Item_Damage10" then
                            jungleLib.currentMaxDifficulty = jungleLib.currentMaxDifficulty + 100
                        end
                    end
            end
    end

    if object.bDebugUtility == true then BotEcho("  JungleUtility: " .. nUtility .. " - " .. jungleLib.currentMaxDifficulty) end

 	return nUtility
end
behaviorLib.jungleBehavior["Utility"] = jungleUtilityOverride

local function jungleExecuteOverride(botBrain)
        local unitSelf = core.unitSelf
        local debugMode=true

    	local tEnemyHeroes = core.localUnits["EnemyHeroes"]

		for id, hero in pairs(tEnemyHeroes) do
			if Vector3.Distance2D(hero:GetPosition(), unitSelf:GetPosition()) < 1500 then
				return false
			end
		end

        local Booboo=false
	    for key, unit in pairs(core.tControllableUnits["AllUnits"]) do
	            if unit:GetTypeName()=="Pet_Yogi_Ability1" then
	                    Booboo=unit
	            end
	    end

	    if not Booboo then
	        return false
	    end

	    if Booboo:GetHealthPercent() < 0.3 and unitSelf:GetHealth() < 450 then
	    	return false
	    end

        local vecMyPos = unitSelf:GetPosition()
        local vecTargetPos, nCamp = jungleLib.getNearestCampPos(vecMyPos, 0, jungleLib.currentMaxDifficulty)
        if not vecTargetPos then
	       		if core.myTeam == HoN.GetHellbourneTeam() then
       				return core.OrderBothMoveToPosClamp(botBrain, unitSelf, Booboo, Vector3.Create(7800,10600))
       			else
    	   			return core.OrderBothMoveToPosClamp(botBrain, unitSelf, Booboo, Vector3.Create(7800,5500))
	       		end
                --return false
        end

        local distanceToCamp = Vector3.Distance2D(vecMyPos, vecTargetPos)
        if core.unitSelf:GetLevel() < 3 and distanceToCamp > 6000 then

        end


        if debugMode then core.DrawDebugArrow(vecMyPos, vecTargetPos, 'green') end

        local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, vecTargetPos)
        if unitSelf:GetLevel() > 2 and (nTargetDistanceSq > (600 * 600) or jungleLib.nStacking ~= 0) then
                -- Move to the next camp
                local nMins, nSecs = jungleLib.getTime()
                if jungleLib.nStacking ~= 0 or ((nSecs > 40 or nMins == 0) and nTargetDistanceSq < (800 * 800) and nTargetDistanceSq > (400 * 400)) then
                        -- Stack the camp if possible
                        if nSecs < 53 and (nSecs > 40 or nMins == 0) then
                                --BotEcho("JUNGLE wait")
                                -- Wait outside the camp
                                jungleLib.nStacking = 1
                                jungleLib.nStackingCamp = nCamp

                                return core.OrderMoveToPosAndHoldClamp(botBrain, core.unitSelf, jungleLib.jungleSpots[nCamp].outsidePos, false)
                        elseif jungleLib.nStacking == 1 and unitSelf:IsAttackReady() then
                                --BotEcho("JUNGLE attack")
                                -- Attack the units in the camp
                                if nSecs >= 57 then 
                                        -- Missed our chance to stack
                                        jungleLib.nStacking = 0 
                                end

                                --return core.OrderAttackPosition(botBrain, Booboo, vecTargetPos,false,false)
                                return core.OrderAttackPosition(botBrain, unitSelf, vecTargetPos,false,false)
                        elseif jungleLib.nStacking ~= 0 and nTargetDistanceSq < (1500 * 1500) and nSecs > 50 then
                                --BotEcho("JUNGLE stack")
                                -- Move away from the units in the camp
                                jungleLib.nStacking = 2
                                local vecAwayPos = jungleLib.jungleSpots[jungleLib.nStackingCamp].pos + (jungleLib.jungleSpots[jungleLib.nStackingCamp].outsidePos - jungleLib.jungleSpots[jungleLib.nStackingCamp].pos) * 5
                                if debugMode then
                                        core.DrawXPosition(jungleLib.jungleSpots[jungleLib.nStackingCamp].pos, 'red')
                                        core.DrawXPosition(jungleLib.jungleSpots[jungleLib.nStackingCamp].outsidePos, 'red')
                                        core.DrawDebugArrow(jungleLib.jungleSpots[jungleLib.nStackingCamp].pos,vecAwayPos, 'green')
                                end

                                --return core.OrderMoveToPosClamp(botBrain, Booboo, vecAwayPos, false)
                                return core.OrderMoveToPosClamp(botBrain, core.unitSelf, vecAwayPos, false)
                        else
                                --BotEcho("JUNGLE stack done")
                                -- Finished stacking
                                jungleLib.nStacking = 0
                                return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecTargetPos)
                        end
                else
                        --BotEcho("JUNGLE move to camp")
                        -- Otherwise just move to camp
                        ATPOSITION = -2
                        core.OrderFollow(botBrain, Booboo, unitSelf)
                        return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecTargetPos)
                end
        else 
                --BotEcho("JUNGLE kill!")
                -- Kill neutrals in the camp
                tUnits = core.AssessLocalUnits(object, unitSelf:GetPosition(), 1000)
                tUnits = tUnits["Neutrals"]
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
                        local vecAwayPos = jungleLib.jungleSpots[nCamp].pos + (jungleLib.jungleSpots[nCamp].outsidePos - jungleLib.jungleSpots[nCamp].pos) * 5
                        if unitStrongest then
                        	if ATPOSITION ~=0 then
                        		keepAtDistance(unitSelf, unitStrongest, 400)
                        	end
                        	if Vector3.Distance2D(Booboo:GetPosition(), unitSelf:GetPosition())>900 and Booboo:GetHealthPercent()>0.7 then
								return core.OrderAbility(botBrain, Booboo:GetAbility(0))
							end
                        end

                        -- Attack the strongest unit
                        if unitStrongest and unitStrongest:GetPosition() then
                                local nStrongestTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, unitStrongest:GetPosition())
                                --BotEcho(unitStrongest:GetTypeName()..": "..unitStrongest:GetHealth())
                                if ATPOSITION ~=0 then
                                	return core.OrderBothAttackClamp(botBrain, unitSelf, Booboo, unitStrongest, false)
                                else
                                	return core.OrderAttackClamp(botBrain, Booboo, unitStrongest, false)
                                end
                                --return core.OrderAttackClamp(botBrain, unitSelf, unitStrongest, false)
                        else
                        		if ATPOSITION ~=0 then
                        	    	return core.OrderBothAttackPositionClamp(botBrain, unitSelf, Booboo, vecTargetPos, false, false)
                        	    else
                        	    	return core.OrderAttackPositionClamp(botBrain, Booboo, vecTargetPos, false, false)
                        	    end
                                --return core.OrderAttackPosition(botBrain, unitSelf, vecTargetPos, false, false)
                        end
                end
        end

        return false
end
behaviorLib.jungleBehavior["Execute"] = jungleExecuteOverride

-- core.GetAttackSequenceProgress(unit) 
--	-------|                       | == "windup"
--	       |----------|            | == "followThrough"
--	                  |------------| == "idle"

local ATPOSITION = -2
function keepAtDistance(unit, target, range, vecAwayPos)
	local bDebug = false

	local dist = Vector3.Distance2D(unit:GetPosition(), target:GetPosition())

	if bDebug then printf("%.0f | %.0f | %.0f", range - 100, dist, range + 100) end

	if dist > range + 100 then
		ATPOSITION = 1
	elseif dist < range - 100 then
		local targetPos = AwayVector(unit, target)
		if vecAwayPos then targetPos = vecAwayPos end
		core.OrderMoveToPosClamp(object, unit, targetPos)
		ATPOSITION = -1
		if bDebug then core.DrawDebugArrow(unit:GetPosition(), targetPos, 'yellow') end
	else
		if ATPOSITION ~= 0 then
			core.OrderMoveToPos(object, unit, unit:GetPosition())
		end
		ATPOSITION = 0
		return true
	end
	return false
end

function AwayVector(unit, target)
    local vecUnitPos = unit:GetPosition()
    local vecTargetPos = target:GetPosition()

	return vecUnitPos - (vecTargetPos - vecUnitPos)
end

function printf(...) return Echo(string.format(...)) end

-- Tee tästä oikeastaan iterable table tj..
function printUnit(unit)
  local hero = core.unitSelf
  local vecSelfPos = hero:GetPosition()
  local vecUnitPos = unit:GetPosition()
  local nUnitTeam = unit:GetTeam()
  local nSelfTeam = hero:GetTeam()
  local vecDistance2 = Vector3.Distance2DSq(vecSelfPos, vecUnitPos)
  local vecDistance = Vector3.Distance2D(vecSelfPos, vecUnitPos)
  printf("  %s: %.0f (%.0f, %.0f)", unit:GetTypeName(), unit:GetHealth(), vecUnitPos.x, vecUnitPos.y)
end

function printUnits(unittable)
  for key,value in pairs(unittable) do 
      print(key .. " " .. core.NumberElements(value) ..  "\n")
      local units = value
      for id, unit in pairs(units) do
        printUnit(unit)
      end
  end
end

function donotuse_onlyhereforreference()
	local curTimeMS = HoN.GetGameTime()
	--stagger updates so we don't have permajitter	
	if curTimeMS < core.nextOrderTime then
		BotEcho(curTimeMS .. " vs " .. core.nextOrderTime)
		return true
	end
	local queue = "None"
	if bQueueCommand then
		queue = "Back"
	end
	botBrain:OrderEntity(unit.object or unit, "Attack", unitTarget.object or unitTarget, queue)
	
	core.nextOrderTime = curTimeMS + core.timeBetweenOrders
end

local function ShopUtilityOverride(botBrain)
	local item = HoN.GetItemDefinition(behaviorLib.StartingItems[1])
	local gold = botBrain:GetGold()

	if gold > item:GetCost() then
		if object.bDebugUtility == true then BotEcho("  ShopUtility: " .. 100 .. " (" .. item:GetName() .. " " .. item:GetCost() .. " " .. gold.. ")") end
		return 100
	end
	if object.bDebugUtility == true then BotEcho("  ShopUtility: " .. 0) end
	return 0
end
behaviorLib.ShopBehavior["Utility"] = ShopUtilityOverride

local function ShopExecuteOverride(botBrain)
	if object.bUseShop == false then
		return
	end

	local nTime = HoN.GetMatchTime()
	if nTime < 1 then
		return true
	end

	local Booboo=false
	for key, unit2 in pairs(core.localUnits["AllyUnits"]) do
		if unit2:GetTypeName()=="Pet_Yogi_Ability1" then
			Booboo=unit2
		end
	end

	if not Booboo then
		return
	end

    local inventory = core.unitSelf:GetInventory(true)

	local bCanAccessShop = core.unitSelf:CanAccessStash()
	if not bCanAccessShop or Vector3.Distance2D(Booboo:GetPosition(), core.allyWell:GetPosition()) > 200 then
		return core.OrderBothMoveToPosAndHoldClamp(botBrain, core.unitSelf, Booboo, core.allyWell:GetPosition())
	end

	if Vector3.Distance2D(Booboo:GetPosition(), core.unitSelf:GetPosition())>400 then
		return core.OrderAbility(botBrain, Booboo:GetAbility(0))
	end

	if behaviorLib.nextBuyTime > HoN.GetGameTime() then
		return
	end

	behaviorLib.nextBuyTime = HoN.GetGameTime() + behaviorLib.buyInterval

	if behaviorLib.buyState == behaviorLib.BuyStateUnknown then
		behaviorLib.DetermineBuyState(botBrain)
	end
	
	local unitSelf = core.unitSelf

	local bChanged = false
	local bGoldReduced = false
	local nextItemDef =  HoN.GetItemDefinition(behaviorLib.StartingItems[1])

	if nextItemDef then
		core.teamBotBrain.bPurchasedThisFrame = true

		local goldAmtBefore = botBrain:GetGold()
		Booboo:PurchaseRemaining(nextItemDef)

		local goldAmtAfter = botBrain:GetGold()
		bGoldReduced = (goldAmtAfter < goldAmtBefore)
		bChanged = bChanged or bGoldReduced
	end

	if bChanged == false then
		BotEcho("Finished Buying!")
		behaviorLib.finishedBuying = true
	else
		tremove(behaviorLib.StartingItems, 1)
		--BotEcho(nextItemDef:GetName() .. " next: " .. HoN.GetItemDefinition(behaviorLib.StartingItems[1]):GetName())
	end
end
behaviorLib.ShopBehavior["Execute"] = ShopExecuteOverride

function core.OrderBothAttackPositionClamp(botBrain, unit, booboo, position, bInterruptAttacks, bQueueCommand)
	if object.bRunCommands == false or object.bMoveCommands == false then
		return false
	end
	
	local curTimeMS = HoN.GetGameTime()
	if curTimeMS < core.nextOrderTime then
		return true
	end
	
	core.OrderAttackPosition(botBrain, unit, position, bInterruptAttacks, bQueueCommand)
	core.OrderAttackPosition(botBrain, booboo, position, bInterruptAttacks, bQueueCommand)
	
	core.nextOrderTime = curTimeMS + core.timeBetweenOrders
	return true
end

function core.OrderBothAttackClamp(botBrain, unit, booboo, unitTarget, bQueueCommand)
	if object.bRunCommands == false or object.bAttackCommands == false then
		return false
	end
	if bQueueCommand == nil then
		bQueueCommand = false
	end
	local curTimeMS = HoN.GetGameTime()
	--stagger updates so we don't have permajitter	
	if curTimeMS < core.nextOrderTime then
		return true
	end
	local queue = "None"
	if bQueueCommand then
		queue = "Back"
	end
	botBrain:OrderEntity(unit.object or unit, "Attack", unitTarget.object or unitTarget, queue)
	botBrain:OrderEntity(booboo.object or booboo, "Attack", unitTarget.object or unitTarget, queue)

	core.nextOrderTime = curTimeMS + core.timeBetweenOrders
	return true
end

function core.OrderBothMoveToPosClamp(botBrain, unit, booboo, position, bInterruptAttacks, bQueueCommand)
	if object.bRunCommands == false or object.bMoveCommands == false then
		return false
	end

	local curTimeMS = HoN.GetGameTime()
	if curTimeMS < core.nextOrderTime then
		return true
	end
	
	if Vector3.Distance2DSq(unit:GetPosition(), position) > core.distSqTolerance then
		core.OrderMoveToPos(botBrain, booboo, position, bInterruptAttacks, bQueueCommand)
		core.OrderMoveToPos(botBrain, unit, position, bInterruptAttacks, bQueueCommand)
	end
	
	core.nextOrderTime = curTimeMS + core.timeBetweenOrders
	return true
end

function core.OrderBothMoveToPosAndHoldClamp(botBrain, unit, booboo, position, bInterruptAttacks, bQueueCommand)
	if object.bRunCommands == false or object.bMoveCommands == false then
		return false
	end
	
	local curTimeMS = HoN.GetGameTime()
	if curTimeMS < core.nextOrderTime then
		return true
	end
	
	core.OrderMoveToPosAndHold(botBrain, unit, position, bInterruptAttacks, bQueueCommand)
	core.OrderMoveToPosAndHold(botBrain, booboo, position, bInterruptAttacks, bQueueCommand)
	
	core.nextOrderTime = curTimeMS + core.timeBetweenOrders
	return true
end


local function HarassHeroExecuteOverride(botBrain)
	local bDebugEchos = true

	local ulti = skills.abilR
	printf("%s d:%s r:%s a:%s", ulti:GetTypeName(), tostring(ulti:IsDisabled()), tostring(ulti:IsReady()), tostring(ulti:IsActive()))

	local Booboo=false
	for key, unit2 in pairs(core.localUnits["AllyUnits"]) do
		if unit2:GetTypeName()=="Pet_Yogi_Ability1" then
			Booboo=unit2
		end
	end

	-- Pitäisi myös pitää oma positio mahdollisimman kaukana while at it.

	if not Booboo then
		return false -- :(
	end

	local unitSelf = core.unitSelf
	local unitTarget = behaviorLib.heroTarget
	local vecTargetPos = (unitTarget and unitTarget:GetPosition()) or nil

	if bDebugEchos then BotEcho("Harassing "..((unitTarget~=nil and unitTarget:GetTypeName()) or "nil")) end
	if unitTarget and vecTargetPos then
		local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
		local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget, true)
		local nBDistSq = Vector3.Distance2DSq(Booboo:GetPosition(), vecTargetPos)
		local nBAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(Booboo, unitTarget, true)

		local itemGhostMarchers = core.itemGhostMarchers

		--only attack when in nRange, so not to aggro towers/creeps until necessary, and move forward when attack is on cd
		if nBDistSq < nBAttackRangeSq and Booboo:IsAttackReady() and core.CanSeeUnit(botBrain, unitTarget) then
			local bInTowerRange = core.NumberElements(core.GetTowersThreateningUnit(Booboo)) > 0
			local bShouldDive = behaviorLib.lastHarassUtil >= behaviorLib.diveThreshold
			
			if bDebugEchos then BotEcho(format("inTowerRange: %s  bShouldDive: %s", tostring(bInTowerRange), tostring(bShouldDive))) end
			
			if not bInTowerRange or bShouldDive then
				if bDebugEchos then BotEcho("ATTAKIN NOOBS! divin: "..tostring(bShouldDive)) end
				core.OrderAttackClamp(botBrain, Booboo, unitTarget)
			end
		else
			if bDebugEchos then BotEcho("MOVIN OUT") end
			local vecDesiredPos = vecTargetPos
			local bUseTargetPosition = true

			if itemGhostMarchers and itemGhostMarchers:CanActivate() then
				core.OrderItemClamp(botBrain, Booboo, itemGhostMarchers) -- XXX - itemGhostMarchers booboolla eri asia.
				return
			else
				local bChanged = false
				local bWellDiving = false
				vecDesiredPos, bChanged, bWellDiving = core.AdjustMovementForTowerLogic(vecDesiredPos)
				
				if bDebugEchos then BotEcho("Move - bChanged: "..tostring(bChanged).."  bWellDiving: "..tostring(bWellDiving)) end
				
				if not bWellDiving then
					if behaviorLib.lastHarassUtil < behaviorLib.diveThreshold then
						if bDebugEchos then BotEcho("DON'T DIVE!") end
										
						if bUseTargetPosition and not bChanged then
							core.OrderMoveToUnitClamp(botBrain, Booboo, unitTarget, false)
						else
							core.OrderMoveToPosAndHoldClamp(botBrain, Booboo, vecDesiredPos, false)
						end
					else
						if bDebugEchos then BotEcho("DIVIN Tower! util: "..behaviorLib.lastHarassUtil.." > "..behaviorLib.diveThreshold) end
						core.OrderMoveToPosClamp(botBrain, Booboo, vecDesiredPos, false)
					end
				else
					return false
				end
			end

			--core.DrawXPosition(vecDesiredPos, 'blue')
		end
	else
		return false
	end
end
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


local function MoveExecuteOverride(botBrain, vecDesiredPosition)
	if bDebugEchos then BotEcho("Movin'") end
	local bActionTaken = false
	
	local unitSelf = core.unitSelf
	local vecMyPosition = unitSelf:GetPosition()
	local vecMovePosition = vecDesiredPosition
	
	local Booboo=false
	for key, unit2 in pairs(core.localUnits["AllyUnits"]) do
		if unit2:GetTypeName()=="Pet_Yogi_Ability1" then
			Booboo=unit2
		end
	end

	local nDesiredDistanceSq = Vector3.Distance2DSq(vecDesiredPosition, vecMyPosition)			
	if nDesiredDistanceSq > core.nOutOfPositionRangeSq then
		--check porting
		if bActionTaken == false then
			StartProfile("PortLogic")
				local bPorted = behaviorLib.PortLogic(botBrain, vecDesiredPosition)
			StopProfile()
			
			if bPorted then
				if bDebugEchos then BotEcho("Portin'") end
				bActionTaken = true
			end
		end
		
		if bActionTaken == false then
			--we'll need to path there
			if bDebugEchos then BotEcho("Pathin'") end
			StartProfile("PathLogic")
				local vecWaypoint = behaviorLib.PathLogic(botBrain, vecDesiredPosition)
			StopProfile()
			if vecWaypoint then
				vecMovePosition = vecWaypoint
			end
		end
	end
	
	--move out
	if bActionTaken == false then
		if bDebugEchos then BotEcho("Move 'n' hold order") end
		if Booboo then
			bActionTaken = core.OrderBothMoveToPosAndHoldClamp(botBrain, unitSelf, Booboo, vecMovePosition)
		else
			bActionTaken = core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecMovePosition)
		end
	end
	
	return bActionTaken
end
behaviorLib.MoveExecute = MoveExecuteOverride


function PushExecuteOverride(botBrain)

	local bDebugLines = false
	
	--if botBrain.myName == 'ShamanBot' then bDebugLines = true end
	
	if core.unitSelf:IsChanneling() then 
		return
	end

	local Booboo=false
	for key, unit2 in pairs(core.localUnits["AllyUnits"]) do
		if unit2:GetTypeName()=="Pet_Yogi_Ability1" then
			Booboo=unit2
		end
	end

	local unitSelf = core.unitSelf
	local bActionTaken = false

	-- NOTE: See original if we want to use items when pushing

	--Attack creeps if we're in range
	if bActionTaken == false then
		local unitTarget = core.unitEnemyCreepTarget
		if unitTarget then
			if bDebugEchos then BotEcho("Attacking creeps") end
			local nRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
			if unitSelf:GetAttackType() == "melee" then
				--override melee so they don't stand *just* out of range
				nRange = 250
			end
			
			if unitSelf:IsAttackReady() and core.IsUnitInRange(unitSelf, unitTarget, nRange) then
				if Booboo then
					bActionTaken = core.OrderBothAttackClamp(botBrain, unitSelf, Booboo, unitTarget)
				else
					bActionTaken = core.OrderAttackClamp(botBrain, unitSelf, unitTarget)
				end
			end
			
			if bDebugLines then core.DrawXPosition(unitTarget:GetPosition(), 'red', 125) end
		end
	end
	
	if bActionTaken == false then
		local vecDesiredPos = behaviorLib.PositionSelfLogic(botBrain)
		if vecDesiredPos then
			if bDebugEchos then BotEcho("Moving out") end
			bActionTaken = behaviorLib.MoveExecute(botBrain, vecDesiredPos)
			
			if bDebugLines then core.DrawXPosition(vecDesiredPos, 'blue') end
		end
	end
	
	if bActionTaken == false then
		return false
	end
end
behaviorLib.PushBehavior["Execute"] = PushExecuteOverride


-------- Behavior Fns --------
local function RetreatFromThreatUtilityOverride(botBrain)
	nUtility = object.RetreatFromThreatBehaviorOld(botBrain)

	local unitSelf = core.unitSelf
	local tEnemyHeroes = core.localUnits["EnemyHeroes"]

	for id, hero in pairs(tEnemyHeroes) do
		if Vector3.Distance2D(hero:GetPosition(), unitSelf:GetPosition()) < 1500 then
			nUtility = nUtility + 20
		end
	end
	if object.bDebugUtility == true then BotEcho("  RealRetreatFromThreat: " .. nUtility) end
	return Clamp(nUtility, 0, 100)
end

local function RetreatFromThreatExecuteOverride(botBrain)
	--Activate ghost marchers if we can
	local itemGhostMarchers = core.itemGhostMarchers
	if behaviorLib.lastRetreatUtil >= behaviorLib.retreatGhostMarchersThreshold and itemGhostMarchers and itemGhostMarchers:CanActivate() then
		core.OrderItemClamp(botBrain, core.unitSelf, itemGhostMarchers)
		return
	end

	local ulti = skills.abilR
	if ulti:GetLevel() > 0 and not ulti:IsActive() and ulti:CanActivate() then
		return core.OrderAbility(botBrain, ulti, true)
	end

	local vecPos = behaviorLib.PositionSelfBackUp()
	core.OrderMoveToPosClamp(botBrain, core.unitSelf, vecPos, false)
end

object.RetreatFromThreatBehaviorOld = behaviorLib.RetreatFromThreatBehavior["Utility"]
behaviorLib.RetreatFromThreatBehavior["Utility"] = RetreatFromThreatUtilityOverride
behaviorLib.RetreatFromThreatBehavior["Execute"] = RetreatFromThreatExecuteOverride
