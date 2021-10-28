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
                        local boneWasDamaged, damagedBone = GetPedLastDamageBone(victim)
                        if not boneWasDamaged then
                            damagedBone = -1
                        end
                        TriggerServerEvent('ev:updateKillerData', {tostring(GetPlayerServerId(NetworkGetEntityOwner(attacker))), tostring(GetPlayerServerId(NetworkGetEntityOwner(victim))), damagedBone})
                    end
                end
            end
        end
    end
end

AddEventHandler('gameEventTriggered',function(name, args)
    GameEventTriggered(name,args)
end)

RegisterNetEvent('ev:showLeaderboard', function(all, result)
    if type(result) ~= "table" then
        return print('Cannot receive data, sus')
    end
    isOpen = true
    if all then
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'showScoreboard',
            players = result
        })
    else
        SetNuiFocus(true)
        SetNuiFocusKeepInput(true)
        SendNUIMessage({
            action = 'showScore',
            player = result
        })
    end
end)

RegisterNUICallback('close', function(_, cb)
    if isOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        isOpen = false
    end
    cb({})
end)
