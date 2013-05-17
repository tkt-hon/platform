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
local shopping = object.shoppingHandler

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

--   item buy order. internal names
behaviorLib.StartingItems  = 	{"Item_IronBuckler", "Item_LoggersHatchet"}
behaviorLib.LaneItems  = 		{"Item_SwordOfTheHigh", "Item_Damage10"}
behaviorLib.MidItems  = 		{"Item_Marchers", "Item_EnhancedMarchers"}
behaviorLib.LateItems  = 		{"Item_Lightning1", "Item_Lightning2", "Item_Sicarius", "Item_StrengthAgility", "Item_FrostfieldPlate", "Item_BehemothsHeart"}

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
	return object.HealAtWellExecuteOld(botBrain)
end
object.HealAtWellExecuteOld = behaviorLib.HealAtWellBehavior["Execute"]
behaviorLib.HealAtWellBehavior["Execute"] = HealAtWellExecuteOverride


local function GetAttackDamageOnCreep(botBrain, unitCreepTarget)
	if not unitCreepTarget or not core.CanSeeUnit(botBrain, unitCreepTarget) then
		return nil
	end

	local unitSelf = core.unitSelf

	--Get positioning information
	local vecSelfPos = unitSelf:GetPosition()
	local vecTargetPos = unitCreepTarget:GetPosition()

	--Get projectile info
	local nProjectileSpeed = unitSelf:GetAttackProjectileSpeed()
	local nProjectileTravelTime = Vector3.Distance2D(vecSelfPos, vecTargetPos) / nProjectileSpeed
	if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end

	local nExpectedCreepDamage = 0
	local nExpectedTowerDamage = 0
	local tNearbyAttackingCreeps = nil
	local tNearbyAttackingTowers = nil

	--Get the creeps and towers on the opposite team
	-- of our target
	if unitCreepTarget:GetTeam() == unitSelf:GetTeam() then
		tNearbyAttackingCreeps = core.localUnits['EnemyCreeps']
		tNearbyAttackingTowers = core.localUnits['EnemyTowers']
	else
		tNearbyAttackingCreeps = core.localUnits['AllyCreeps']
		tNearbyAttackingTowers = core.localUnits['AllyTowers']
	end

	--Determine the damage expected on the creep by other creeps
	for i, unitCreep in pairs(tNearbyAttackingCreeps) do
		if unitCreep:GetAttackTarget() == unitCreepTarget then
			local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
			nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
		end
	end

	--Determine the damage expected on the creep by other towers
	for i, unitTower in pairs(tNearbyAttackingTowers) do
		if unitTower:GetAttackTarget() == unitCreepTarget then
			local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
			nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
		end
	end

	return nExpectedCreepDamage + nExpectedTowerDamage
end

