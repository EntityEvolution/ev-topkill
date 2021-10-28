local isOpen = false

CreateThread(function()
	while true do
		if NetworkIsPlayerActive(PlayerId()) then
			    TriggerServerEvent('ev:playerSet')
			break
		end
        Wait(0)
	end
end)

local function GameEventTriggered(eventName, data)
    if eventName == "CEventNetworkEntityDamage" then
		local newbuild = #data == 13
		local i = 1
		local function iplus()
			local x = i
			i = i + 1
			return x
		end
        local victim = tonumber(data[iplus()])
        local attacker = tonumber(data[iplus()])
		iplus()
		if newbuild then
			iplus()
			iplus()
			if #data == 12 then i = i - 1 end
		end 
        local victimDied = tonumber(data[iplus()]) == 1 and true or false
        if attacker == PlayerPedId() then
            if attacker ~= victim then
                if IsPedAPlayer(attacker) and IsPedAPlayer(victim) then
                    if victimDied then
                        TriggerServerEvent('ev:updateKillerData', {tostring(GetPlayerServerId(NetworkGetEntityOwner(attacker))), tostring(GetPlayerServerId(NetworkGetEntityOwner(victim)))})
                    end
                end
            end
        end
    end
end

local function checkInput()
    CreateThread(function()
        while isOpen do
            Wait(0)
            if isOpen then
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 37, true)
                DisableControlAction(0, 257, true)
                DisableControlAction(0, 106, true)
                DisableControlAction(0, 287, true)
                DisableControlAction(0, 286, true)
                DisableControlAction(0, 199, true)
            end
            Wait(1)
        end
    end)
end

AddEventHandler('gameEventTriggered',function(name, args)
    GameEventTriggered(name,args)
end)

RegisterNetEvent('ev:showLeaderboard', function(all, result)
    if type(result) ~= "table" then
        return print('Cannot receive data, sus')
    end
    SetNuiFocus(true)
    SetNuiFocusKeepInput(true)
    isOpen = true
    checkInput()
    if all then
        SendNUIMessage({
            action = 'showScoreboard',
            first = result[1],
            second = result[2],
            third = result[3]
        })
    else
        SendNUIMessage({
            action = 'showScore',
            player = result
        })
    end
end)

RegisterNUICallback('close', function(_, cb)
    if isOpen then
        SetNuiFocus(false)
        SetNuiFocusKeepInput(false)
        isOpen = false
    end
    cb({})
end)
