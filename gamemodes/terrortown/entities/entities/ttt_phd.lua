if SERVER then
  AddCSLuaFile()
  resource.AddWorkshop("")
  resource.AddFile("materials/vgui/ttt/icon_phd.vmt")
  resource.AddFile("materials/vgui/ttt/perks/hud_phd.png")
  util.AddNetworkString("DrinkingthePHD")
end

if CLIENT then
  -- feel for to use this function for your own perk, but please credit Zaratusa
  -- your perk needs a "hud = true" in the table, to work properly
  local defaultY = ScrH() / 2 + 20
  local function getYCoordinate(currentPerkID)
    local amount, i, perk = 0, 1
    while (i < currentPerkID) do
      perk = GetEquipmentItem(LocalPlayer():GetRole(), i)
      if (istable(perk) and perk.hud and LocalPlayer():HasEquipmentItem(perk.id)) then
        amount = amount + 1
      end
      i = i * 2
    end

    return defaultY - 80 * amount
  end

  local yCoordinate = defaultY
  -- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
  hook.Add("TTTBoughtItem", "TTTPHD", function()
      if (LocalPlayer():HasEquipmentItem(EQUIP_PHD)) then
        yCoordinate = getYCoordinate(EQUIP_PHD)
      end
    end)
  local material = Material("vgui/ttt/perks/hud_phd.png")
  hook.Add("HUDPaint", "TTTPHD", function()
      if LocalPlayer():GetNWBool("PHDActive", false) and LocalPlayer():HasEquipmentItem(EQUIP_PHD) then
        surface.SetMaterial(material)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(20, yCoordinate, 64, 64)
      end
    end)

end

function getNextFreeID()
  local freeID, i = 1, 1
  while (freeID == 1) do
    if (!GetEquipmentItem(ROLE_DETECTIVE, i)
      and !GetEquipmentItem(ROLE_TRAITOR, i)) then
      freeID = i
    end
    i = i * 2
  end

  return freeID
end

EQUIP_PHD = getNextFreeID()

local PHD = {
  id = EQUIP_PHD,
  loadout = false,
  type = "item_passive",
  material = "vgui/ttt/icon_phd",
  name = "PHD Flopper",
  desc = "PHD Flopper Perk.\nAutomatically drinks perk to become \nimmune to fall damage,\nexplosion damage, and create an explosion\nwhere you land.",
  hud = true
}

local detectiveCanUse = CreateConVar("ttt_phd_det", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Detective be able to use the PHD.")
local traitorCanUse = CreateConVar("ttt_phd_tr", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should the Traitor be able to use the PHD.")

if (detectiveCanUse:GetBool()) then
  table.insert(EquipmentItems[ROLE_DETECTIVE], PHD)
end
if (traitorCanUse:GetBool()) then
  table.insert(EquipmentItems[ROLE_TRAITOR], PHD)
end

if SERVER then

  local plymeta = FindMetaTable("Player")
  function plymeta:CanDrinkPHD()
    if IsValid(self) and self:IsTerror() then
      if IsValid(self:GetActiveWeapon()) and (self:GetActiveWeapon():GetClass() == "ttt_perk_juggernog" or self:GetActiveWeapon():GetClass() == "ttt_perk_staminup") then
        timer.Create("MakethePHDDrink",0.5,0, function()
            if IsValid(self) and IsValid(self:GetActiveWeapon()) and (self:GetActiveWeapon():GetClass() != "ttt_perk_juggernog" and self:GetActiveWeapon():GetClass() != "ttt_perk_staminup") then
              self:GivethePHD()
              timer.Remove("MakethePHDDrink")
            end
          end)
      else
        self:GivethePHD()
      end
    end
  end

  function plymeta:GivethePHD()
    self:Give("ttt_perk_phd")
    self:SelectWeapon("ttt_perk_phd")
    if self:HasWeapon("ttt_perk_phd") then
      self:GetWeapon("ttt_perk_phd"):DrinkTheBottle()
    elseif IsValid(self) and !self:HasWeapon("ttt_perk_phd") then
      self:CanDrinkPHD()
    end
  end

  hook.Add("TTTOrderedEquipment", "TTTPHD", function(ply, equipment, is_item)
      if is_item == EQUIP_PHD then
        ply:CanDrinkPHD()
      end
    end)
    hook.Add("TTTPrepareRound", "TTTPHDResettin", function()
      timer.Remove("MakethePHDDrink")
    end)
end

if CLIENT then
  hook.Add("TTTBodySearchEquipment", "PHDCorpseIcon", function(search, eq)
      search.eq_phd = util.BitSet(eq, EQUIP_PHD)
    end )

  hook.Add("TTTBodySearchPopulate", "PHDCorpseIcon", function(search, raw)
      if (!raw.eq_phd) then
        return end

        local highest = 0
        for _, v in pairs(search) do
          highest = math.max(highest, v.p)
        end

        search.eq_phd = {img = "vgui/ttt/icon_phd", text = "They drunk a PHD Flopper.", p = highest + 1}
      end )
  end