function GetCreepAttackTargetOverride(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
	local bDebugEchos = false

	--Get info about self
	local unitSelf = core.unitSelf

	local Booboo={}
	for key, unit2 in pairs(core.localUnits["AllyUnits"]) do
		if unit2:GetTypeName()=="Pet_Yogi_Ability1" then
			Booboo=unit2
		end
	end

	local unitClosestHero = nil
	local nClosestHeroDistSq = 1100*1100 -- Not concerned if more than 900, since Booboo can't attack then, and their range not enough to harm. But predictive running....
	for id, unitHero in pairs(HoN.GetHeroes(core.enemyTeam)) do
		if unitHero ~= nil then
			if core.CanSeeUnit(botBrain, unitHero) and unitHero:GetTeam()~=team then
				local nDistanceSq = Vector3.Distance2DSq(unitHero:GetPosition(), core.unitSelf:GetPosition())
				if nDistanceSq < nClosestHeroDistSq then
					nClosestHeroDistSq = nDistanceSq
					unitClosestHero = unitHero
				end
			end
		end
	end
	local wellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
	if Booboo then
		if Booboo:GetHealthPercent() and Booboo:GetHealthPercent() > 0.35 then
	--		core.OrderMoveToPosClamp(botBrain, Booboo, core.unitSelf:GetPosition(), false)
			if unitClosestHero~=nil then
				core.OrderAttack(botBrain, Booboo, unitClosestHero,false)
			else
				core.OrderMoveToPos(botBrain, Booboo, core.unitSelf:GetPosition(), false)
			end
		else
			core.OrderMoveToPos(botBrain, Booboo, wellPos, false)
		end
		if Vector3.Distance2DSq(Booboo:GetPosition(), wellPos)<1000*1000 and Booboo:GetHealthPercent()<0.9 then
			core.OrderMoveToPos(botBrain, Booboo, wellPos, false)
		end
		if Vector3.Distance2DSq(Booboo:GetPosition(), unitSelf:GetPosition())>10000*10000 and Booboo:GetHealthPercent()>0.9 then
			core.OrderAbility(botBrain, Booboo:GetAbility(0))
		end
	end

	local nDamageMin = unitSelf:GetFinalAttackDamageMin()

	if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
		local nTargetHealth = unitEnemyCreep:GetHealth()
		--Only attack if, by the time our attack reaches the target
		-- the damage done by other sources brings the target's health
		-- below our minimum damage
		if nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitEnemyCreep)) then
			if bDebugEchos then BotEcho("Returning an enemy") end
			return unitEnemyCreep
		end
	end

	if unitAllyCreep then
		local nTargetHealth = unitAllyCreep:GetHealth()

		--Only attack if, by the time our attack reaches the target
		-- the damage done by other sources brings the target's health
		-- below our minimum damage
		if nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitAllyCreep)) then
			local bActuallyDeny = true

			if bActuallyDeny then
				if bDebugEchos then BotEcho("Returning an ally") end
				return unitAllyCreep
			end
		end
	end

	return nil
end
-- overload the behaviour stock function with custom
object.getCreepAttackTargetOld = behaviorLib.GetCreepAttackTarget
behaviorLib.GetCreepAttackTarget = GetCreepAttackTargetOverride


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

local function HarassHeroBehavior(botBrain)
    return 0
end
object.HarassHeroBehaviorUtilityOld = behaviorLib.HarassHeroBehavior["Utility"]
behaviorLib.HarassHeroBehavior["Utility"]  = HarassHeroBehavior

local function PushBehavior(botBrain)
    return 0
end
object.PushBehaviorUtilityOld = behaviorLib.PushBehavior["Utility"]
behaviorLib.PushBehavior["Utility"]  = PushBehavior

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

jungleLib.currentMaxDifficulty = 40
-- jungleLib.currentMaxDifficulty asetus lennossa tilanteen mukaan lienee aika voittoisaa

local function jungleUtilityOverride(botBrain)
 	if core.unitSelf:GetLevel() > 2 then
 		return 70
 	end
 	return 0
end
behaviorLib.jungleBehavior["Utility"] = jungleUtilityOverride


