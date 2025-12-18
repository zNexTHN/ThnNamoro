local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
src = {}
Tunnel.bindInterface(GetCurrentResourceName(),src)



local relationships = {}  -- [playerId] = { partnerId, type, startDate }
local pendingRequests = {} -- [targetId] = { fromId, fromName, type, timestamp }

-- Configurações
local Config = {
    requestTimeout = 60000, -- Tempo limite para responder pedido (ms)
    allowSameGender = true, -- Permitir relacionamentos do mesmo gênero
    requireProximity = false, -- Requer estar próximo para pedir
    proximityDistance = 3.0, -- Distância máxima se requireProximity = true
}

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================

--- Formata data no padrão ISO
--- @return string Data ISO
local function GetISODate()
    return os.date('!%Y-%m-%dT%H:%M:%S.000Z')
end

--- Obtém dados do relacionamento de um jogador
--- @param playerId number
--- @return table
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

--- Verifica se jogador está em relacionamento
--- @param playerId number
--- @return boolean
local function IsInRelationship(playerId)
    return relationships[playerId] ~= nil
end

--- Verifica se há pedido pendente
--- @param targetId number
--- @return table|nil
local function GetPendingRequest(targetId)
    local request = pendingRequests[targetId]
    
    if request then
        -- Verifica se expirou
        if GetGameTimer() - request.timestamp > Config.requestTimeout then
            pendingRequests[targetId] = nil
            return nil
        end
        return request
    end
    
    return nil
end

--- Cria relacionamento entre dois jogadores
--- @param player1 number
--- @param player2 number
--- @param relType string 'dating' ou 'marriage'
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
    
    -- Limpa pedidos pendentes
    pendingRequests[player1] = nil
    pendingRequests[player2] = nil
end

--- Remove relacionamento de ambos os jogadores
--- @param playerId number
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

-- ============================================
-- EVENTOS
-- ============================================

--- Evento: Obter status do relacionamento
RegisterNetEvent('relationship:getStatus', function()
    local src = source
    local data = GetRelationshipData(src)
    TriggerClientEvent('relationship:openUI', src, data)
end)

--- Evento: Enviar pedido de relacionamento
RegisterNetEvent('relationship:sendRequest', function(targetId, requestType)
    local src = source
    local srcName = GetPlayerName(src)
    
    -- Validação: Jogador já está em relacionamento
    if IsInRelationship(src) then
        TriggerClientEvent('relationship:notify', src, 'Você já está em um relacionamento!', 'error')
        return
    end
    
    -- Validação: Alvo já está em relacionamento
    if IsInRelationship(targetId) then
        TriggerClientEvent('relationship:notify', src, 'Esta pessoa já está em um relacionamento!', 'error')
        return
    end
    
    -- Validação: Jogador alvo existe
    if not GetPlayerName(targetId) then
        TriggerClientEvent('relationship:notify', src, 'Jogador não encontrado!', 'error')
        return
    end
    
    -- Validação: Não pode pedir a si mesmo
    if targetId == src then
        TriggerClientEvent('relationship:notify', src, 'Você não pode pedir a si mesmo!', 'error')
        return
    end
    
    -- Validação: Já tem pedido pendente para este jogador
    local existingRequest = GetPendingRequest(targetId)
    if existingRequest and existingRequest.fromId == src then
        TriggerClientEvent('relationship:notify', src, 'Você já enviou um pedido para esta pessoa!', 'error')
        return
    end
    
    -- Validação: Tipo de pedido válido
    if requestType ~= 'dating' and requestType ~= 'marriage' then
        TriggerClientEvent('relationship:notify', src, 'Tipo de pedido inválido!', 'error')
        return
    end
    
    -- Armazena pedido pendente
    pendingRequests[targetId] = {
        fromId = src,
        fromName = srcName,
        type = requestType,
        timestamp = GetGameTimer()
    }
    
    -- Notifica o alvo
    TriggerClientEvent('relationship:receiveRequest', targetId, src, srcName, requestType)
    
    -- Confirma envio
    local typeText = requestType == 'marriage' and 'casamento' or 'namoro'
    TriggerClientEvent('relationship:notify', src, 'Pedido de ' .. typeText .. ' enviado!', 'success')
end)

