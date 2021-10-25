local firstSpawn = true

CreateThread(function()
	while firstSpawn do
		if NetworkIsPlayerActive(PlayerId()) then
            if firstSpawn then
			    TriggerServerEvent('ev:playerSet')
                firstSpawn = false
            end
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
                        print(GetPlayerServerId(NetworkGetEntityOwner(attacker)))
                        print(GetPlayerServerId(NetworkGetEntityOwner(victim)))
                    end
                end
            end
        end
    end
end

AddEventHandler('gameEventTriggered',function(name, args)
    GameEventTriggered(name,args)
end)