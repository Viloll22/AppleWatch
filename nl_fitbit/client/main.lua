Keys = {
    ['ESC'] = 322, ['F1'] = 288, ['F2'] = 289, ['F3'] = 170, ['F5'] = 166, ['F6'] = 167, ['F7'] = 168, ['F8'] = 169, ['F9'] = 56, ['F10'] = 57,
    ['~'] = 243, ['1'] = 157, ['2'] = 158, ['3'] = 160, ['4'] = 164, ['5'] = 165, ['6'] = 159, ['7'] = 161, ['8'] = 162, ['9'] = 163, ['-'] = 84, ['='] = 83, ['BACKSPACE'] = 177,
    ['TAB'] = 37, ['Q'] = 44, ['W'] = 32, ['E'] = 38, ['R'] = 45, ['T'] = 245, ['Y'] = 246, ['U'] = 303, ['P'] = 199, ['['] = 39, [']'] = 40, ['ENTER'] = 18,
    ['CAPS'] = 137, ['A'] = 34, ['S'] = 8, ['D'] = 9, ['F'] = 23, ['G'] = 47, ['H'] = 74, ['K'] = 311, ['L'] = 182,
    ['LEFTSHIFT'] = 21, ['Z'] = 20, ['X'] = 73, ['C'] = 26, ['V'] = 0, ['B'] = 29, ['N'] = 249, ['M'] = 244, [','] = 82, ['.'] = 81,
    ['LEFTCTRL'] = 36, ['LEFTALT'] = 19, ['SPACE'] = 22, ['RIGHTCTRL'] = 70,
    ['HOME'] = 213, ['PAGEUP'] = 10, ['PAGEDOWN'] = 11, ['DELETE'] = 178,
    ['LEFT'] = 174, ['RIGHT'] = 175, ['TOP'] = 27, ['DOWN'] = 173,
}

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Wait(0)
	end

    Citizen.Wait(2000)

	ESX.TriggerServerCallback('nl_fitbit:getConnectedPlayers', function(connectedPlayers)
		UpdatePlayerTable(connectedPlayers)
    end)
    
    TriggerServerEvent('nl_fitbit:putNotLogged')

end)

RegisterCommand('reloj', function()
    ESX.TriggerServerCallback('nl_fitbit:server:HasFitbit', function(hasItem)
        if hasItem then
            TriggerEvent('nl_fitbit:use')
        else
            ESX.ShowNotification('No tienes el eWatch')
        end
    end, 'ewatch')
end)

-- Code

local inWatch = false
local isLoggedIn = false

local hunger = 100
local thirst = 100
local stress = 0
-- steps is the last amount of steps since saving
local m_steps

-- count is the steps measured since last save
local m_count = 0

-- the next time in ticks it should save
local m_nextSave


RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    isLoggedIn = true
end)

-- STEP COUNTER CODE

CreateThread(function()
    -- retrieve old steps count from kvp
    m_steps = GetResourceKvpFloat("stappenteller_steps")
    reset()

    while true do
        -- update step count every 500ms
        Wait(500)

    local _, walkDist = StatGetFloat(`mp0_dist_walking`)
    local _, runDist  = StatGetFloat(`mp0_dist_running`)
    local distance = walkDist + runDist

        -- meters to steps
        m_count = distance * 1.31233595800525

      --[[if getSteps() >= 1000 then
            reset()
            m_steps = 0
            m_count = 0
            TriggerServerEvent('stadus_skills:addStamina', GetPlayerServerId(PlayerId()), (1))
            ESX.ShowNotification("Has conseguido 1 punto de estamina")
        end]]
        

        if GetGameTimer() > m_nextSave then
            saveSteps()
        end

    end
end)

-- reset resets the local gta dist stats used for counting
function reset()
    StatSetFloat(`mp0_dist_walking`, 0.0, true)
    StatSetFloat(`mp0_dist_running`, 0.0, true)

    -- save every 20 seconds
    m_nextSave = GetGameTimer() + 20000
end

-- getSteps gets the amount of steps
function getSteps()
    return math.floor(m_steps + m_count)
end

-- saveSteps saves the amount of steps to KVP
function saveSteps()
    m_steps = getSteps()
    m_count = 0

    reset()

    SetResourceKvpFloat("stappenteller_steps", m_steps)
end

-- BASIC APPS

RegisterNetEvent('nl_fitbit:updateConnectedPlayers')
AddEventHandler('nl_fitbit:updateConnectedPlayers', function(connectedPlayers)
	UpdatePlayerTable(connectedPlayers)
end)

function UpdatePlayerTable(connectedPlayers)
	local formattedPlayerList, num = {}, 1
	local ems, police, taxi, mechanic, soa, taxi, tallernorte, marihuanero, players = 0, 0, 0, 0, 0, 0, 0, 0, 0 -- Añadir aqui los trabajos


	for k,v in pairs(connectedPlayers) do

		if num == 1 then
			table.insert(formattedPlayerList, ('<tr><td></td><td>%s</td><td></td>'):format(v.id, v.ping))
			num = 2
		elseif num == 2 then
			table.insert(formattedPlayerList, ('<td></td><td>%s</td><td></td></tr>'):format(v.id, v.ping))
			num = 1
		end

		players = players + 1
		if v.job == 'ambulance' then
			ems = ems + 1
			if ems > 3 then
				ems = '+3'
			end
		elseif v.job == 'police' then
			police = police + 1
			if police > 5 then
				police = '+5'
			end

		elseif v.job == 'taxi' then
			taxi = taxi + 1
			if taxi > 3 then
				taxi = '+2'
			end
		elseif v.job == 'mechanic' or v.job == 'tallernorte' then
			mechanic = mechanic + 1
			if mechanic > 3 then
				mechanic = '+3'
			end

		elseif v.job == 'soa' then
			tendero = tendero + 1
			if tendero > 2 then
				tendero = '+7'
			end
		end
	end

	if num == 1 then
		table.insert(formattedPlayerList, '</tr>')
	end

	SendNUIMessage({
		action  = 'updatePlayerList',
		players = table.concat(formattedPlayerList)
	})

	SendNUIMessage({
		action = 'updatePlayerJobs',
		jobs   = {ems = ems, police = police, taxi = taxi, mechanic = mechanic, tendero = tendero, taxi = taxi}
	})
