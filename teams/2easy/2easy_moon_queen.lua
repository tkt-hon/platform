local _G = getfenv(0)
local moonqueen = _G.object

runfile 'bots/core_herobot.lua'

local core, behaviorLib, eventsLib, metadata, skills = moonqueen.core, moonqueen.behaviorLib, moonqueen.eventsLib, moonqueen.metadata, moonqueen.skills

local ipairs, pairs, tinsert, tremove = _G.ipairs, _G.pairs, _G.table.insert, _G.table.remove
local floor, sin, random = _G.math.floor, _G.math.sin, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

--local SteamBootsLib = moonqueen.SteamBootsLib

BotEcho(' loading Moon Queen')

-----------------------
-- bot "global" vars --
-----------------------

--To keep track status of 2nd skill
moonqueen.bouncing = true
moonqueen.auraState = true
--bounce "resets" when you die to keep track when you respawn
moonqueen.alive = true

--To keep track day/night cycle
moonqueen.isDay = true

--Constants
moonqueen.heroName = 'Hero_Krixi'
behaviorLib.diveThreshold = 85

-- skillbuild table, 0=beam, 1=bounce, 2=aura, 3=ult, 4=attri
moonqueen.tSkills = {
  2, 0, 0, 1, 0,
  3, 0, 2, 2, 1,
  3, 2, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4,
}

