local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
src = Tunnel.getInterface(GetCurrentResourceName(),src)

local isUIOpen = false
local currentRequest = nil


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

local function NotifyUI(message, notifyType)
    SendNUIMessage({
        type = 'notify',
        data = {
            message = message,
            type = notifyType or 'success'
        }
    })
end

local function UpdateStatus(data)
    SendNUIMessage({
        type = 'updateStatus',
        data = data
    })
end


local function ReceiveRequest(fromId, fromName, requestType)
    currentRequest = {
        fromId = fromId,
        fromName = fromName,
        type = requestType
    }
    
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


RegisterNUICallback('closeUI', function(_, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('sendRequest', function(data, cb)
    local targetId = tonumber(data.targetId)
    
    if not targetId then
        cb({ success = false, message = 'ID inválido' })
        return
    end
    

    local status,mensagem = src.sendRequest(targetId,data.type)
    if status then
        cb({ success = true })
        return;
    end
    TriggerEvent('Notify', 'negado',mensagem,3000)
    cb({ success = false, message = mensagem })
end)

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

RegisterNUICallback('breakup', function(_, cb)
    TriggerServerEvent('relationship:breakup')
    cb({ success = true })
end)

RegisterNUICallback('getStatus', function(_, cb)
    TriggerServerEvent('relationship:getStatus')
    cb({ success = true })
end)



RegisterNetEvent('relationship:closeUI', function()
    CloseUI()
end)

RegisterNetEvent('relationship:receiveRequest', function(fromId, fromName, requestType)
    ReceiveRequest(fromId, fromName, requestType)
end)

RegisterNetEvent('relationship:updateStatus', function(data)
    UpdateStatus(data)
end)

RegisterNetEvent('relationship:notify', function(message, notifyType)
    TriggerEvent('Notify', notifyType, message,3000)

    --NotifyUI(message, notifyType)
end)


RegisterCommand('relacionamento', function()
    if isUIOpen then
        CloseUI()
    else
        local status = src.getStatus()
        if status then
            OpenUI(status)
        end
        TriggerServerEvent('relationship:getStatus')
    end
end, false)