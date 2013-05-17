local _G = getfenv(0)
local yogi = _G.object

yogi.heroName = "Hero_Yogi"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = yogi.core, yogi.behaviorLib

behaviorLib.StartingItems  = { "6 Item_HealthPotion"}
behaviorLib.LaneItems  = { "Item_EnhancedMarchers", "Item_Lightning1" } 
behaviorLib.MidItems  = { "Item_Lightning2", "Item_Evasion"}
behaviorLib.LateItems  = { "Item_Weapon3", "Item_FrostfieldPlate", "Item_Damage9"}


yogi.skills = {}
local skills = yogi.skills
local tinsert = _G.table.insert

yogi.tSkills ={
	0, 2, 0, 2, 0,
	2, 0, 1, 2, 1, 
	1, 1, 3, 3, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4
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
function yogi:SkillBuild()
 
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
        unitSelf:GetAbility( self.tSkills[i] ):LevelUp()
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
end
object.onthinkOld = object.onthink
object.onthink  = object.onthinkOverride
 
--------------------------------------
-- Heal at well utility override    --
--------------------------------------

local function HealAtWellLogicOverride(botBrain)
  
  local nHpPercent = core.unitSelf:GetHealthPercent()
  local nUtility = 0

  if nHpPercent < 0.2 then
	nUtility = 80
  end

  if nUtility = 0 then
	return defiler.HealAtWellUtilityOld(botBrain)
  end

  return nUtility

end
defiler.HealAtWellUtilityOld = behaviorLib.HealAtWellBehavior["Utility"]
behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellLogicOverride 
 
----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
--	BotEcho("Bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent     = object.oncombateventOverride
 
 
 
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
--
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


local function GetAttackDamageOnCreep(botBrain, unitCreepTarget)

	if not unitCreepTarget or not core.CanSeeUnit(botBrain, unitCreepTarget) then
		return nil
	end

	local unitSelf = core.unitSelf

	-- /Back to pool if rich
	-- gold=botBrain:GetGold()
	--	BotEcho(gold)
	--if gold>maxgold then
	--	BotEcho("Returning to well!")
	--	local wellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
	--	core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, wellPos, false)
	--end
	

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

	-- /Back to pool if rich
	--gold=botBrain:GetGold()
	--	BotEcho(gold)
	--if gold>maxgold then
	--	BotEcho("Returning to well!")
	--	local wellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
	--	core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, wellPos, false)
	--end	
	-- passive, Booboo and second skill, always up
	if skills.abilQ:CanActivate() then
		actionTaken = core.OrderAbility(botBrain, skills.abilQ)
	--	BotEcho("Booboo")
	end
	if skills.abilW:CanActivate() then
		actionTaken = core.OrderAbility(botBrain, skills.abilW)
	end


	
--------------------
--[[	local bDebugInfo = true
	core.tControllableUnits = botBrain:GetControllableUnits()
	if bDebugInfo then
		BotEcho("ControllableUnits:")
		Echo("AllControllableUnits\n{")	core.printGetTypeNameTable(core.tControllableUnits["AllUnits"]) Echo("}")
		Echo("InventoryUnits\n{")	core.printGetTypeNameTable(core.tControllableUnits["InventoryUnits"]) Echo("}")
	end
--]]


	local Booboo={}
	for key, unit2 in pairs(core.localUnits["AllyUnits"]) do
		if unit2:GetTypeName()=="Pet_Yogi_Ability1" then
			Booboo=unit2
		end
--[[		BotEcho(unit:GetTypeName())
		if unit:GetTypeName()=="Pet_Yogi_Ability1" then
			core.OrderMoveToPos(botBrain, unit, vecMoundMidTower, false) 
		end
--]]		
	end
--	local vecMoundMidTower = Vector3.Create(8650, 7950)
--	core.OrderMoveToPos(botBrain, Booboo, vecMoundMidTower, false) 

	local unitClosestHero = nil
	local nClosestHeroDistSq = 1100*1100 -- Not concerned if more than 900, since Booboo can't attack then, and their range not enough to harm. But predictive running....
	for id, unitHero in pairs(HoN.GetHeroes(core.enemyTeam)) do --HoN.GetHeroes(core.enemyTeam)
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
	if Booboo:GetHealthPercent()*100>35 then
--		BotEcho(Booboo:GetHealthPercent())
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
--[[
	if Booboo:GetHealthPercent()*100<35 then
		core.OrderMoveToPosAndHoldClamp(botBrain, Booboo, wellPos, false)
	elseif unitClosestHero~=nil then
--	if unitClosestHero~=nil then
		core.OrderAttack(botBrain, Booboo, unitClosestHero,false)
	else --lasthit. Now just move to character
		core.OrderMoveToPosAndHoldClamp(botBrain, Booboo, core.unitSelf:GetPosition(), false)
	end
--]]



















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
object.getCreepAttackTargetOld = behaviorLib.GetCreepAttackTarget
behaviorLib.GetCreepAttackTarget = GetCreepAttackTargetOverride
