function IsSiege(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionSiege" or unitType == "Creep_HellbourneSiege"
end
function IsRanged(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionRanged" or unitType == "Creep_HellbourneRanged"
end

function IsTower(unit)
  local unitType = unit:GetTypeName()
  return unitType == "Creep_LegionRanged" or unitType == "Creep_HellbourneRanged"
end

function GetArmorMultiplier(unit, magic)
  --return value of like 0.75 where armor would therefore be 25%
  --just multiply dmg with this value and you get final result
  -- needs changes... for if armor is below zero, is different algorithm then
  local magicReduc = 0
  if magic then
    magicReduc = unit:GetMagicArmor()
  else
    magicReduc = unit:GetArmor()
  end
  if magicReduc >= 0 then
    magicReduc = 1 - (magicReduc*0.06)/(1+0.06*magicReduc)
  else
    magicReduc = math.pow(0.94,math.abs(magicReduc)) - 1
  end
  return magicReduc
end

function closeToEnemyTowerDist(unit) -- returns pythagoras result , not something that is cubed
  local unitSelf = unit
  local myPos = unitSelf:GetPosition()
  local myTeam = unitSelf:GetTeam()

  local unitsInRange = HoN.GetUnitsInRadius(myPos, 3000, ALIVE + BUILDING)
  for _,unit in pairs(unitsInRange) do
    if unit and not(myTeam == unit:GetTeam()) then
      if unit:GetTypeName() == "Building_HellbourneTower" then
        return Vector3.Distance2D(myPos, unit:GetPosition())
      end
    end
  end
  return 3000
end

function GetHeroInRange(botBrain, myPos, radius)
  local unitsLocal = HoN.GetUnitsInRadius(myPos, radius, ALIVE + HERO)
  local vihunmq = nil

  for key,unit in pairs(unitsLocal) do
    if unit ~= nil and not (botBrain:GetTeam() == unit:GetTeam()) then
      vihunmq = unit
    end
  end

  if not vihunmq then
    return nil
  end
  return vihunmq
end

function heroIsInRange(botBrain,enemyCreep, range)
  local creepPos = enemyCreep:GetPosition()
  local unitsInRange = HoN.GetUnitsInRadius(creepPos, range, ALIVE + HERO)
  for _,unit in pairs(unitsInRange) do
    if unit and not (botBrain:GetTeam() == unit:GetTeam()) then
      return true
    end
  end
  return false
end

function AmountOfCreepsInRange(target, position, range, ally)
  if ally == nil then
    ally = false
  end
  local unitsInRange = HoN.GetUnitsInRadius(position, range, ALIVE + UNIT)
  local count = 0
  for _,unit in pairs(unitsInRange) do
    if ally and unit then
      count = count + 1
    elseif unit and not (target:GetTeam() == unit:GetTeam()) then
      count = count + 1
    end
  end
  return count
end

function shouldWeHarassHero(botBrain)
  local unitSelf = botBrain.core.unitSelf
  local myPos = unitSelf:GetPosition()
  local allyTeam = botBrain:GetTeam()
  local heroes = HoN.GetUnitsInRadius(myPos, 4000, ALIVE+HERO)
  for _,unit in pairs(heroes) do
    if unit and not (allyTeam == unit:GetTeam()) then
      -- core.BotEcho("asdasd: " .. tostring(unit:GetHealthPercent()))
      if unit:GetHealthPercent() < 0.4 then
        return false
      else
        return true
      end
    end
  end
end

function GetHeroToUlti(botBrain, myPos, radius)
  local unitsLocal = HoN.GetUnitsInRadius(myPos, radius, ALIVE + HERO)
  local vihunmq = nil

  for key,unit in pairs(unitsLocal) do
    if unit ~= nil and not (botBrain:GetTeam() == unit:GetTeam()) then
      vihunmq = unit
    end
  end

  if not vihunmq then
    return nil
  end
  return vihunmq
end

function AreThereMaxTwoEnemyUnitsClose(botBrain, myPos, range)
  local unitsLocal = HoN.GetUnitsInRadius(myPos, range, ALIVE + UNIT)
  local count = 0
  for _,unit in pairs(unitsLocal) do
    if unit and not (botBrain:GetTeam() == unit:GetTeam()) then
      if not IsSiege(unit) then
        count = count +1
      end
    end
  end

  return count <= 1
end

function getHeroWithLessHealthThan(botBrain, dmg, range, physical) -- checksAgainstMagicDmg, unless physical is true
  local magicDmg = true
  if physical then
    magicDmg = false
  end

  local unitSelf = botBrain.core.unitSelf
  local myPos = unitSelf:GetPosition()
  local getTargets = {}
  local unitsInRange = HoN.GetUnitsInRadius(myPos, range, ALIVE + HERO)
  for _,unit in pairs(unitsInRange) do
    if unit and not (ownTeam == unit:GetTeam()) then
      local nTargetDistance = Vector3.Distance2D(myPos, unit:GetPosition())
      local targetArmor = GetArmorMultiplier(unit,magicDmg)
      local targetHealth = unit:GetHealth()
      if targetHealth < dmg*targetArmor then
        if nTargetDistance < range then
          util = 100
          --witchslayer.UltiTarget = unit
        end
      end
    end
  end
end