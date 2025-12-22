local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
src = {}
Tunnel.bindInterface(GetCurrentResourceName(),src)

vRP.prepare("thn/create_relationships_table", [[
    CREATE TABLE IF NOT EXISTS thn_relationships (
        user_id INT(11) NOT NULL,
        partner_id INT(11) NOT NULL,
        type VARCHAR(50),
        start_date VARCHAR(50),
        PRIMARY KEY (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]])

vRP.prepare("thn/get_relationship", "SELECT * FROM thn_relationships WHERE user_id = @user_id")
vRP.prepare("thn/insert_relationship", "INSERT INTO thn_relationships(user_id, partner_id, type, start_date) VALUES(@user_id, @partner_id, @type, @start_date)")
vRP.prepare("thn/delete_relationship", "DELETE FROM thn_relationships WHERE user_id = @user_id OR user_id = @partner_id")

Citizen.CreateThread(function()
    vRP.execute("thn/create_relationships_table")
end)

local relationships = {}  
local pendingRequests = {}

local Config = {
    requestTimeout = 60000, -- Tempo limite para responder pedido (ms)
    allowSameGender = true, -- Permitir relacionamentos do mesmo gênero
    requireProximity = false, -- Requer estar próximo para pedir
    proximityDistance = 3.0, -- Distância máxima se requireProximity = true
}

local function GetISODate()
    return os.date('!%Y-%m-%dT%H:%M:%S.000Z')
end


local function syncRelacionamento(user_id)
    local rows = vRP.query("thn/get_relationship", { user_id = user_id })
    if #rows > 0 then
        local row = rows[1]
        relationships[user_id] = {
            partnerId = row.partner_id,
            type = row.type,
            startDate = row.start_date
        }
    end
end

AddEventHandler("vRP:playerSpawn",function(user_id,source,first_spawn)
    if user_id then
        syncRelacionamento(user_id)
    end
end)

local function GetRelationshipData(user_id)
    local rel = relationships[user_id]
    
    if not rel then
        return { status = 'single' }
    end
    
    local partnerName = "Desconhecido"
    local identity = vRP.getUserIdentity(rel.partnerId)
    if identity then
        partnerName = identity.name .. ' ' .. identity.firstname
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

local function IsInRelationship(user_id)
    return relationships[user_id] ~= nil
end

local function GetPendingRequest(targetSource)
    local request = pendingRequests[targetSource]
    
    if request then
        if GetGameTimer() - request.timestamp > Config.requestTimeout then
            pendingRequests[targetSource] = nil
            return nil
        end
        return request
    end
    
    return nil
end

local function CreateRelationship(user_id_1, user_id_2, relType)
    local now = GetISODate()
    
    -- Atualiza Cache na Memória
    relationships[user_id_1] = {
        partnerId = user_id_2,
        type = relType,
        startDate = now
    }
    
    relationships[user_id_2] = {
        partnerId = user_id_1,
        type = relType,
        startDate = now
    }
    
    vRP.execute("thn/insert_relationship", { user_id = user_id_1, partner_id = user_id_2, type = relType, start_date = now })
    vRP.execute("thn/insert_relationship", { user_id = user_id_2, partner_id = user_id_1, type = relType, start_date = now })
end

local function RemoveRelationship(user_id)
    local rel = relationships[user_id]
    
    if rel then
        local partnerId = rel.partnerId
        
        vRP.execute("thn/delete_relationship", { user_id = user_id, partner_id = partnerId })

        relationships[user_id] = nil
        relationships[partnerId] = nil
        
        return partnerId
    end
    
    return nil
end

RegisterNetEvent('relationship:getStatus', function()
    local src = source
    local user_id = vRP.getUserId(src)
    if user_id then
        local data = GetRelationshipData(user_id)
        TriggerClientEvent('relationship:openUI', src, data)
    end
end)

src.getStatus = function()
    local src = source
    local user_id = vRP.getUserId(src)
    if user_id then
        syncRelacionamento(user_id)
        return GetRelationshipData(user_id)
    end
    return { status = 'single' }
end

src.sendRequest = function(targetId,requestType)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then        
        local nplayer = vRP.getUserSource(tonumber(targetId))
        if nplayer then
            local nuser_id = vRP.getUserId(nplayer)
            if nuser_id then
                local identity = vRP.getUserIdentity(user_id) 
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

                local existingRequest = GetPendingRequest(nplayer)
                if existingRequest and existingRequest.fromId == user_id then
                    return false,'Você já enviou um pedido para esta pessoa!'
                end
                
                print(requestType)
                if requestType ~= 'dating' and requestType ~= 'marriage' and requestType ~= 'engagement' then
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
            return false, 'Cidadão não encontrado ou offline!'
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

    local nplayer = vRP.getUserSource(fromId)
    if not nplayer then
        TriggerClientEvent('relationship:notify', src, 'O cidadão saiu da cidade!', 'negado')
        pendingRequests[src] = nil
        return
    end
    
    if IsInRelationship(user_id) or IsInRelationship(fromId) then
        TriggerClientEvent('relationship:notify', src, 'Um dos jogadores já está em relacionamento!', 'negado')
        pendingRequests[src] = nil
        return
    end
    
    CreateRelationship(user_id, fromId, request.type)

    pendingRequests[src] = nil

    TriggerClientEvent('relationship:updateStatus', src, GetRelationshipData(user_id))
    TriggerClientEvent('relationship:updateStatus', nplayer, GetRelationshipData(fromId))
    
    local typeText = request.type == 'marriage' and 'casaram' or 'começaram a namorar'
    local emoji = request.type == 'marriage' and '💍' or '💕'
    
    TriggerClientEvent('relationship:notify', src, 'Vocês ' .. typeText .. '! ' .. emoji, 'sucesso')
    TriggerClientEvent('relationship:notify', nplayer, 'Vocês ' .. typeText .. '! ' .. emoji, 'sucesso')
end)

RegisterNetEvent('relationship:rejectRequest', function(fromId)
    local src = source
    local request = GetPendingRequest(src)
    
    if not request or request.fromId ~= fromId then
        return
    end
    
    pendingRequests[src] = nil
    
    local nplayer = vRP.getUserSource(fromId)
    if nplayer then
        TriggerClientEvent('relationship:notify', nplayer, 'Seu pedido foi recusado 💔', 'negado')
    end
    
    TriggerClientEvent('relationship:updateStatus', src, { status = 'single' })
end)

RegisterNetEvent('relationship:breakup', function()
    local src = source
    local user_id = vRP.getUserId(src)
    local rel = relationships[user_id]
    
    if not rel then
        TriggerClientEvent('relationship:notify', src, 'Você não está em um relacionamento!', 'negado')
        return
    end
    
    local partnerId = rel.partnerId
    local wasMarried = rel.type == 'marriage'
    
    RemoveRelationship(user_id)
    
    TriggerClientEvent('relationship:updateStatus', src, { status = 'single' })
    
    local nplayer = vRP.getUserSource(partnerId)
    if nplayer then
        TriggerClientEvent('relationship:updateStatus', nplayer, { status = 'single' })
    end
    
    local actionText = wasMarried and 'se divorciaram' or 'terminaram'
    
    TriggerClientEvent('relationship:notify', src, 'Vocês ' .. actionText .. ' 💔', 'negado')
    
    if nplayer then
        TriggerClientEvent('relationship:notify', nplayer, 'Vocês ' .. actionText .. ' 💔', 'negado')
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local user_id = vRP.getUserId(src)
    
    if user_id then
        relationships[user_id] = nil
        
        for targetSrc, request in pairs(pendingRequests) do
            if request.fromId == user_id then
                pendingRequests[targetSrc] = nil
            end
        end
    end
    pendingRequests[src] = nil
end)