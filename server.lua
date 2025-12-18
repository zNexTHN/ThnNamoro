local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
src = {}
Tunnel.bindInterface(GetCurrentResourceName(),src)



local relationships = {}  -- [playerId] = { partnerId, type, startDate }
local pendingRequests = {} -- [targetId] = { fromId, fromName, type, timestamp }

local Config = {
    requestTimeout = 60000, -- Tempo limite para responder pedido (ms)
    allowSameGender = true, -- Permitir relacionamentos do mesmo gênero
    requireProximity = false, -- Requer estar próximo para pedir
    proximityDistance = 3.0, -- Distância máxima se requireProximity = true
}

local function GetISODate()
    return os.date('!%Y-%m-%dT%H:%M:%S.000Z')
end

local function GetRelationshipData(playerId)
    local rel = relationships[playerId]
    
    if not rel then
        return { status = 'single' }
    end
    
    local partnerName = GetPlayerName(rel.partnerId)
    if not partnerName then
        partnerName = 'Offline'
    end
    
    return {
        status = rel.type == 'marriage' and 'married' or 'dating',
        partner = {
            id = tostring(rel.partnerId),
            name = partnerName,
            startDate = rel.startDate
        }
    }
end


local function IsInRelationship(playerId)
    return relationships[playerId] ~= nil
end

local function GetPendingRequest(targetId)
    local request = pendingRequests[targetId]
    
    if request then
        if GetGameTimer() - request.timestamp > Config.requestTimeout then
            pendingRequests[targetId] = nil
            return nil
        end
        return request
    end
    
    return nil
end

local function CreateRelationship(player1, player2, relType)
    local now = GetISODate()
    
    relationships[player1] = {
        partnerId = player2,
        type = relType,
        startDate = now
    }
    
    relationships[player2] = {
        partnerId = player1,
        type = relType,
        startDate = now
    }
    
    pendingRequests[player1] = nil
    pendingRequests[player2] = nil
end

local function RemoveRelationship(playerId)
    local rel = relationships[playerId]
    
    if rel then
        local partnerId = rel.partnerId
        relationships[playerId] = nil
        relationships[partnerId] = nil
        return partnerId
    end
    
    return nil
end

RegisterNetEvent('relationship:getStatus', function()
    local src = source
    local data = GetRelationshipData(src)
    TriggerClientEvent('relationship:openUI', src, data)
end)


src.getStatus = function()
    local src = source
    local data = GetRelationshipData(src)
    return data
end

src.sendRequest = function(targetId,requestType)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then        
        local nplayer = vRP.getUserSource(targetId)
        if nplayer then
            local nuser_id = vRP.getUserId(nplayer)
            if nuser_id then
                local identity = vRP.getUserIdentity(nuser_id)
                local srcName = identity.name..' '..identity.firstname
                if nuser_id == user_id then
                    return false,'Você não pode pedir a si mesmo!'
                end
                
                if IsInRelationship(user_id) then
                    return false,'Você já está em um relacionamento!'
                end

                if IsInRelationship(nuser_id) then
                    return false,'Esta pessoa já está em um relacionamento!'
                end

                local existingRequest = GetPendingRequest(nuser_id)
                if existingRequest and existingRequest.fromId == user_id then
                    return false,'Você já enviou um pedido para esta pessoa!'
                end
                
                if requestType ~= 'dating' and requestType ~= 'marriage' then
                    return false,'Tipo de pedido inválido!'
                end
                
                pendingRequests[nplayer] = {
                    fromId = user_id,
                    fromName = srcName,
                    type = requestType,
                    timestamp = GetGameTimer()
                }
                
                TriggerClientEvent('relationship:receiveRequest', nplayer, user_id, srcName, requestType)
                
                local typeText = requestType == 'marriage' and 'casamento' or 'namoro'
                TriggerClientEvent('Notify', source, 'sucesso','Pedido de ' .. typeText .. ' enviado!')
                return true
            end
        else
            return false, 'Jogador não encontrado!'
        end
    end
end 

RegisterNetEvent('relationship:acceptRequest', function(fromId)
    local src = source
    local user_id = vRP.getUserId(src)
    local request = GetPendingRequest(src)
    
    if not request or request.fromId ~= fromId then
        TriggerClientEvent('relationship:notify', src, 'Pedido não encontrado ou expirado!', 'negado')
        return
    end
    
    print(fromId,request.fromId,json.encode(request))
    if not vRP.getUserSource(fromId) then
        TriggerClientEvent('relationship:notify', src, 'O jogador saiu do servidor!', 'negado')
        pendingRequests[src] = nil
        return
    end
    
    if IsInRelationship(user_id) or IsInRelationship(fromId) then
        TriggerClientEvent('relationship:notify', src, 'Um dos jogadores já está em relacionamento!', 'negado')
        pendingRequests[src] = nil
        return
    end
    
    CreateRelationship(user_id, fromId, request.type)
    
    TriggerClientEvent('relationship:updateStatus', src, GetRelationshipData(src))
    TriggerClientEvent('relationship:updateStatus', fromId, GetRelationshipData(fromId))
    
    local typeText = request.type == 'marriage' and 'casaram' or 'começaram a namorar'
    local emoji = request.type == 'marriage' and '💍' or '💕'
    
    TriggerClientEvent('relationship:notify', src, 'Vocês ' .. typeText .. '! ' .. emoji, 'sucesso')
    TriggerClientEvent('relationship:notify', fromId, 'Vocês ' .. typeText .. '! ' .. emoji, 'sucesso')
    
    -- Opcional: Anúncio global
    -- TriggerClientEvent('chat:addMessage', -1, {
    --     args = { '^5[Relacionamento]', GetPlayerName(src) .. ' e ' .. GetPlayerName(fromId) .. ' ' .. typeText .. '! ' .. emoji }
    -- })
end)
RegisterNetEvent('relationship:rejectRequest', function(fromId)
    local src = source
    local request = GetPendingRequest(src)
    
    if not request or request.fromId ~= fromId then
        return
    end
    
    pendingRequests[src] = nil
    
    if GetPlayerName(fromId) then
        TriggerClientEvent('relationship:notify', fromId, 'Seu pedido foi recusado 💔', 'negado')
    end
    
    TriggerClientEvent('relationship:updateStatus', src, { status = 'single' })
end)

RegisterNetEvent('relationship:breakup', function()
    local src = source
    local rel = relationships[src]
    
    if not rel then
        TriggerClientEvent('relationship:notify', src, 'Você não está em um relacionamento!', 'negado')
        return
    end
    
    local partnerId = rel.partnerId
    local wasMarried = rel.type == 'marriage'
    
    RemoveRelationship(src)
    
    TriggerClientEvent('relationship:updateStatus', src, { status = 'single' })
    
    if GetPlayerName(partnerId) then
        TriggerClientEvent('relationship:updateStatus', partnerId, { status = 'single' })
    end
    
    local actionText = wasMarried and 'se divorciaram' or 'terminaram'
    
    TriggerClientEvent('relationship:notify', src, 'Vocês ' .. actionText .. ' 💔', 'negado')
    
    if GetPlayerName(partnerId) then
        TriggerClientEvent('relationship:notify', partnerId, 'Vocês ' .. actionText .. ' 💔', 'negado')
    end
end)


AddEventHandler('playerDropped', function()
    local src = source
    for targetId, request in pairs(pendingRequests) do
        if request.fromId == src then
            pendingRequests[targetId] = nil
        end
    end
    pendingRequests[src] = nil
end)