--   item buy order.
behaviorLib.StartingItems  = {"2 Item_DuckBoots", "2 Item_MinorTotem", "Item_HealthPotion", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems  = {"Item_Marchers", "Item_HelmOfTheVictim", "Item_Steamboots"}
behaviorLib.MidItems  = {"Item_Sicarius", "Item_WhisperingHelm", "Item_Immunity"}
behaviorLib.LateItems  = {"Item_ManaBurn2", "Item_LifeSteal4", "Item_Evasion"}

--Steamboots defaults to agi
--SteamBootsLib.setAttributeBonus("agi")

------------------------------
--     skills               --
------------------------------
-- @param: none
-- @return: none
function moonqueen:SkillBuild()
  core.VerboseLog("skillbuild()")

  -- takes care at load/reload, <name_#> to be replaced by some convinient name.
  local unitSelf = self.core.unitSelf
  if skills.moonbeam == nil then
    skills.moonbeam = unitSelf:GetAbility(0)
    skills.bounce = unitSelf:GetAbility(1)
    skills.aura = unitSelf:GetAbility(2)
    skills.ult = unitSelf:GetAbility(3)
    skills.abilAttributeBoost = unitSelf:GetAbility(4)
  end
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local nlev = unitSelf:GetLevel()
  local nlevpts = unitSelf:GetAbilityPointsAvailable()
  for i = nlev, nlev+nlevpts do
    unitSelf:GetAbility( moonqueen.tSkills[i] ):LevelUp()

    --initialy set aura and bounce to heroes only
    if i == 1 then
      self:toggleAura(false)
    end
    if i == 4 then
      self:toggleBounce(false)
    end
  end
end

---------------------------------------
-- Find geo, shrunken, rage and helm --
---------------------------------------
local function funcFindItemsOverride(botBrain)
  moonqueen.FindItemsOld(botBrain)
  if core.itemGeometer ~= nil and not core.itemGeometer:IsValid() then
    core.itemGeometer = nil
  end
  if core.itemShrunkenHead ~= nil and not core.itemShrunkenHead:IsValid() then
    core.itemShrunkenHead = nil
  end
  if core.itemSymbolofRage ~= nil and not core.itemSymbolofRage:IsValid() then
    core.itemSymbolofRage = nil
  end
  if core.itemWhisperingHelm ~= nil and not core.itemWhisperingHelm:IsValid() then
    core.itemWhisperingHelm = nil
  end

  local inventory = core.unitSelf:GetInventory(true)
  for slot = 1, 6, 1 do
    local curItem = inventory[slot]
    if curItem ~= nil then
      if core.itemGeometer == nil and not curItem:IsRecipe() and curItem:GetName() == "Item_ManaBurn2" then
        core.itemGeometer = core.WrapInTable(curItem)
      elseif core.itemShrunkenHead == nil and not curItem:IsRecipe() and curItem:GetName() == "Item_Immunity" then
        core.itemShrunkenHead = core.WrapInTable(curItem)
      elseif core.itemSymbolofRage == nil and curItem:GetName() == "Item_LifeSteal4" then
        core.itemSymbolofRage = core.WrapInTable(curItem)
      elseif core.itemWhisperingHelm == nil and curItem:GetName() == "Item_WhisperingHelm" then
        core.itemWhisperingHelm = core.WrapInTable(curItem)
      end
    end
  end
end

moonqueen.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

---------------------------
--    onthink override   --
-- Called every bot tick --
---------------------------
function moonqueen:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  local unitSelf = core.unitSelf
  local heroPos = unitSelf:GetPosition()
  if (unitSelf:IsAlive() and core.localUnits~=nil)then
    if not moonqueen.alive then
      --To keep track status of 2nd skill
      moonqueen.alive = true
      moonqueen.bouncing = true
      self:toggleBounce(false)
    end

    -- Keep illus near
    --local heroPos = unitSelf:GetPosition()
    --for _, illu in pairs(IlluLib.my()) do
    --if Vector3.Distance2DSq(illu:GetPosition(), heroPos) > 400*400 then
    --core.OrderMoveToPos(self, illu, heroPos, false)
    --end
    --end
  end

  if not unitSelf:IsAlive() then
    --To keep track status of 2nd skill
    moonqueen.alive = false
  end

  --keep track of day/night only to say something stupid in all chat
  local time = HoN.GetMatchTime() --This is time since the 0:00 mark

  if time ~= 0 then
    local day = math.floor(time/(7.5*60*1000)) % 2
    --BotEcho(day)

    if day == 0 and not moonqueen.isDay then
      --Good morning
      moonqueen.isDay = true
    elseif day == 1 and moonqueen.isDay then
      --gnight
      moonqueen.isDay = false
      if random(5) == 1 then --math.random(upper) generates integer numbers between 1 and upper.
        local randomMessageId = random(#core.nightMessages)
        core.AllChat(core.nightMessages[randomMessageId])
      end
    end
  end

end
moonqueen.onthinkOld = moonqueen.onthink
moonqueen.onthink 	= moonqueen.onthinkOverride

---------------------------
-- Togle aura and bounce --
---------------------------
local function PushExecuteOverride(botBrain)
  botBrain:toggleBounce(true)
  botBrain:toggleAura(true)
  --	SteamBootsLib.setAttributeBonus("agi")
  moonqueen.PushExecuteOld(botBrain)
end
moonqueen.PushExecuteOld = behaviorLib.PushBehavior["Execute"]
behaviorLib.PushBehavior["Execute"] = PushExecuteOverride

function behaviorLib.newPositionSelfExecute(botBrain)
  botBrain:toggleBounce(false)
  botBrain:toggleAura(false)
  return behaviorLib.oldPositionSelfExecute(botBrain)
end
behaviorLib.oldPositionSelfExecute = behaviorLib.PositionSelfBehavior["Execute"]
behaviorLib.PositionSelfBehavior["Execute"] = behaviorLib.newPositionSelfExecute

----------------------------
-- oncombatevent override --
----------------------------
--Bonuses
moonqueen.geometerUseBonus = 15
moonqueen.ultUseBonus = 65
moonqueen.beamUseBonus = 5
moonqueen.SymbolofRageUseBonus = 50
function moonqueen:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  local addBonus = 0
  if EventData.Type == "Ability" then
    if EventData.InflictorName == "Ability_Krixi1" then
      addBonus = addBonus + moonqueen.beamUseBonus
    elseif EventData.InflictorName == "Ability_Krixi4" then
      addBonus = addBonus + moonqueen.ultUseBonus
    end
  elseif EventData.Type == "Item" then
    if core.itemGeometer ~= nil and EventData.InflictorName == core.itemGeometer:GetName() then
      addBonus = addBonus + moonqueen.geometerUseBonus
    elseif EventData.InflictorName == "Item_LifeSteal4" then
      addBonus = addBonus + moonqueen.SymbolofRageUseBonus
    end
  end

  if addBonus > 0 then
    core.DecayBonus(self)
    core.nHarassBonus = core.nHarassBonus + addBonus
  end
end
moonqueen.oncombateventOld = moonqueen.oncombatevent
moonqueen.oncombatevent 	= moonqueen.oncombateventOverride

----------------------------
-- Retreat override --
----------------------------
-- Use geo and set boots to str
function behaviorLib.RetreatFromThreatExecuteOverride(botBrain)
  --SteamBootsLib.setAttributeBonus("str")
  bActionTaken = false
  if core.NumberElements(core.localUnits["EnemyHeroes"]) > 0 then
    if core.itemGeometer and core.itemGeometer:CanActivate() then
      bActionTaken = core.OrderItemClamp(botBrain, unitSelf, core.itemGeometer, false, false)
    end
  end

  if not bActionTaken then
    behaviorLib.RetreatFromThreatExecuteOld(botBrain)
  end
end
behaviorLib.RetreatFromThreatExecuteOld = behaviorLib.RetreatFromThreatBehavior["Execute"]
behaviorLib.RetreatFromThreatBehavior["Execute"] = behaviorLib.RetreatFromThreatExecuteOverride

----------------------------------
-- customharassutility override --
----------------------------------
-- Extra value from spells and geo

moonqueen.moonbeamUpBonus = 5
moonqueen.ultUpBonus = 20
moonqueen.geometerUpBonus = 5
local function CustomHarassUtilityFnOverride(hero)
  local val = 0

  if skills.moonbeam:CanActivate() then
    val = val + moonqueen.moonbeamUpBonus
  end

  if skills.ult:CanActivate() then
    val = val + moonqueen.ultUpBonus
  end

  if core.itemGeometer ~= nil then
    if core.itemGeometer:CanActivate() then
      val = val + moonqueen.geometerUpBonus
    end
  end
  -- Less mana less aggerssion
  val = val + (core.unitSelf:GetManaPercent() - 0.65) * 30
  return val

end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

---------------------
-- Harass Behavior --
---------------------
moonqueen.geometerUseThreshold = 55
moonqueen.moonbeamThreshold = 35
moonqueen.ultTheresholds = {95, 85, 75}
local function HarassHeroExecuteOverride(botBrain)
  --SteamBootsLib.setAttributeBonus("agi")
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return false --Target is invalid, move on to the next behavior
  end

  if not core.CanSeeUnit(botBrain, unitTarget) then
    return moonqueen.harassExecuteOld(botBrain)
  end

  --some vars
  local unitSelf = core.unitSelf
  local vecMyPosition = unitSelf:GetPosition()

  local vecTargetPosition = unitTarget:GetPosition()
  local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)

  local nLastHarassUtility = behaviorLib.lastHarassUtil
  local bCanSee = core.CanSeeUnit(botBrain, unitTarget)

  local bActionTaken = false

  local targetMagicImmune = moonqueen.IsMagicImmune(unitTarget)

  ----------------------------------------------------------------------------

  if not bActionTaken then
    if skills.moonbeam:CanActivate() and nLastHarassUtility > moonqueen.moonbeamThreshold and not targetMagicImmune then
      bActionTaken = core.OrderAbilityEntity(botBrain, skills.moonbeam, unitTarget)
    end
  end

  if not bActionTaken then
    if nLastHarassUtility > moonqueen.geometerUseThreshold and core.itemGeometer and core.itemGeometer:CanActivate() then
      bActionTaken = core.OrderItemClamp(botBrain, unitSelf, core.itemGeometer, false, false)
    end
  end

  if not bActionTaken and bCanSee and not targetMagicImmune then
    --at higher levels this overpowers ult behavior with lastHarassUtil like 150
    if skills.ult:CanActivate() and nLastHarassUtility > moonqueen.ultTheresholds[skills.ult:GetLevel()] and nTargetDistanceSq < 600 * 600 then
      bActionTaken = behaviorLib.ultBehavior["Execute"](botBrain)
    end
  end

  for _, illu in pairs(IlluLib.myIllusions()) do
    core.OrderAttack(botBrain, illu, unitTarget)
  end

  if not bActionTaken then
    if core.itemSymbolofRage and core.itemSymbolofRage:CanActivate() and unitSelf:GetHealthPercent() < 0.7 then
      botBrain:OrderItem(core.itemSymbolofRage.moonqueen)
    end
    return moonqueen.harassExecuteOld(botBrain)
  end
end
moonqueen.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

----------------------
-- Custom behaviors --
----------------------

-------------------------------------------------------------------
--Use ult when there are good change and harashero is too afraid --
-------------------------------------------------------------------
function behaviorLib.UltimateUtility(botBrain)

  if not skills.ult:CanActivate() then
    return 0
  end

  local selfPos = core.unitSelf:GetPosition()

  --range of ult is 700, check 800 cause we are going to move during ult
  --check heroes in range 600, they try to run
  local unitlist = HoN.GetUnitsInRadius(selfPos, 800, core.UNIT_MASK_UNIT + core.UNIT_MASK_HERO + core.UNIT_MASK_ALIVE)
  local localUnits = {}
  core.SortUnitsAndBuildings(unitlist, localUnits, true)

  local enemyheroes = {}

  for _, hero in pairs(localUnits["enemyHeroes"]) do
    if Vector3.Distance2DSq(selfPos, hero:GetPosition()) < 600*600 and not moonqueen.IsMagicImmune(hero) then
      tinsert(enemyheroes, hero)
    end
  end

  if core.NumberElements(enemyheroes) == 0 then
    return 0
  end

  local utilityvalue = 0
  if core.NumberElements(localUnits["tEnemyUnits"]) <= skills.ult:GetLevel() + 1 then
    utilityvalue = utilityvalue + 30
  end
  if core.NumberElements(localUnits["tEnemyUnits"]) == core.NumberElements(enemyheroes) then
    utilityvalue = utilityvalue + 40
  elseif core.NumberElements(localUnits["tEnemyUnits"]) < core.NumberElements(enemyheroes) *2 then
    utilityvalue = utilityvalue + 20
  end
  return utilityvalue * core.unitSelf:GetHealthPercent()
end

--press R to kill
function behaviorLib.UltimateExecute(botBrain)
  bActionTaken = core.OrderAbility(botBrain, skills.ult)

  if core.itemShrunkenHead and bActionTaken then
    botBrain:OrderItem(core.itemShrunkenHead.moonqueen)
  end
  return bActionTaken
end

behaviorLib.ultBehavior = {}
behaviorLib.ultBehavior["Utility"] = behaviorLib.UltimateUtility
behaviorLib.ultBehavior["Execute"] = behaviorLib.UltimateExecute
behaviorLib.ultBehavior["Name"] = "mq Ultimate"
tinsert(behaviorLib.tBehaviors, behaviorLib.ultBehavior)

------------------------------------------------
-- Behavior to break channels and remove pots --
------------------------------------------------
behaviorLib.enemyToStun = nil
function behaviorLib.stunUtility(botBrain)
  if not skills.moonbeam:CanActivate() then
    return 0
  end

  for _,enemy in pairs(core.localUnits["EnemyHeroes"]) do
    if enemy:IsChanneling() or enemy:HasState("State_ManaPotion") or enemy:HasState("State_HealthPotion")
      or enemy:HasState("State_Bottle") or enemy:HasState("State_PowerupRegen") then
      behaviorLib.enemyToStun = enemy
      return 75
    end
  end
  return 0
end

function behaviorLib.stunExecute(botBrain)
  return core.OrderAbilityEntity(botBrain, skills.moonbeam, behaviorLib.enemyToStun)
end

behaviorLib.stunBehavior = {}
behaviorLib.stunBehavior["Utility"] = behaviorLib.stunUtility
behaviorLib.stunBehavior["Execute"] = behaviorLib.stunExecute
behaviorLib.stunBehavior["Name"] = "stun"
tinsert(behaviorLib.tBehaviors, behaviorLib.stunBehavior)

-----------------------------------------------
--                  Misc                     --
-----------------------------------------------

---------------------------------
--Helppers for bounce and aura --
---------------------------------
function moonqueen:toggleAura(state)
  if moonqueen.getAuraState() == state or not skills.aura:CanActivate() then
    return false
  end
  local success = core.OrderAbility(self, skills.aura)
  if success then
    moonqueen.auraState = not moonqueen.auraState
  end
  return true
end

function moonqueen:toggleBounce(state)
  if moonqueen.getBounceState() == state or not skills.bounce:CanActivate() then
    return false
  end

  local success = core.OrderAbility(self, skills.bounce)
  if success then
    moonqueen.bouncing = not moonqueen.bouncing
  end
  return true
end

--true when target is "all" false when heroes only
function moonqueen.getAuraState()
  if skills.aura:GetLevel() == 0 then
    return false
  end
  return moonqueen.auraState
end

function moonqueen.getBounceState()
  if skills.bounce:GetLevel() == 0 then
    return false
  end
  return moonqueen.bouncing
end

--------------------
-- Magic immunity --
--------------------
function moonqueen.IsMagicImmune(unit)
  local states = { "State_Item3E", "State_Predator_Ability2", "State_Jereziah_Ability2", "State_Rampage_Ability1_Self", "State_Rhapsody_Ability4_Buff", "State_Hiro_Ability1" }
  for _, state in ipairs(states) do
    if unit:HasState(state) then
      return true
    end
  end
  return false
end

--------------
-- Messages --
--------------
core.tKillChatKeys={
  "Shot by the Moon.",
  "Harvest moon.",
  "Feel the power of the moon.",
  "Take one and pass it on.",
  "One to the other."
}

core.tDeathChatKeys = {
  "Carried away by a moonlight shadow.",
}

core.tRespawnChatKeys = {
  "By the moonlight.",
  "Moonlight guide me."
}

core.nightMessages = {
  "Oh full moon tonight",
  "Blue moon rises",
  "Under the moon."
}

BotEcho('finished loading Moon Queen')
