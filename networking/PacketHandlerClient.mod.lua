local NetworkManager = require("NetworkManager")
local Packet = require("packets/Packet.mod")

local HelloPacket = require("packets/HelloPacket.mod")
local PeerStatusPacket = require("packets/PeerStatusPacket.mod")
local CharacterStatePacket = require("packets/runtime/CharacterStatePacket.mod")
local SyncPacket = require("packets/SyncPacket.mod")
local CharacterSyncPacket = require("packets/runtime/CharacterSyncPacket.mod")
local AuthPacket = require("packets/AuthPacket.mod")
local CharacterRequestPacket = require("packets/runtime/CharacterRequestPacket.mod")

local Utils = require("../utils/Utils.mod")
local Character = require("../character/Character")

local MapManagerM = require("../map_system/MapManager")
local MapManager = gdglobal("MapManager") :: MapManagerM.MapManager

local AppearancesM = require("../character/appearance/Appearances")
local Appearances = gdglobal("Appearances") :: AppearancesM.Appearances

local PacketHandlerClient = {}

function PacketHandlerClient.OnConnectedToServer(nm: NetworkManager.NetworkManager)
    -- HANDSHAKE: 1) Client HELLO
    nm.peerData[1] = {
        state = NetworkManager.PeerState.CONNECTED,
        identity = "SERVER",
        successfulPings = 0,
        rtt = 0,
    }

    nm.peerData[1].state = NetworkManager.PeerState.CONNECTED

    local hello = HelloPacket.client.new(Utils.version, nm.identity)
    nm:SendPacket(1, hello)

    nm:DisconnectTimeout(1, function()
        return nm.peerData[1].state == NetworkManager.PeerState.CONNECTED
    end)
end

PacketHandlerClient[HelloPacket.server.NAME] = function(nm: NetworkManager.NetworkManager, packet: Packet.Packet)
    -- HANDSHAKE: 3) Client AUTH
    local peerData = nm.peerData[1]

    if peerData.state ~= NetworkManager.PeerState.CONNECTED then
        nm:DisconnectWithReason(1, "Incorrect stage for handshake begin")
    end

    local hp = packet :: HelloPacket.HelloPacketServer

    local map = MapManager.maps[hp.mapId]

    if not map then
        nm:DisconnectWithReason(1, "Client doesn't have requested map")
        return
    end

    if map.manifest.version ~= hp.mapVersion then
        nm:DisconnectWithReason(1, "Client map version mismatch")
        return
    end

    if map.hash ~= hp.mapHash then
        nm:DisconnectWithReason(1, "Client map hash mismatch")
        return
    end

    MapManager:Load(hp.mapId)

    local auth = AuthPacket.client.new()

    if bit32.band(hp.authType, AuthPacket.AuthType.PASSWORD) ~= 0 then
        auth.password = nm.password
    end

    nm:SendPacket(1, auth)

    peerData.state = NetworkManager.PeerState.AUTH
    nm:DisconnectTimeout(1, function()
        return peerData.state == NetworkManager.PeerState.AUTH
    end)
end

PacketHandlerClient[PeerStatusPacket.server.NAME] = function(nm: NetworkManager.NetworkManager, packet: Packet.Packet)
    local peerData = nm.peerData[1]
    local psp = packet :: PeerStatusPacket.PeerStatusPacket

    if psp.status == PeerStatusPacket.PeerStatus.JOIN then
        if psp.peer == nm.peer:GetUniqueId() then
            -- HANDSHAKE: 5) End
            if peerData.state ~= NetworkManager.PeerState.AUTH then
                nm:DisconnectWithReason(1, "Incorrect stage for join status")
            end

            peerData.state = NetworkManager.PeerState.JOINED
            nm:Log(`successfully joined as {psp.identity}`)

            local charReq = CharacterRequestPacket.client.new(CharacterStatePacket.CharacterStateUpdateType.SPAWN)
            charReq.appearance = Appearances.current

            nm:SendPacket(1, charReq)
        else
            nm:Log(`peer {psp.peer} joined as {psp.identity}`)
            nm.peerData[psp.peer] = {
                state = NetworkManager.PeerState.JOINED,
                identity = psp.identity,
                successfulPings = 0,
                rtt = 0,
            }
        end
    else
        if psp.peer == nm.peer:GetUniqueId() then
            return
        end

        nm:Log(`peer {psp.peer} ({psp.identity}) left`)
        assert(MapManager.currentRuntime).players:DeleteCharacter(psp.peer)
        nm.peerData[psp.peer] = nil
    end
end

PacketHandlerClient[CharacterStatePacket.server.NAME] = function(nm: NetworkManager.NetworkManager, packet: Packet.Packet)
    -- The character will be synced anyway; errors may occur if packets sent before sync
    if nm.peerData[1].state < NetworkManager.PeerState.SYNCED then
        return
    end

    local stu = packet :: CharacterStatePacket.CharacterStatePacket

    local characterManager = assert(MapManager.currentRuntime).players

    if stu.type == CharacterStatePacket.CharacterStateUpdateType.SPAWN then
        local peer = if stu.peer == nm.peer:GetUniqueId() then nil else stu.peer
        characterManager:SpawnCharacter(stu.appearance, peer, stu.transform)
    elseif stu.type == CharacterStatePacket.CharacterStateUpdateType.APPEARANCE then
        characterManager:UpdateAppearance(stu.peer, assert(stu.appearance))
    elseif stu.type == CharacterStatePacket.CharacterStateUpdateType.MOVEMENT then
        characterManager:ProcessMovementUpdate(stu)
    elseif stu.type == CharacterStatePacket.CharacterStateUpdateType.DELETE then
        characterManager:DeleteCharacter(stu.peer, stu.died)
    end
end

PacketHandlerClient[SyncPacket.server.NAME] = function(nm: NetworkManager.NetworkManager, packet: Packet.Packet)
    local syn = packet :: SyncPacket.SyncPacket

    for i = 1, #syn.peers do
        nm.peerData[syn.peers[i]] = {
            state = NetworkManager.PeerState.JOINED,
            identity = syn.identities[i],
            successfulPings = 0,
            rtt = 0,
        }
    end
end

PacketHandlerClient[CharacterSyncPacket.server.NAME] = function(nm: NetworkManager.NetworkManager, packet: Packet.Packet)
    local syn = packet :: CharacterSyncPacket.CharacterSyncPacket

    local characterManager = assert(MapManager.currentRuntime).players

    for i = 1, #syn.peers do
        local character = characterManager:SpawnCharacter(syn.appearances[i], syn.peers[i], syn.transforms[i])

        if character and character:IsA(Character) then
            local c = character :: Character.Character

            c.state.state = syn.states[i]
            c.state:SetRagdoll(syn.isRagdoll[i])
        end
    end

    nm.peerData[1].state = NetworkManager.PeerState.SYNCED
end

return PacketHandlerClient
