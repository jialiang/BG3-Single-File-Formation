local isDebugMode = true
local isQueued = false

local function log(msg)
	if isDebugMode then
		print("[SingleFileFormation] " .. msg)
	end
end

local function isChainable(member)
	if Osi.IsDead(member) == 1 then
		return false
	end
	if Osi.HasActiveStatus(member, "DOWNED") == 1 then
		return false
	end
	if Osi.GetHitpoints(member) <= 0 then
		return false
	end
	if Osi.IsInForceTurnBasedMode(member) == 1 then
		return false
	end
	if Osi.CombatGetGuidFor(member) ~= nil then
		return false
	end
	if Osi.IsSpeakerReserved(member) == 1 then
		return false
	end

	local campRows = Osi.DB_PlayerInCamp:Get(member)
	if campRows and campRows[1] then
		return false
	end

	return true
end

local function refreshChain()
	if isQueued then
		return
	end
	isQueued = true

	Ext.OnNextTick(function()
		local ok, err = pcall(function()
			local t0 = Ext.Timer.MonotonicTime()

			local leaderRows = Osi.DB_Players:Get(Osi.GetHostCharacter())
			local leader = leaderRows and leaderRows[1] and leaderRows[1][1]
			log(leader and ("Leader: " .. leader) or "No leader found")

			local isLeaderChainable = leader and isChainable(leader)
			local chain = {}

			for _, row in pairs(Osi.DB_Players:Get(nil)) do
				local member = row[1]
				Osi.StopFollow(member)

				if
					isLeaderChainable
					and member ~= leader
					and isChainable(member)
					and Osi.InSamePartyGroup(member, leader) == 1
				then
					table.insert(chain, member)
				else
					log(member .. " not following anyone")
				end
			end

			if #chain > 0 then
				local distToLeader = {}

				for _, member in ipairs(chain) do
					distToLeader[member] = Osi.GetDistanceTo(leader, member)
				end

				table.sort(chain, function(a, b)
					return distToLeader[a] < distToLeader[b]
				end)

				for i, member in ipairs(chain) do
					if i == 1 then
						Osi.Follow(member, leader)
						log(member .. " follows " .. leader)
					else
						Osi.Follow(member, chain[i - 1])
						log(member .. " follows " .. chain[i - 1])
					end
				end
			end

			log("Took " .. (Ext.Timer.MonotonicTime() - t0) .. "ms")
		end)

		if not ok then
			log("Error: " .. tostring(err))
		else
			log("Done")
		end

		isQueued = false
	end)
end

Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(_)
	log("CombatStarted triggered")
	refreshChain()
end)

Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function(_)
	log("CombatEnded triggered")
	refreshChain()
end)

Ext.Osiris.RegisterListener("EnteredForceTurnBased", 1, "after", function(character)
	if Osi.IsPlayer(character) ~= 1 then
		return
	end

	log("EnteredForceTurnBased triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("LeftForceTurnBased", 1, "after", function(character)
	if Osi.IsPlayer(character) ~= 1 then
		return
	end

	log("LeftForceTurnBased triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("DetachedFromPartyGroup", 1, "after", function(character)
	log("DetachedFromPartyGroup triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("AttachedToPartyGroup", 1, "after", function(character)
	log("AttachedToPartyGroup triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("GainedControl", 1, "after", function(character)
	log("GainedControl triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(character)
	log("CharacterJoinedParty triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", function(character)
	log("CharacterLeftParty triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("TeleportedToCamp", 1, "after", function(character)
	log("TeleportedToCamp triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("TeleportedFromCamp", 1, "after", function(character)
	log("TeleportedFromCamp triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("HitpointsChanged", 2, "after", function(entity, _)
	if Osi.IsPlayer(entity) ~= 1 then
		return
	end

	log("HitpointsChanged triggered: " .. entity)
	refreshChain()
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(character, status, _, _)
	if status ~= "DOWNED" then
		return
	end

	log("StatusApplied (" .. status .. ") triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(character, status, _, _)
	if status ~= "DOWNED" then
		return
	end

	log("StatusRemoved (" .. status .. ") triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("Resurrected", 1, "after", function(character)
	log("Resurrected triggered: " .. character)
	refreshChain()
end)

Ext.Osiris.RegisterListener("DialogStarted", 2, "after", function(_, instanceID)
	if Osi.DialogGetNumberOfInvolvedPlayers(instanceID) <= 0 then
		return
	end

	log("DialogStarted triggered")
	refreshChain()
end)

Ext.Osiris.RegisterListener("DialogEnded", 2, "after", function(_, instanceID)
	if Osi.DialogGetNumberOfInvolvedPlayers(instanceID) <= 0 then
		return
	end

	log("DialogEnded triggered")
	refreshChain()
end)

print("[SingleFileFormation] Mod loaded.")