end


local hudToggle = true

function openWatch()

    TriggerEvent('esx_status:getStatus', 'hunger',
    function(status) food = status.val / 10000 end)

    TriggerEvent('esx_status:getStatus', 'thirst',
    function(status) thirst = status.val / 10000 end)

    SendNUIMessage({
        action = "openWatch",
        watchData = {},
        stepData = getSteps(),
        hungerData = food,
        thirstData = thirst
    })
    SetNuiFocus(true, true)
    inWatch = true
     playAnim('amb@code_human_wander_idles_fat@male@idle_a','idle_a_wristwatch',1500)
end

function playAnim(animDict, animName, duration)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(0)
    end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1.0, duration, 49, 1, false, false, false)
    RemoveAnimDict(animDict)
end

function closeWatch()
    SetNuiFocus(false, false)
end

RegisterNUICallback('close', function()
    closeWatch()
end)

RegisterNUICallback('login', function()
    ExecuteCommand('ewatch_spotify pair')
end)

RegisterNUICallback('hud-spotify', function()
    ExecuteCommand('ewatch_spotify toggle')
end)
RegisterNUICallback('getLogged', function()
    ExecuteCommand('ewatch_spotify getLogIn')
end)

RegisterNUICallback('logoff', function()
    ExecuteCommand('ewatch_spotify unpair')
end)


RegisterNetEvent('nl_fitbit:Logged')
AddEventHandler('nl_fitbit:Logged', function(value)
    TriggerServerEvent('nl_fitbit:Logged:Server', value)
end)


RegisterNetEvent('nl_fitbit:use')
AddEventHandler('nl_fitbit:use', function()
  openWatch(true)
end)

Citizen.CreateThread(function()
    while true do

        Citizen.Wait(120 * 1000)
        
        if isLoggedIn then
            ESX.TriggerServerCallback('nl_fitbit:server:HasFitbit', function(hasItem)
                if hasItem then

                    TriggerEvent('esx_status:getStatus', 'hunger', function(status) 
                        food = status.val / 10000 
                    end)

                    TriggerEvent('esx_status:getStatus', 'thirst', function(status)
                         thirst = status.val / 10000 
                    end)

                    ESX.TriggerServerCallback('nl_fitbit:server:setValue', function(tabla)

                        if tabla.food then
                            if food < tabla.food then

                                TriggerServerEvent('InteractSound_SV:PlayOnSource', 'vibracion', 1.0)		
                                Wait(3100)

                                ESX.UI.Speech('Tu comida es menor a '..tabla.food.."%", 'mujer', 1.0)
                            end
                        end
            
                        if tabla.thirst then
                            if thirst <tabla.thirst then
                                TriggerServerEvent('InteractSound_SV:PlayOnSource', 'vibracion', 1.0)		
                                Wait(3100)

                                ESX.UI.Speech('Tu bebida es menor a '..tabla.thirst.."%", 'mujer', 1.0)
                            end
                        end
                    end)
                end
            end, "ewatch")
        end
    end
end)

RegisterNUICallback('setFoodWarning', function(data)
    local foodValue = tonumber(data.value)

    TriggerServerEvent('nl_fitbit:server:setValue', 'food', foodValue)

    ESX.ShowNotification('FigurasRP: Alarma de comida añadida al '..foodValue..'%')
end)

RegisterNUICallback('setThirstWarning', function(data)
    local thirstValue = tonumber(data.value)

    TriggerServerEvent('nl_fitbit:server:setValue', 'thirst', thirstValue)

    ESX.ShowNotification('FigurasRP: Alarma de bebida añadida al '..thirstValue..'%')
end)

RegisterNUICallback('setStepCount', function(data)

    ESX.ShowNotification('FigurasRP: Contador de pasos reseteados')

    StatSetFloat(`mp0_dist_walking`, 0.0, true)
    StatSetFloat(`mp0_dist_running`, 0.0, true)
    m_steps = 0
    
    SetResourceKvpFloat("stappenteller_steps", data.value)
end)

RegisterNUICallback('toggleHud', function(data)
    hudToggle = data.value

    TriggerEvent('contador')
    TriggerEvent('barritas')
    TriggerEvent('ocultar_chat')
    TriggerEvent('logo:display0')
    TriggerEvent('nocalles')
    ExecuteCommand('togglevoz')

    TriggerServerEvent('nl_fitbit:server:setValue', 'hud', hudToggle)
    if hudToggle then
        ExecuteCommand("hud")
        ESX.ShowNotification('FigurasRP: HUD desactivado')
    else
        ExecuteCommand("hud")
        ESX.ShowNotification('FigurasRP: HUD activado')
    end
end)