local function jungleExecuteOverride(botBrain)
        local unitSelf = core.unitSelf
        local debugMode=true

        local Booboo=false
	    for key, unit in pairs(core.tControllableUnits["AllUnits"]) do
	            if unit:GetTypeName()=="Pet_Yogi_Ability1" then
	                    Booboo=unit
	            end
	    end

	    if not Booboo then
	        return false
	    end

        local vecMyPos = unitSelf:GetPosition()
        local vecTargetPos, nCamp = jungleLib.getNearestCampPos(vecMyPos, 0, jungleLib.currentMaxDifficulty)
        if not vecTargetPos then
                return false
        end

        if debugMode then core.DrawDebugArrow(vecMyPos, vecTargetPos, 'green') end

        local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, vecTargetPos)
        if nTargetDistanceSq > (600 * 600) or jungleLib.nStacking ~= 0 then
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
                                BotEcho("JUNGLE attack")
                                -- Attack the units in the camp
                                if nSecs >= 57 then 
                                        -- Missed our chance to stack
                                        jungleLib.nStacking = 0 
                                end

                                --return core.OrderAttackPosition(botBrain, Booboo, vecTargetPos,false,false)
                                return core.OrderAttackPosition(botBrain, unitSelf, vecTargetPos,false,false)
                        elseif jungleLib.nStacking ~= 0 and nTargetDistanceSq < (1500 * 1500) and nSecs > 50 then
                                BotEcho("JUNGLE stack")
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
                                BotEcho("JUNGLE stack done")
                                -- Finished stacking
                                jungleLib.nStacking = 0
                                return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecTargetPos)
                        end
                else
                        --BotEcho("JUNGLE move to camp")
                        -- Otherwise just move to camp
                        ATPOSITION = -2
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

                        if unitStrongest then
                        	keepAtDistance(unitSelf, unitStrongest, 400)
                        	if Vector3.Distance2D(unitSelf:GetPosition(), Booboo:GetPosition()) > 1000 and Booboo:GetHealthPercent() > 0.6 then
                        		-- Call Booboo
                        		if Booboo:GetAbility(0):CanActivate() then
                        			core.OrderAbility(object, Booboo:GetAbility(0))
                        		end
                        	end
                        end

                        -- Attack the strongest unit
                        if unitStrongest and unitStrongest:GetPosition() then
                                local nStrongestTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, unitStrongest:GetPosition())
                                --BotEcho(unitStrongest:GetTypeName()..": "..unitStrongest:GetHealth())
                                return core.OrderAttackClamp(botBrain, Booboo, unitStrongest, false)
                                --return core.OrderAttackClamp(botBrain, unitSelf, unitStrongest, false)
                        else
                        	    return core.OrderAttackPositionClamp(botBrain, Booboo, vecTargetPos, false, false)
                                --return core.OrderAttackPosition(botBrain, unitSelf, vecTargetPos, false, false)
                        end
                end
        end

        return false
end
behaviorLib.jungleBehavior["Execute"] = jungleExecuteOverride

local function AttackCreepsExecuteWS(botBrain)
	local state = core.AttackCreepsExecuteWSOverride(botBrain)
	if not state then
		return false
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


	local unitSelf = Booboo
	local currentTarget = core.unitCreepTarget

	if currentTarget and core.CanSeeUnit(botBrain, currentTarget) then		
		local vecTargetPos = currentTarget:GetPosition()
		local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
		local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)

		if currentTarget ~= nil then
			if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() then
				--only attack when in nRange, so not to aggro towers/creeps until necessary, and move forward when attack is on cd
				core.OrderAttackClamp(botBrain, unitSelf, currentTarget)
			else
				--BotEcho("MOVIN OUT")
				local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
				core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)
			end
		end
	else
		return false
	end
end
core.AttackCreepsExecuteWSOverride = behaviorLib.AttackCreepsExecute
behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteWS

-- core.GetAttackSequenceProgress(unit) 
--	-------|                       | == "windup"
--	       |----------|            | == "followThrough"
--	                  |------------| == "idle"

local ATPOSITION = -2
function keepAtDistance(unit, target, range)
	local bDebug = true

	local dist = Vector3.Distance2D(unit:GetPosition(), target:GetPosition())

	if bDebug then printf("%.0f | %.0f | %.0f", range - 100, dist, range + 100) end

	if dist > range + 100 then
		if ATPOSITION ~= 1 then
			core.OrderMoveToUnitClamp(object, unit, target)
		end
		ATPOSITION = 1
		if bDebug then core.DrawDebugArrow(unit:GetPosition(), target:GetPosition(), 'white') end
	elseif dist < range - 100 then
		core.OrderMoveToPosClamp(object, unit, AwayVector(unit, target))
		ATPOSITION = -1
		if bDebug then core.DrawDebugArrow(unit:GetPosition(), AwayVector(unit, target), 'yellow') end
	else
		if ATPOSITION ~= 0 then
			core.OrderMoveToPosClamp(object, unit, unit:GetPosition())
		end
		ATPOSITION = true
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