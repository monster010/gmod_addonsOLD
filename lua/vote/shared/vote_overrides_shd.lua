if SERVER then
	--local totem = GetGlobalBool("ttt_totem", true)
	function TTTVote.GetVoteMessage(sender, text, teamchat) -- for backwards compatibility reasons
		local msg = string.lower(text)
		if string.sub(msg,1,8) == "!prozent" and GetRoundState() == ROUND_ACTIVE and sender:IsTerror() then
			if sender:GetNWInt("UsedVotes",0) <= 0 and sender:GetNWInt("PlayerVotes") - sender:GetNWInt("UsedVotes") >= 1 then
				net.Start("TTTVoteMenu")
				net.Send(sender)
				return false
			end
		elseif string.sub(msg,1,11) == "!votebeacon" and GetRoundState() != ROUND_WAIT and sender:IsTerror() then
			TTTVote.PlaceTotem(nil, sender)
			return false
		end
	end

	function TTTVote.AdjustSpeed(ply)
		if (GetRoundState() == ROUND_ACTIVE or GetRoundState() == ROUND_POST) then
			if TTTVote.AnyTotems then
				local Totem = ply:GetNWEntity("Totem", NULL)
				if IsValid(Totem) then
					local distance = Totem:GetPos():Distance(ply:GetPos())
					if distance >= 2000 then
						return math.Round(math.Clamp(math.Remap(distance,2000,5000,1,0),0.5,1),2)
					elseif distance <= 1000 then
						return 1.25
					elseif distance > 1000 and distance < 2000 then
						return 1
					end
				else
					return 0.75
				end
			else
				return 1
			end
		end
	end

	function TTTVote.Overrides() --Overriding functions that dont have hooks to modify

		local plymeta = FindMetaTable("Player")
		function plymeta:SetSpeed(slowed)
			local mul = TTTVote.AdjustSpeed(self) or 1
			if mul >= 1 and hook.Call("TTTPlayerSpeed", GAMEMODE, self, slowed) then
				mul = hook.Call("TTTPlayerSpeed", GAMEMODE, self, slowed)
			elseif mul < 1 and hook.Call("TTTPlayerSpeed", GAMEMODE, self, slowed) then
				mul = math.min(mul, hook.Call("TTTPlayerSpeed", GAMEMODE, self, slowed),100)
			end

			if slowed then
				self:SetWalkSpeed(120 * mul)
				self:SetRunSpeed(120 * mul)
				self:SetMaxSpeed(120 * mul)
			else
				self:SetWalkSpeed(220 * mul)
				self:SetRunSpeed(220 * mul)
				self:SetMaxSpeed(220 * mul)
			end
		end
	end
	--if totem then
		hook.Add("Initialize", "TTTTotemOverrideFunction", TTTVote.Overrides)
	--end
	hook.Add("PlayerSay","TTTVote", TTTVote.GetVoteMessage)
else
	--local totem = GetGlobalBool("ttt_totem", true)
	function TTTVote.VoteMakeCounter(pnl)
		pnl:AddColumn("Votes", function(ply)
				if ply:GetNWInt("VoteCounter",0) < 3 then
					return ply:GetNWInt("VoteCounter",0)
				elseif ply:GetNWInt("VoteCounter",0) >= 3 then
					return 3
				end
			end)
		--if totem then
			pnl:AddColumn("Totem", function(ply)
				if ply:GetNWEntity("Totem",NULL) != NULL then
					return "Ja"
				else
					return "Nein"
				end
			end)
		--end
	end

	function TTTVote.MakeVoteScoreBoardColor(ply)
		if ply:GetNWInt("VoteCounter",0) >= 3 then
			return Color(0,120,0)
		end
	end
	hook.Add("TTTScoreboardRowColorForPlayer", "TTTVoteColorScoreboard", TTTVote.MakeVoteScoreBoardColor)
	hook.Add("TTTScoreboardColumns", "TTTVoteCounteronScoreboard", TTTVote.VoteMakeCounter)
end
