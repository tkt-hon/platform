local _G = getfenv(0)
local rampage = _G.object

rampage.heroName = "Hero_Rampage"

runfile 'bots/core_herobot.lua'
runfile 'bots/lib/rune_controlling/init.lua'

local core, behaviorLib = rampage.core, rampage.behaviorLib

local tinsert = _G.table.insert

behaviorLib.StartingItems = { "Item_RunesOfTheBlight", "Item_IronBuckler", "Item_LoggersHatchet" }
behaviorLib.LaneItems = { "Item_Marchers", "Item_EnhancedMarchers", "Item_Pierce"}
behaviorLib.MidItems = {  "Item_Shield2", "Item_PowerSupply", "Item_MysticVestments" }
behaviorLib.LateItems = { "Item_Immunity", "Item_DaemonicBreastplate" }

local CHARGE_NONE, CHARGE_STARTED, CHARGE_TIMER, CHARGE_WARP = 0, 1, 2, 3

rampage.charged = CHARGE_NONE

rampage.skills = {}
local skills = rampage.skills

rampage.tSkills = {
  1, 2, 1, 2, 1,
  3, 2, 2, 1, 0,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
function rampage:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilCharge == nil then
    skills.abilCharge = unitSelf:GetAbility(0)
    skills.abilSlow = unitSelf:GetAbility(1)
    skills.abilBash = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  self:SkillBuildOld()
end
rampage.SkillBuildOld = rampage.SkillBuild
rampage.SkillBuild = rampage.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function rampage:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
rampage.onthinkOld = rampage.onthink
rampage.onthink = rampage.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function rampage:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  if EventData.Type == "Ability" and EventData.InflictorName == "Ability_Rampage1" then
    self.charged = CHARGE_STARTED
  elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Timer" then
    if self.charged == CHARGE_STARTED then
      self.charged = CHARGE_NONE
    end
  elseif EventData.Type == "State" and EventData.StateName == "State_Rampage_Ability1_Warp" then
    self.charged = CHARGE_WARP
  elseif EventData.Type == "State_End" and EventData.StateName == "State_Rampage_Ability1_Warp" then
    self.charged = CHARGE_NONE
  elseif EventData.Type == "Death" then
    self.charged = CHARGE_NONE
  end
end
rampage.oncombateventOld = rampage.oncombatevent
rampage.oncombatevent = rampage.oncombateventOverride



local function KaiGetCreepAttackTargetOverride(botBrain, unitEnemyCreep, unitAllyCreep)
    local unitSelf = core.unitSelf
       
        --Get closest hero. We can make decisions based on this.
        local uClosestHero = nil
        local nClosestHeroDistSq = 2000*2000 -- more than 2000 and we are not concerned. 2000*2000
        for id, unitHero in pairs(HoN.GetHeroes(core.enemyTeam)) do
                if unitHero ~= nil then
                        if core.CanSeeUnit(botBrain, unitHero) and unitHero:GetTeam()~=team then
                                local nDistanceSq = Vector3.Distance2DSq(unitHero:GetPosition(), core.unitSelf:GetPosition())
                                if nDistanceSq < nClosestHeroDistSq then
                                        nClosestHeroDistSq = nDistanceSq
                                        uClosestHero = unitHero
                                end
                        end
                end
        end
       
        --addition is how much sooner to move towards creep. '30' is 30hp more than you can 1 hit kill it for.
        addition=30
        if (uClosestHero and uClosestHero:GetAttackType() ~= "melee") then --be more passive if opponent is ranged.
                addition=20
        end    
       
        if (uClosestHero and unitSelf:GetHealthPercent()*100<60 and Vector3.Distance2D(unitSelf:GetPosition(), uClosestHero:GetPosition())<uClosestHero:GetAttackRange()+150) then return nil end --too dangerous. Stay back.
    local nDamageAverage = unitSelf:GetFinalAttackDamageMin()+addition --make the hero go to the unit when it is 40 hp away, but too risky if enemy is ranged
        core.FindItems(botBrain)
    if core.itemHatchet then
        nDamageAverage = nDamageAverage * core.itemHatchet.creepDamageMul
    end
        if core.nDifficulty == core.nEASY_DIFFICULTY then
                nDamageAverage = nDamageAverage + 10
        end
    if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then --return enemy creep
        local nTargetHealth = unitEnemyCreep:GetHealth()
        if nDamageAverage >= nTargetHealth or core.teamBotBrain.nPushState==2 then
            return unitEnemyCreep
        end
    end
        if unitAllyCreep then
                local nTargetHealth = unitAllyCreep:GetHealth()
                if nDamageAverage >= nTargetHealth then
                        local bActuallyDeny = true
                        if core.teamBotBrain.nPushState~=2 and (core.nDifficulty ~= core.nEASY_DIFFICULTY or (core.bIsTutorial and core.bTutorialBehaviorReset == true and core.myTeam == HoN.GetHellbourneTeam())) then
                                return unitAllyCreep
                        end
                end
        end
    return nil
end
object.GetCreepAttackTargetOld = behaviorLib.GetCreepAttackTarget
behaviorLib.GetCreepAttackTarget = KaiGetCreepAttackTargetOverride

local function advancedThinkUtility(botBrain)
        return 95; --always ridiculously important. Though, this rarly returns true.
end
 
local function advancedThinkExecute(botBrain)
        local unitSelf = core.unitSelf
        local vecSelfPos = unitSelf:GetPosition()
        local vecWellPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()
        local distToWellSq=Vector3.Distance2DSq(vecSelfPos, vecWellPos)
        local bActionTaken=false
       
        --remove invalid hatchet item.
        if core.itemHatchet ~= nil and not core.itemHatchet:IsValid() then
                core.itemHatchet = nil
        end
        --hatchet
        if not bActionTaken and core.unitCreepTarget and core.itemHatchet and core.itemHatchet:CanActivate() and --can activate
          Vector3.Distance2DSq(unitSelf:GetPosition(), core.unitCreepTarget:GetPosition()) <= 600*600 and --in range of hatchet.
          unitSelf:GetBaseDamage()*(1-core.unitCreepTarget:GetPhysicalResistance())>core.unitCreepTarget:GetHealth() and --low enough hp, killable
          string.find(core.unitCreepTarget:GetTypeName(), "Creep") then-- viable creep (this makes it ignore minions etc, some of which aren't hatchetable.)
                bActionTaken=botBrain:OrderItemEntity(core.itemHatchet.object or core.itemHatchet, core.unitCreepTarget.object or core.unitCreepTarget, false)--use hatchet.
        end
       
        return bActionTaken
end
behaviorLib.advancedThink = {}
behaviorLib.advancedThink["Utility"] = advancedThinkUtility
behaviorLib.advancedThink["Execute"] = advancedThinkExecute
behaviorLib.advancedThink["Name"] = "advancedThink"
tinsert(behaviorLib.tBehaviors, behaviorLib.advancedThink)



local function ChargeTarget(botBrain, unitSelf, abilCharge)
  local tEnemyHeroes = HoN.GetHeroes(core.enemyTeam)
  local utility = 0
  local unitTarget = nil
  local nTarget = 0
  for nUID, unit in pairs(tEnemyHeroes) do
    if core.CanSeeUnit(botBrain, unit) and unit:IsAlive() and (not unitTarget or unit:GetHealth() < unitTarget:GetHealth()) then
      unitTarget = unit
      nTarget = nUID
    end
  end
  if unitTarget then
    local damageLevels = {100,140,180,220}
    local chargeDamage = damageLevels[abilCharge:GetLevel()]
    local estimatedHP = unitTarget:GetHealth() - chargeDamage
    if estimatedHP < 200 then
      utility = 20
    end
    if unitTarget:GetManaPercent() < 30 then
      utility = utility + 5
    end
    local level = unitTarget:GetLevel()
    local ownLevel = unitSelf:GetLevel()
    if level < ownLevel then
      utility = utility + 5 * (ownLevel - level)
    else
      utility = utility - 10 * (ownLevel - level)
    end
    local vecTarget = unitTarget:GetPosition()
    for nUID, unit in pairs(tEnemyHeroes) do
      if nUID ~= nTarget and core.CanSeeUnit(botBrain, unit) and Vector3.Distance2DSq(vecTarget, unit:GetPosition()) < (500 * 500) then
        utility = utility - 5
      end
    end
  end
  return unitTarget, utility
end

local function ChargeUtility(botBrain)
  local abilCharge = skills.abilCharge
  local unitSelf = core.unitSelf
  if rampage.charged ~= CHARGE_NONE then
    return 9999
  end
  if not abilCharge:CanActivate() then
    return 0
  end
  local unitTarget, utility = ChargeTarget(botBrain, unitSelf, abilCharge)
  if unitTarget then
    rampage.chargeTarget = unitTarget
    return utility
  end
  return 0
end

local function ChargeExecute(botBrain)
  local bActionTaken = false
  if botBrain.charged ~= CHARGE_NONE then
    return true
  end
  if not rampage.chargeTarget then
    return false
  end
  local abilCharge = skills.abilCharge
  if abilCharge:CanActivate() then
    bActionTaken = core.OrderAbilityEntity(botBrain, abilCharge, rampage.chargeTarget)
  end
  return bActionTaken
end

local ChargeBehavior = {}
ChargeBehavior["Utility"] = ChargeUtility
ChargeBehavior["Execute"] = ChargeExecute
ChargeBehavior["Name"] = "Charge like a boss"
tinsert(behaviorLib.tBehaviors, ChargeBehavior)
