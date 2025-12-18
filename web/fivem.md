# 🎮 FiveM Integration - Sistema de Relacionamento

Documentação completa dos callbacks e eventos para integração com FiveM.

---

## 📁 Estrutura do Resource

```
relationship-system/
├── client/
│   └── main.lua
├── server/
│   └── main.lua
├── ui/
│   ├── index.html
│   └── assets/
├── fxmanifest.lua
└── README.md
```

---

## 📄 fxmanifest.lua

```lua
fx_version 'cerulean'
game 'gta5'

author 'Seu Nome'
description 'Sistema de Relacionamento NUI'
version '1.0.0'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/**/*'
}

client_script 'client/main.lua'
server_script 'server/main.lua'

-- Opcional: dependências
-- dependencies { 'oxmysql' }
```

---

## 📤 Client Script (client/main.lua)

```lua
--[[
    Sistema de Relacionamento - Client
    Gerencia a comunicação entre NUI e Server
]]

local isUIOpen = false
local currentRequest = nil

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================

--- Abre a UI de relacionamento
--- @param data table Dados do relacionamento atual
local function OpenUI(data)
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openUI',
        data = data or { status = 'single' }
    })
end

--- Fecha a UI de relacionamento
local function CloseUI()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeUI',
        data = {}
    })
end

--- Envia notificação para a UI
--- @param message string Mensagem a exibir
--- @param notifyType string 'success' ou 'error'
local function NotifyUI(message, notifyType)
    SendNUIMessage({
        type = 'notify',
        data = {
            message = message,
            type = notifyType or 'success'
        }
    })
end

--- Atualiza o status do relacionamento na UI
--- @param data table Dados atualizados
local function UpdateStatus(data)
    SendNUIMessage({
        type = 'updateStatus',
        data = data
    })
end

--- Notifica que recebeu um pedido
--- @param fromId number ID de quem enviou
--- @param fromName string Nome de quem enviou
--- @param requestType string 'dating' ou 'marriage'
local function ReceiveRequest(fromId, fromName, requestType)
    currentRequest = {
        fromId = fromId,
        fromName = fromName,
        type = requestType
    }
    
    -- Abre UI se não estiver aberta
    if not isUIOpen then
        OpenUI({ status = 'single' })
    end
    
    SendNUIMessage({
        type = 'receiveRequest',
        data = {
            fromId = tostring(fromId),
            fromName = fromName,
            type = requestType
        }
    })
end

-- ============================================
-- CALLBACKS NUI
-- ============================================

--- Callback: Fechar UI
RegisterNUICallback('closeUI', function(_, cb)
    CloseUI()
    cb('ok')
end)

--- Callback: Enviar pedido de relacionamento
--- @param data table { targetId: string, type: 'dating'|'marriage' }
RegisterNUICallback('sendRequest', function(data, cb)
    local targetId = tonumber(data.targetId)
    
    if not targetId then
        cb({ success = false, message = 'ID inválido' })
        return
    end
    
    if targetId == GetPlayerServerId(PlayerId()) then
        cb({ success = false, message = 'Você não pode pedir a si mesmo!' })
        return
    end
    
    TriggerServerEvent('relationship:sendRequest', targetId, data.type)
    cb({ success = true })
end)

--- Callback: Aceitar pedido recebido
--- @param data table { fromId: string }
RegisterNUICallback('acceptRequest', function(data, cb)
    local fromId = tonumber(data.fromId)
    
    if not fromId then
        cb({ success = false, message = 'Pedido inválido' })
        return
    end
    
    TriggerServerEvent('relationship:acceptRequest', fromId)
    currentRequest = nil
    cb({ success = true })
end)

--- Callback: Recusar pedido recebido
--- @param data table { fromId: string }
RegisterNUICallback('rejectRequest', function(data, cb)
    local fromId = tonumber(data.fromId)
    
    if not fromId then
        cb({ success = false, message = 'Pedido inválido' })
        return
    end
    
    TriggerServerEvent('relationship:rejectRequest', fromId)
    currentRequest = nil
    cb({ success = true })
end)

--- Callback: Terminar relacionamento
RegisterNUICallback('breakup', function(_, cb)
    TriggerServerEvent('relationship:breakup')
    cb({ success = true })
end)

--- Callback: Obter status atual
RegisterNUICallback('getStatus', function(_, cb)
    TriggerServerEvent('relationship:getStatus')
    cb({ success = true })
end)

-- ============================================
-- EVENTOS DO SERVIDOR
-- ============================================

--- Evento: Abre a UI com dados do relacionamento
RegisterNetEvent('relationship:openUI', function(data)
    OpenUI(data)
end)

--- Evento: Fecha a UI
RegisterNetEvent('relationship:closeUI', function()
    CloseUI()
end)

--- Evento: Recebe um pedido de relacionamento
RegisterNetEvent('relationship:receiveRequest', function(fromId, fromName, requestType)
    ReceiveRequest(fromId, fromName, requestType)
end)

--- Evento: Atualiza status do relacionamento
RegisterNetEvent('relationship:updateStatus', function(data)
    UpdateStatus(data)
end)

--- Evento: Notificação do servidor
RegisterNetEvent('relationship:notify', function(message, notifyType)
    NotifyUI(message, notifyType)
    
    -- Opcional: também mostrar notificação nativa do GTA
    -- SetNotificationTextEntry('STRING')
    -- AddTextComponentString(message)
    -- DrawNotification(false, true)
end)

-- ============================================
-- COMANDOS
-- ============================================

--- Comando para abrir o menu de relacionamento
RegisterCommand('relacionamento', function()
    if isUIOpen then
        CloseUI()
    else
        TriggerServerEvent('relationship:getStatus')
    end
end, false)

--- Comando alternativo
RegisterCommand('rel', function()
    ExecuteCommand('relacionamento')
end, false)

--- Comando para pedir em namoro (atalho)
RegisterCommand('namorar', function(_, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerEvent('chat:addMessage', {
            args = { '^1[Relacionamento]', 'Use: /namorar [ID]' }
        })
        return
    end
    TriggerServerEvent('relationship:sendRequest', targetId, 'dating')
end, false)

--- Comando para pedir em casamento (atalho)
RegisterCommand('casar', function(_, args)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerEvent('chat:addMessage', {
            args = { '^1[Relacionamento]', 'Use: /casar [ID]' }
        })
        return
    end
    TriggerServerEvent('relationship:sendRequest', targetId, 'marriage')
end, false)

--- Comando para terminar/divorciar
RegisterCommand('terminar', function()
    TriggerServerEvent('relationship:breakup')
end, false)

-- ============================================
-- TECLAS DE ATALHO
-- ============================================

--- Thread para tecla ESC fechar a UI
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if isUIOpen then
            -- Desabilita ESC do menu de pausa
            DisableControlAction(0, 200, true)
            
            -- Se pressionar ESC, fecha a UI
            if IsDisabledControlJustReleased(0, 200) then
                CloseUI()
            end
        end
    end
end)

--- Opcional: Tecla para abrir menu (F5)
-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(0)
--         if IsControlJustReleased(0, 166) then -- F5
--             ExecuteCommand('relacionamento')
--         end
--     end
-- end)

-- ============================================
-- EXPORTS (para outros resources)
-- ============================================

exports('OpenRelationshipUI', OpenUI)
exports('CloseRelationshipUI', CloseUI)
exports('IsRelationshipUIOpen', function() return isUIOpen end)
```

