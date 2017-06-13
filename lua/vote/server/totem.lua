-- if !TotemEnabled() then print("TTT Totem is not enabled on this Server, set ttt_totem to 1 to activate!") return end

function TTTGF.PlaceTotem(len, sender)
	local ply = sender
	if !IsValid(ply) or !ply:IsTerror() then return end
	if !ply:GetNWBool("CanSpawnTotem", true) or IsValid(ply:GetNWEntity("Totem",NULL)) or ply:GetNWBool("PlacedTotem") then
		net.Start("TTTTotem")
		net.WriteInt(1,8)
		net.Send(ply)
		return
	end
	if !ply:OnGround() then
		net.Start("TTTTotem")
		net.WriteInt(2,8)
		net.Send(ply)
		return
	end

	if ply:IsInWorld() then
		local totem = ents.Create("ttt_totem")
		if IsValid(totem) then
			totem:SetAngles(ply:GetAngles())

			totem:SetPos(ply:GetPos())
			totem:SetOwner(ply)
			totem:Spawn()

			ply:SetNWBool("CanSpawnTotem",false)
			ply:SetNWBool("PlacedTotem", true)
			ply:SetNWEntity("Totem",totem)
			net.Start("TTTTotem")
			net.WriteInt(3,8)
			net.Send(ply)
			TTTGF.TotemUpdate()
		end
	end
end

function TTTGF.HasTotem(ply)
	return IsValid(ply:GetNWEntity("Totem", NULL))
end

function TTTGF.TotemUpdate()
	if (GetRoundState() == ROUND_ACTIVE or GetRoundState() == ROUND_POST) and TTTGF.AnyTotems then

		TTTGF.totems = {}
		for k,v in pairs(player.GetAll()) do
			if (v:IsTerror() or !v:Alive()) and (TTTGF.HasTotem(v) or v:GetNWBool("CanSpawnTotem", false)) then
				table.insert(TTTGF.totems, v)
			end
		end

		if #TTTGF.totems >= 1 then
			TTTGF.AnyTotems = true
		else
			TTTGF.AnyTotems = false
			net.Start("TTTTotem")
			net.WriteInt(8,8)
			net.Broadcast()
			return
		end

		TTTGF.innototems = {}

		for k,v in pairs(TTTGF.totems) do
			if !v:GetEvil() then
				table.insert(TTTGF.innototems, v)
			end
		end

		if TTTGF.AnyTotems and #TTTGF.innototems == 0 then
			TTTGF.DestroyAllTotems()
		end
	end
end

function TTTGF.DestroyAllTotems()
	for k,v in pairs(ents.FindByClass("ttt_totem")) do
		v:FakeDestroy()
	end
	for k,v in pairs(player.GetAll()) do
		v:SetNWBool("CanSpawnTotem", false)
	end
	TTTGF.TotemUpdate()
 end

function TTTGF.TotemSuffer()
	if GetRoundState() == ROUND_ACTIVE and TTTGF.AnyTotems then
		for k,v in pairs(player.GetAll()) do
			if v:IsTerror() and !v:GetNWBool("PlacedTotem", false) and v.TotemSuffer then
				if v.TotemSuffer == 0 then
					v.TotemSuffer = CurTime() + 10
					v.DamageNotified = false
				elseif v.TotemSuffer <= CurTime() then
					if !v.DamageNotified then
						net.Start("TTTTotem")
						net.WriteInt(6,8)
						net.Send(v)
						v.DamageNotified = true
					end
					v:TakeDamage(1,v,v)
					v.TotemSuffer = CurTime() + 0.2
				end
			elseif v:IsTerror() and (v:GetNWBool("PlacedTotem", true) or !v.TotemSuffer) then
				v.TotemSuffer = 0
				v.DamageNotified = false
			end
		end
	end
end

function TTTGF.GiveTotemHunterCredits(ply,totem)
	LANG.Msg(ply, "credit_h_all", {num = 1})
	ply:AddCredits(1)
end

function TTTGF.ResetTotems()
	for k,v in pairs(player.GetAll()) do
		v:SetNWBool("CanSpawnTotem", true)
		v:SetNWBool("PlacedTotem", false)
		v:SetNWEntity("Totem", NULL)
		v.TotemSuffer = 0
		v.DamageNotified = false
		v.totemuses = 0
	end
	TTTGF.AnyTotems = true
end

function TTTGF.ResetSuffer()
	for k,v in pairs(player.GetAll()) do
		v.TotemSuffer = 0
	end
end

function TTTGF.DestroyTotem(ply)
	if GetRoundState() == ROUND_ACTIVE then
		ply:SetNWBool("CanSpawnTotem", false)
		ply.TotemSuffer = 0
		TTTGF.TotemUpdate()
	end
end

function TTTGF.TotemInit(ply)
		ply:SetNWBool("CanSpawnTotem", true)
		ply:SetNWBool("PlacedTotem", false)
		ply:SetNWEntity("Totem", NULL)
		ply.TotemSuffer = 0
		ply.DamageNotified = false
		ply.totemuses = 0
end


hook.Add("PlayerInitialSpawn", "TTTTotemInit", TTTGF.TotemInit)
net.Receive("TTTVotePlaceTotem", TTTGF.PlaceTotem)
hook.Add("TTTPrepareRound", "ResetValues", TTTGF.ResetTotems)
hook.Add("PlayerDeath", "TTTDestroyTotem", TTTGF.DestroyTotem)
hook.Add("Think", "TotemSuffer", TTTGF.TotemSuffer)
hook.Add("TTTBeginRound", "TTTTotemSync", TTTGF.TotemUpdate)
hook.Add("TTTBeginRound", "TTTTotemResetSuffer", TTTGF.ResetSuffer)
hook.Add("PlayerDisconnected", "TTTTotemSync", TTTGF.TotemUpdate)
