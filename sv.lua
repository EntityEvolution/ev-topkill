local insert = table.insert
local sort = table.sort

local playersData = {}
local TOKEN = "Bot Nzc3MDU1MTA4MDEzNzUyMzIw.X6929g.ScaHvW1Ogo3soA6WcFSHyJRNh5I"

--#region Functions
---Gets the discord id and cuts it
---@param playerId number
---@return string
---@return boolean
local function getDiscordId(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    for i=1, #identifiers do
        if identifiers[i]:match('discord:') then
            return identifiers[i]:gsub('discord:', '')
        end
    end
    return false
end

---Gets the license of a player
---@param playerId number
---@return string
---@return boolean
local function getLicense(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    for i=1, #identifiers do
        if identifiers[i]:match('license:') then
            return identifiers[i]
        end
    end
    return false
end

---Fetches the discord api for an user.
---If player id is not nil, then it returns avatar
---@param playerId any
---@return string
local function getPlayerIconFromIdentifier(playerId)
    if not playerId then
        return 'noimage'
    end
    local discordId = getDiscordId(playerId)
    if not discordId then
        return 'noimage'
    end
    local p = promise.new()
    PerformHttpRequest(('https://discordapp.com/api/users/%s'):format(discordId), function(err, result, headers)
        p:resolve({data=result, code=err, headers = headers})
    end, "GET", "", {["Content-Type"] = "application/json", ["Authorization"] = TOKEN})

    local result = Citizen.Await(p)
    if result then
        if result.code ~= 200 then
            return print('Error: Something went wrong with error code - ' .. result.code)
        end
        local data = json.decode(result.data)
        if data and data.avatar then
            return ('https://cdn.discordapp.com/avatars/%s/%s'):format(discordId, data.avatar)
        end
    end
end
--#endregion

AddEventHandler('playerDropped', function()
	local playerId <const> = source
	local player = playersData[tonumber(playerId)]
	if player then
		player = nil
	end
end)

RegisterNetEvent('ev:updateKillerData', function(data)
    if data then
        if type(data) ~= "table" then
            return print('Sus')
        else
            if type(data[1]) ~= "string" and type(data[2]) ~= "string" then
                return print('sus')
            end
            local playerId = tonumber(data[1])
            local targetId = tonumber(data[2])
            if playerId ~= targetId then
                local playerData = playersData[playerId]
                local targetData = playersData[targetId]
                if playerData and targetData then
                    if playerData.license and targetData.license then
                        local queries = {
                            { query = 'UPDATE `ev_leaderboard` SET kills = ?, deaths = ? WHERE license = ?', values = {playerData.kills + 1, playerData.deaths, playerData.license} },
                            { query = 'UPDATE `ev_leaderboard` SET kills = ?, deaths = ? WHERE license = ?', values = {targetData.kills, targetData.deaths + 1, targetData.license} }
                        }
                        exports.oxmysql:transaction(queries, function(result)
                            playerData.kills = playerData.kills + 1
                            targetData.deaths = targetData.deaths + 1
                        end)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('ev:playerSet', function()
    local playerId <const> = source
    local license = getLicense(playerId)
    if license then
        local p = promise.new()
        exports.oxmysql:single('SELECT * FROM ev_leaderboard WHERE license = ?', {license}, function(result)
            if result then
                p:resolve({license = result.license, kills = tonumber(result.kills), deaths = tonumber(result.deaths)})
            else
                exports.oxmysql:insert('INSERT INTO ev_leaderboard (license, kills, deaths) VALUES (?, ?, ?) ', {license, '0', '0'}, function(id)
                    if id then
                        p:resolve({license = license, kills = 0, deaths = 0})
                    end
                end)
            end
        end)
        local result = Citizen.Await(p)
        playersData[playerId] = result
    end
end)

--#region Commands
RegisterCommand('score', function(source)
    local playerId <const> = source
    local playerData = playersData[playerId]
    if playerData then
        TriggerClientEvent('ev:showLeaderboard', {kills = playerData.kills, deaths = playerData.deaths, kd = (playerData.kills / playerData.deaths)})
    end
end)

RegisterCommand('showLeaderboard', function(source)
    local playerId <const> = source
    local identifier = getLicense(source)
    if identifier then
        local p = promise.new()
        exports.oxmysql:execute('SELECT * FROM ev_leaderboard', function(result)
            if result then
                local data = {}
                for i = 1, #result do
                    insert(data, tonumber(result[i].kills))
                end
                table.sort(data, function (a, b)
                    return a > b
                end)
                p:resolve({data})
            end
        end)
    end
end)
--#endregion
