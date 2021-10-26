---@diagnostic disable: undefined-global
local botToken <const> = "YOUR_BOT_TOKEN" -- Add your discord bot with admin perms token here.

local insert = table.insert
local sort = table.sort

local playersData = {}
local TOKEN <const> = "Bot "  .. botToken --Concatenated token
local DEFAULT_ID <const> = '110103088488005632' -- I don't remember what this was used foR


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
AddEventHandler('onResourceStart', function(name)
    if GetResourceCurrentName() == name then
        local p = promise.new()
        exports.oxmysql:execute('SELECT * FROM ev_leaderboard', function(result)
            if result then
                local data = {}
                for i = 1, #result do
                    insert(data, result[i].identifier, {discord = result[i].discord, kills = tonumber(result[i].kills), deaths = tonumber(result[i].kills), name = getDiscordName(result[i].discord)})
                end
                return p:resolve({data})
            end
        end)
        local result = Citizen.Await(p)
        playersData = result
    end
end)

AddEventHandler('playerDropped', function()
	local playerId <const> = source
    local license = getLicense(playerId)
	local player = playersData[license]
	if player then
        exports.oxmysql:single('SELECT license FROM ev_leaderboard WHERE license = ?', {license}, function(result)
            if result then
                exports.oxmysql:insert('UPDATE ev_leaderboard SET kills = ?, kills = ? WHERE license = ? ', {player.kills, player.deaths, license}, function(id)
                    if id then
                        print('Update table for ' .. license)
                    end
                end)
            else
                exports.oxmysql:insert('INSERT INTO ev_leaderboard (license, discord, kills, deaths) VALUES (?, ?, ?, ?) ', {license, getDiscordId(playerId), player.kills, players.deaths}, function(id)
                    if id then
                        print('Created new table for ' .. license)
                    end
                end)
            end
        end)
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
            local playerLicense = getLicense(tonumber(data[1]))
            local targetLicense = getLicense(tonumber(data[2]))
            if playerId ~= targetId then
                local playerData = playersData[playerLicense]
                local targetData = playersData[targetLicense]
                if playerData and targetData then
                    playerData.kills = playersData.kills + 1
                    targetData.deaths = playerData.deaths + 1
                end
            end
        end
    end
end)

RegisterNetEvent('ev:playerSet', function()
    local playerId <const> = source
    local license = getLicense(playerId)
    if license then
        local playerData = playersData[license]
        if not playerData then
            local discordId = getDiscordId(playerId)
            playersData[license] = {discord = discordId, kills = 0, deaths = 0, name = getDiscordName(discordId)}
        end
    end
end)

--#region Commands
RegisterCommand('score', function(source)
    local playerId <const> = source
    local license = getLicense(playerId)
    if license then
        local playerData = playersData[license]
        if playerData then
            TriggerClientEvent('ev:showLeaderboard', playerId, false, {avatar = getPlayerFromDiscord(playerData.discord), discord = getDiscordName(playerData.discord), kills = playerData.kills, deaths = playerData.deaths, kd = math.floor(playerData.kills / playerData.deaths)})
        end
    end
end)

RegisterCommand('showLeaderboard', function(source)
    local playerId <const> = source
    local identifier = getLicense(playerId)
    if identifier then
        local data = playersData
        -- If this doesn't work the I'll have to organize data differently
        sort(data, function (a, b)
            return a.kills > b.kills
        end)
        if type(result) ~="table" then
            return false, print('Cannot return table data sus')
        end
        TriggerClientEvent('ev:showLeaderboard', playerId, true, data)
    end
end)
--#endregion
