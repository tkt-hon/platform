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

object.bReportBehavior = true -- DEBUG
object.bDebugUtility = true -- DEBUG

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
    = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
    = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp


BotEcho(object:GetName()..' loading Yogi_main...')


object.bReportBehavior = true -- DEBUG
object.bDebugUtility = true -- DEBUG


--####################################################################
--####################################################################
--#                                                                 ##
--#                  bot constant definitions                       ##
--#                                                                 ##
--####################################################################
--####################################################################

-- hero_<hero>  to reference the internal hon name of a hero, Hero_Yogi ==wildsoul

--   item buy order. internal names
behaviorLib.StartingItems  = 	{"Item_RunesOfTheBlight", "Item_IronBuckler", "Item_LoggersHatchet"}
behaviorLib.LaneItems  = 		{"Item_Lightning1", "Item_EnhancedMarchers", }
behaviorLib.MidItems  = 		{"Item_Protect", "Item_Dawnbringer"}
behaviorLib.LateItems  = 		{"Item_Lightning2", "Item_FrostfieldPlate", "Item_BehemothsHeart"}


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

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
    self:onthinkOld(tGameVariables)

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

--[[

------------------------------------------------------
--            customharassutility override          --
-- change utility according to usable spells here   --
------------------------------------------------------
-- @param: iunitentity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
    return 0
end
-- assisgn custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none
local function HarassHeroExecuteOverride(botBrain)

    local unitTarget = behaviorLib.heroTarget
    if unitTarget == nil then
        return object.harassExecuteOld(botBrain) --Target is invalid, move on to the next behavior
    end


    local unitSelf = core.unitSelf
    local vecMyPosition = unitSelf:GetPosition()
    local nAttackRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
    local nMyExtraRange = core.GetExtraRange(unitSelf)

    local vecTargetPosition = unitTarget:GetPosition()
    local nTargetExtraRange = core.GetExtraRange(unitTarget)
    local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)

    local nLastHarassUtility = behaviorLib.lastHarassUtil
    local bCanSee = core.CanSeeUnit(botBrain, unitTarget)
    local bActionTaken = false


    --- Insert abilities code here, set bActionTaken to true
    --- if an ability command has been given successfully


    if not bActionTaken then
        return object.harassExecuteOld(botBrain)
    end
end
-- overload the behaviour stock function with custom
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


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

	if skills.abilQ:CanActivate() then
		actionTaken = core.OrderAbility(botBrain, skills.abilQ)
	end
	if skills.abilW:CanActivate() then
		actionTaken = core.OrderAbility(botBrain, skills.abilW)
	end

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

			--[Difficulty: Easy] Don't deny
			if core.nDifficulty == core.nEASY_DIFFICULTY then
				bActuallyDeny = false
			end

			-- [Tutorial] Hellbourne *will* deny creeps after shit gets real
			if core.bIsTutorial and core.bTutorialBehaviorReset == true and core.myTeam == HoN.GetHellbourneTeam() then
				bActuallyDeny = true
			end

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

]]--

function debugUtility(botBrain)
    return 99
end


local PULL_STATE = 1
local PULL_RETURNING = false
local PULL_LEG = {Vector3.Create(2248, 9342), Vector3.Create(4284, 8875), Vector3.Create(10061, 13088), Vector3.Create(9938, 13348)}
local PULL_HB = {Vector3.Create(14223, 6516), Vector3.Create(7955, 5136), Vector3.Create(5637, 2195), Vector3.Create(5606, 1900)}
local PULL_STARTED = false

-- cg_drawSelectedStats true
function debugExecute(botBrain)
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

    local Booboo={}
    for key, unit2 in pairs(core.localUnits["AllyUnits"]) do
            if unit2:GetTypeName()=="Pet_Yogi_Ability1" then
                    Booboo=unit2
            end
    end

    if not Booboo then
        return false
    end

    local unitSelf = core.unitSelf
    core.OrderMoveToPosAndHold(botBrain, unitSelf, path[1]+Vector3.Create(-200,-200), false)
    local vecSelfPos = Booboo:GetPosition()
    print(Vector3.Distance2D(vecSelfPos, path[PULL_STATE]).." Durr:"..PULL_STATE.." Hurr:"..tostring(PULL_RETURNING).."\n")
    if Vector3.Distance2D(vecSelfPos, path[PULL_STATE]) < 100 then
        if PULL_RETURNING then
            PULL_STATE = PULL_STATE-1
            if PULL_STATE == 0 then
                PULL_RETURNING = false
                PULL_STATE = 2
            end
        else
            PULL_STATE = PULL_STATE+1 
            if PULL_STATE == 5 then
                PULL_RETURNING = true
                PULL_STATE = 3
            end
        end
    else
        if PULL_STARTED then
            return true
        end
    end

    PULL_STARTED = true
    if PULL_STATE < 4 then
        return core.OrderMoveToPosAndHold(botBrain, Booboo, path[PULL_STATE], false, true)
    else
        return core.OrderMoveToPosAndHold(botBrain, Booboo, path[4], false, true)
    end

    return false
end

behaviorLib.debugBehavior = {}
behaviorLib.debugBehavior["Utility"] = debugUtility
behaviorLib.debugBehavior["Execute"] = debugExecute
behaviorLib.debugBehavior["Name"] = "debug"
tinsert(behaviorLib.tBehaviors, behaviorLib.debugBehavior)


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
