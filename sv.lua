local insert = table.insert
local sort = table.sort

local playersData = {}
local TOKEN = "Bot Nzc3MDU1MTA4MDEzNzUyMzIw.X6929g.ScaHvW1Ogo3soA6WcFSHyJRNh5I"
local DEFAULT_ID = '110103088488005632'


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
---If discord id is not nil, then it returns avatar
---@param discordId number
---@return string
local function getPlayerFromDiscord(discordId)
    if not discordId then
        return false
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
---Fetches the discord api for an user.
---If discord id is not nil, then it returns avatar
---@param discordId number
---@return string
local function getDiscordName(discordId)
    if not discordId then
        return false
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
        if data and data.username then
            return data.username
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
    local discord = getDiscordId(playerId) or DEFAULT_ID
    if license then
        if discord then
            local p = promise.new()
            exports.oxmysql:single('SELECT * FROM ev_leaderboard WHERE license = ?', {license}, function(result)
                if result then
                    p:resolve({license = result.license, discord = result.discord, kills = tonumber(result.kills), deaths = tonumber(result.deaths)})
                else
                    exports.oxmysql:insert('INSERT INTO ev_leaderboard (license, discord, kills, deaths) VALUES (?, ?, ?, ?) ', {license, discord, '0', '0'}, function(id)
                        if id then
                            p:resolve({license = license, discord = getDiscordName(discord), kills = 0, deaths = 0})
                        end
                    end)
                end
            end)
            local result = Citizen.Await(p)
            playersData[playerId] = result
        end
    end
end)

--#region Commands
RegisterCommand('score', function(source)
    local playerId <const> = source
    local playerData = playersData[playerId]
    if playerData then
        TriggerClientEvent('ev:showLeaderboard', playerId, false, {avatar = getPlayerFromDiscord(playerData.discord), discord = getDiscordName(playerData.discord), kills = playerData.kills, deaths = playerData.deaths, kd = math.floor(playerData.kills / playerData.deaths)})
    end
end)

RegisterCommand('showLeaderboard', function(source)
    local playerId <const> = source
    local identifier = getLicense(playerId)
    if identifier then
        local p = promise.new()
        exports.oxmysql:execute('SELECT discord, kills FROM ev_leaderboard', function(result)
            if result then
                local data = {}
                for i = 1, #result do
                    insert(data, {discord = getPlayerFromDiscord(result[i].discord), kills = tonumber(result[i].kills), name = getDiscordName(result[i].discord)})
                end
                sort(data, function (a, b)
                    return a.kills > b.kills
                end)
                p:resolve({data[1] or nil, data[2] or nil, data[3] or nil})
            end
        end)
        local result = Citizen.Await(p)
        if type(result) ~="table" then
            return false, print('Cannot return table data sus')
        end
        TriggerClientEvent('ev:showLeaderboard', playerId, true, result)
    end
end)
--#endregion