--- Evento: Aceitar pedido
RegisterNetEvent('relationship:acceptRequest', function(fromId)
    local src = source
    local request = GetPendingRequest(src)
    
    -- Validação: Pedido existe e é do remetente correto
    if not request or request.fromId ~= fromId then
        TriggerClientEvent('relationship:notify', src, 'Pedido não encontrado ou expirado!', 'error')
        return
    end
    
    -- Validação: Remetente ainda está online
    if not GetPlayerName(fromId) then
        TriggerClientEvent('relationship:notify', src, 'O jogador saiu do servidor!', 'error')
        pendingRequests[src] = nil
        return
    end
    
    -- Validação: Nenhum dos dois entrou em relacionamento enquanto esperava
    if IsInRelationship(src) or IsInRelationship(fromId) then
        TriggerClientEvent('relationship:notify', src, 'Um dos jogadores já está em relacionamento!', 'error')
        pendingRequests[src] = nil
        return
    end
    
    -- Cria o relacionamento
    CreateRelationship(src, fromId, request.type)
    
    -- Atualiza ambos os jogadores
    TriggerClientEvent('relationship:updateStatus', src, GetRelationshipData(src))
    TriggerClientEvent('relationship:updateStatus', fromId, GetRelationshipData(fromId))
    
    -- Notifica ambos
    local typeText = request.type == 'marriage' and 'casaram' or 'começaram a namorar'
    local emoji = request.type == 'marriage' and '💍' or '💕'
    
    TriggerClientEvent('relationship:notify', src, 'Vocês ' .. typeText .. '! ' .. emoji, 'success')
    TriggerClientEvent('relationship:notify', fromId, 'Vocês ' .. typeText .. '! ' .. emoji, 'success')
    
    -- Opcional: Anúncio global
    -- TriggerClientEvent('chat:addMessage', -1, {
    --     args = { '^5[Relacionamento]', GetPlayerName(src) .. ' e ' .. GetPlayerName(fromId) .. ' ' .. typeText .. '! ' .. emoji }
    -- })
end)

--- Evento: Recusar pedido
RegisterNetEvent('relationship:rejectRequest', function(fromId)
    local src = source
    local request = GetPendingRequest(src)
    
    if not request or request.fromId ~= fromId then
        return
    end
    
    -- Remove pedido pendente
    pendingRequests[src] = nil
    
    -- Notifica o remetente
    if GetPlayerName(fromId) then
        TriggerClientEvent('relationship:notify', fromId, 'Seu pedido foi recusado 💔', 'error')
    end
    
    -- Atualiza UI do jogador que recusou
    TriggerClientEvent('relationship:updateStatus', src, { status = 'single' })
end)

--- Evento: Terminar relacionamento
RegisterNetEvent('relationship:breakup', function()
    local src = source
    local rel = relationships[src]
    
    if not rel then
        TriggerClientEvent('relationship:notify', src, 'Você não está em um relacionamento!', 'error')
        return
    end
    
    local partnerId = rel.partnerId
    local wasMarried = rel.type == 'marriage'
    
    -- Remove relacionamento
    RemoveRelationship(src)
    
    -- Atualiza ambos
    TriggerClientEvent('relationship:updateStatus', src, { status = 'single' })
    
    if GetPlayerName(partnerId) then
        TriggerClientEvent('relationship:updateStatus', partnerId, { status = 'single' })
    end
    
    -- Notifica ambos
    local actionText = wasMarried and 'se divorciaram' or 'terminaram'
    
    TriggerClientEvent('relationship:notify', src, 'Vocês ' .. actionText .. ' 💔', 'error')
    
    if GetPlayerName(partnerId) then
        TriggerClientEvent('relationship:notify', partnerId, 'Vocês ' .. actionText .. ' 💔', 'error')
    end
end)

-- ============================================
-- CLEANUP
-- ============================================

--- Limpa dados quando jogador sai
AddEventHandler('playerDropped', function()
    local src = source
    
    -- Remove pedidos pendentes deste jogador
    for targetId, request in pairs(pendingRequests) do
        if request.fromId == src then
            pendingRequests[targetId] = nil
        end
    end
    pendingRequests[src] = nil
    
    -- Nota: Não removemos o relacionamento para manter persistência
    -- Em produção com banco de dados, os dados ficam salvos
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetRelationshipData', GetRelationshipData)
exports('IsInRelationship', IsInRelationship)
exports('GetPartner', function(playerId)
    local rel = relationships[playerId]
    return rel and rel.partnerId or nil
end)

-- ============================================
-- COMANDOS ADMIN (opcional)
-- ============================================

RegisterCommand('forcarnamoro', function(source, args)
    if source ~= 0 then return end -- Apenas console
    
    local player1 = tonumber(args[1])
    local player2 = tonumber(args[2])
    
    if player1 and player2 then
        CreateRelationship(player1, player2, 'dating')
        print('[Relacionamento] Namoro forçado entre ' .. player1 .. ' e ' .. player2)
    end
end, true)

RegisterCommand('forcarcasamento', function(source, args)
    if source ~= 0 then return end
    
    local player1 = tonumber(args[1])
    local player2 = tonumber(args[2])
    
    if player1 and player2 then
        CreateRelationship(player1, player2, 'marriage')
        print('[Relacionamento] Casamento forçado entre ' .. player1 .. ' e ' .. player2)
    end
end, true)

RegisterCommand('forcartermino', function(source, args)
    if source ~= 0 then return end
    
    local playerId = tonumber(args[1])
    
    if playerId then
        local partnerId = RemoveRelationship(playerId)
        if partnerId then
            print('[Relacionamento] Término forçado de ' .. playerId .. ' e ' .. partnerId)
        end
    end
end, true)


