local debug = true
local queued = false
local campState = {}
local turnBasedState = {}

local function log(msg)
    if debug then
        print("[SingleFileFormation] " .. msg)
    end
end

local function isChainable(member)
    if campState[member] then return false end
    if turnBasedState[member] then return false end
    if Osi.IsDead(member) == 1 then return false end
    if Osi.HasActiveStatus(member, "DOWNED") == 1 then return false end
    if Osi.CombatGetGuidFor(member) ~= nil then return false end
    if Osi.IsSpeakerReserved(member) == 1 then return false end

    return true
end

local function refreshChain()
    if queued then return end
    queued = true

    Ext.OnNextTick(function()
        local ok, err = pcall(function()
            local leaderRows = Osi.DB_Players:Get(Osi.GetHostCharacter())
            local leader = leaderRows and leaderRows[1] and leaderRows[1][1]
            log(leader and ("Leader: " .. leader) or "No leader found.")

            local isLeaderChainable = leader and isChainable(leader);
            local lastInChain = leader

            for _, row in pairs(Osi.DB_Players:Get(nil)) do
                local member = row[1]
                Osi.StopFollow(member)

                if isLeaderChainable
                    and member ~= leader
                    and isChainable(member)
                    and Osi.InSamePartyGroup(member, leader) == 1
                then
                    Osi.Follow(member, lastInChain)
                    log(member .. " follows " .. lastInChain)
                    lastInChain = member
                else
                    log(member .. " not following anyone")
                end
            end
        end)

        if not ok then
            log("Error: " .. tostring(err))
        else
            log("Done applying follows.")
        end

        queued = false
    end)
end

Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(_)
    log("CombatStarted triggered.")
    refreshChain()
end)

Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function(_)
    log("CombatEnded triggered.")
    refreshChain()
end)

Ext.Osiris.RegisterListener("EnteredForceTurnBased", 1, "after", function(character)
    if Osi.IsPlayer(character) ~= 1 then return end

    log("EnteredForceTurnBased triggered: " .. character)
    turnBasedState[character] = true
    refreshChain()
end)

Ext.Osiris.RegisterListener("LeftForceTurnBased", 1, "after", function(character)
    if Osi.IsPlayer(character) ~= 1 then return end

    log("LeftForceTurnBased triggered: " .. character)
    turnBasedState[character] = nil
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
    campState[character] = true
    refreshChain()
end)

Ext.Osiris.RegisterListener("TeleportedFromCamp", 1, "after", function(character)
    log("TeleportedFromCamp triggered: " .. character)
    campState[character] = nil
    refreshChain()
end)

Ext.Osiris.RegisterListener("HitpointsChanged", 2, "after", function(entity, percentage)
    if Osi.IsPlayer(entity) ~= 1 then return end

    if percentage > 0 then
        log("HitpointsChanged triggered: " .. entity .. " healed.")
        refreshChain()
    elseif Osi.GetHitpoints(entity) <= 0 then
        log("HitpointsChanged triggered: " .. entity .. " at 0 HP, stopping follow.")
        Osi.StopFollow(entity)
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(character, status, _, _)
    if status == "DOWNED" then
        log("StatusApplied (" .. status .. ") triggered: " .. character)
        refreshChain()
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(character, status, _, _)
    if status == "DOWNED" then
        log("StatusRemoved (" .. status .. ") triggered: " .. character)
        refreshChain()
    end
end)

Ext.Osiris.RegisterListener("Resurrected", 1, "after", function(character)
    log("Resurrected triggered: " .. character)
    refreshChain()
end)

Ext.Osiris.RegisterListener("DialogStarted", 2, "after", function(_, instanceID)
    if Osi.DialogGetNumberOfInvolvedPlayers(instanceID) > 0 then
        log("DialogStarted triggered")
        refreshChain()
    end
end)

Ext.Osiris.RegisterListener("DialogEnded", 2, "after", function(_, instanceID)
    if Osi.DialogGetNumberOfInvolvedPlayers(instanceID) > 0 then
        log("DialogEnded triggered")
        refreshChain()
    end
end)

print("[SingleFileFormation] Mod loaded.")
