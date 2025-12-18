local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
src = Tunnel.getInterface(GetCurrentResourceName(),src)

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
end)


RegisterCommand('relacionamento', function()
    print('Enviado!')
    if isUIOpen then
        CloseUI()
    else
        TriggerServerEvent('relationship:getStatus')
    end
end, false)

RegisterCommand('rel', function()
    ExecuteCommand('relacionamento')
end, false)

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

RegisterCommand('terminar', function()
    TriggerServerEvent('relationship:breakup')
end, false)

-- --- Thread para tecla ESC fechar a UI
-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(0)
        
--         if isUIOpen then
--             -- Desabilita ESC do menu de pausa
--             DisableControlAction(0, 200, true)
            
--             -- Se pressionar ESC, fecha a UI
--             if IsDisabledControlJustReleased(0, 200) then
--                 CloseUI()
--             end
--         end
--     end
-- end)


exports('OpenRelationshipUI', OpenUI)
exports('CloseRelationshipUI', CloseUI)
exports('IsRelationshipUIOpen', function() return isUIOpen end)