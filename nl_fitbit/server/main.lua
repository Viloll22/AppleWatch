ESX = nil
local connectedPlayers = {}
local playerJobs = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('nl_fitbit:getConnectedPlayers', function(source, cb)
	cb(connectedPlayers)
end)

AddEventHandler('esx:setJob', function(playerId, job, lastJob)
	connectedPlayers[playerId].job = job.name
	connectedPlayers[playerId].jobLabel = job.label
	
	TriggerClientEvent('nl_fitbit:updateConnectedPlayers', -1, connectedPlayers)
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
	AddPlayersToScoreboard()
end)

AddEventHandler('esx:playerDropped', function(playerId)
	connectedPlayers[playerId] = nil
	TriggerClientEvent('nl_fitbit:updateConnectedPlayers', -1, connectedPlayers)
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.CreateThread(function()
			Citizen.Wait(1000)
			AddPlayersToScoreboard()
		end)
	end
end)

function AddPlayerToScoreboard(xPlayer, update)
	local playerId = xPlayer.source

	local identifier = GetPlayerIdentifiers(playerId)[1]
	local result = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", { ['@identifier'] = identifier })
	
	connectedPlayers[playerId] = {}
	connectedPlayers[playerId].id = playerId
	connectedPlayers[playerId].job = xPlayer.job.name
	connectedPlayers[playerId].jobLabel = xPlayer.job.label

	if update then
		TriggerClientEvent('nl_fitbit:updateConnectedPlayers', -1, connectedPlayers)
	end
end

function AddPlayersToScoreboard()
	local players = ESX.GetPlayers()
	for i=1, #players, 1 do
		local xPlayer = ESX.GetPlayerFromId(players[i])
		AddPlayerToScoreboard(xPlayer, true)
	end
	TriggerClientEvent('nl_fitbit:updateConnectedPlayers', -1, connectedPlayers)
end

ESX.RegisterUsableItem("fitbit", function(source, item)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent('nl_fitbit:use', source)
end)


RegisterServerEvent('nl_fitbit:server:setValue')
AddEventHandler('nl_fitbit:server:setValue', function(type, value)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local fitbitData = {}

    if type == "thirst" then
        local currentMeta = xPlayer.PlayerData["fitbit"]
        fitbitData = {
            thirst = value,
            food = currentMeta.food
        }
    elseif type == "food" then
        local currentMeta = xPlayer.PlayerData["fitbit"]
        fitbitData = {
            thirst = currentMeta.thirst,
            food = value
        }
    end

    xPlayer.SetMetaData('fitbit', fitbitData)
end)


ESX.RegisterServerCallback('nl_fitbit:server:HasFitbit', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local Fitbit = xPlayer.getInventoryItem("fitbit")
    if Fitbit ~= nil then
        cb(true)
    else
        cb(false)
    end
end)

--- CARS ---

RegisterCommand('carstats', function(source, args, user)
    TriggerClientEvent('carstats', source, {})
end)