---

## 📥 Server Script (server/main.lua)

```lua
--[[
    Sistema de Relacionamento - Server
    Gerencia a lógica de relacionamentos
    
    ATENÇÃO: Este exemplo usa armazenamento em memória.
    Para produção, use um banco de dados (oxmysql, mysql-async, etc.)
]]

-- Armazenamento em memória (substitua por banco de dados)
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
```

---

## 🗄️ Integração com Banco de Dados (oxmysql)

Para persistir os dados, substitua as funções de armazenamento:

```lua
-- No início do server/main.lua, adicione:

--- Carrega relacionamento do banco
--- @param identifier string Identifier do jogador
local function LoadRelationship(identifier)
    local result = MySQL.query.await([[
        SELECT * FROM relationships 
        WHERE player1 = ? OR player2 = ?
    ]], { identifier, identifier })
    
    if result and result[1] then
        return result[1]
    end
    return nil
end

--- Salva relacionamento no banco
--- @param player1 string Identifier do jogador 1
--- @param player2 string Identifier do jogador 2
--- @param relType string 'dating' ou 'marriage'
local function SaveRelationship(player1, player2, relType)
    MySQL.insert.await([[
        INSERT INTO relationships (player1, player2, type, start_date)
        VALUES (?, ?, ?, NOW())
    ]], { player1, player2, relType })
end

--- Remove relacionamento do banco
--- @param identifier string Identifier de qualquer um dos parceiros
local function DeleteRelationship(identifier)
    MySQL.query.await([[
        DELETE FROM relationships 
        WHERE player1 = ? OR player2 = ?
    ]], { identifier, identifier })
end
```

### SQL para criar tabela:

```sql
CREATE TABLE IF NOT EXISTS `relationships` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player1` VARCHAR(60) NOT NULL,
    `player2` VARCHAR(60) NOT NULL,
    `type` ENUM('dating', 'marriage') NOT NULL DEFAULT 'dating',
    `start_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_relationship` (`player1`, `player2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 📋 Resumo dos Eventos

### Client → Server
| Evento | Parâmetros | Descrição |
|--------|------------|-----------|
| `relationship:getStatus` | - | Solicita status atual |
| `relationship:sendRequest` | `targetId, type` | Envia pedido |
| `relationship:acceptRequest` | `fromId` | Aceita pedido |
| `relationship:rejectRequest` | `fromId` | Recusa pedido |
| `relationship:breakup` | - | Termina relacionamento |

### Server → Client
| Evento | Parâmetros | Descrição |
|--------|------------|-----------|
| `relationship:openUI` | `data` | Abre UI com dados |
| `relationship:closeUI` | - | Fecha UI |
| `relationship:receiveRequest` | `fromId, fromName, type` | Notifica pedido |
| `relationship:updateStatus` | `data` | Atualiza status |
| `relationship:notify` | `message, type` | Exibe notificação |

### NUI Callbacks
| Callback | Dados | Descrição |
|----------|-------|-----------|
| `closeUI` | - | Fecha UI |
| `sendRequest` | `{ targetId, type }` | Envia pedido |
| `acceptRequest` | `{ fromId }` | Aceita pedido |
| `rejectRequest` | `{ fromId }` | Recusa pedido |
| `breakup` | - | Termina relacionamento |
| `getStatus` | - | Obtém status |

---

## 🎮 Comandos Disponíveis

| Comando | Descrição |
|---------|-----------|
| `/relacionamento` ou `/rel` | Abre/fecha o menu |
| `/namorar [ID]` | Pede em namoro |
| `/casar [ID]` | Pede em casamento |
| `/terminar` | Termina relacionamento |

---

Feito com 💕 para a comunidade FiveM
