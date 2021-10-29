local botToken <const> = "YOUR_BOT_TOKEN" -- Add your discord bot with admin perms token here.

local insert = table.insert
local sort = table.sort

local playersData = {}
local TOKEN <const> = "Bot "  .. botToken --Concatenated token
local DEFAULT_ID <const> = '903150326155182151' -- Just in case the player doesn't have discord open


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
    return DEFAULT_ID
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

AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() == name then
        local p = promise.new()
        exports.oxmysql:execute('SELECT * FROM ev_leaderboard', {}, function(result)
            if result and result[1] then
                return p:resolve(result)
            else
                return p:resolve({})
            end
        end)
        local result = Citizen.Await(p)
        for i = 1, #result, 1 do
            playersData[result[i].license] = result[i]
        end
    end
end)

AddEventHandler('playerDropped', function()
	local playerId <const> = source
	local playerData = playersData[getLicense(playerId)]
	if playerData then
        exports.oxmysql:updateSync('UPDATE ev_leaderboard SET kills = ?, deaths = ?, headshots = ? WHERE license = ? ', {playerData.kills, playerData.deaths, playerData.headshots, playerData.license})
	end
end)

RegisterNetEvent('ev:playerSet', function()
    local playerId <const> = source
    local license = getLicense(playerId)
    local discordId = getDiscordId(playerId)
    if license then
        local playerData = playersData[license]
        local name = getDiscordName(discordId)
        local avatar = getPlayerFromDiscord(discordId)
        if playerData then
            return
        end
        local p = promise.new()
        exports.oxmysql:insert('INSERT INTO ev_leaderboard (license, kills, deaths, headshots, avatar, name) VALUES (?, ?, ?, ?, ?, ?) ', {license, '0', '0', '0', avatar, name}, function(id)
            if id then
                p:resolve({license = license, kills = 0, deaths = 0, headshots = 0, avatar = avatar, name = name})
            end
        end)

        local result = Citizen.Await(p)
        playersData[result.license] = result
    end
end)


RegisterNetEvent('ev:updateKillerData', function(data)
    if data then
        if type(data) ~= "table" then
            return print('Sus')
        else
            if type(data[1]) ~= "string" and type(data[2]) ~= "string" and type(data[3]) == "number" then
                return print('sus')
            end
            local playerId = tonumber(data[1])
            local targetId = tonumber(data[2])
            local headshot = tonumber(data[3]) == 31086 and 1 or 0
            if playerId ~= targetId then
                local playerData = playersData[getLicense(playerId)]
                local targetData = playersData[getLicense(targetId)]
                if playerData and targetData then
                    if playerData.license and targetData.license then
                        playerData.kills = playerData.kills + 1
                        targetData.deaths = targetData.deaths + 1
                        playerData.headshots = playerData.headshots + headshot
                    end
                end
            end
        end
    end
end)

RegisterCommand('score', function(source)
    local playerId <const> = source
    local playerData = playersData[getLicense(playerId)]
    if playerData then
        local kd = 1.0
        if playerData.deaths > 0 then
            kd = playerData.kills / playerData.deaths
        end
        TriggerClientEvent('ev:showLeaderboard', playerId, false, {avatar = playerData.avatar, discord = playerData.name, kills = playerData.kills, deaths = playerData.deaths, kd = kd, headshots = playerData.headshots})
    end
end)


RegisterCommand('showLeaderboard', function(source)
    local playerId <const> = source
    local data = {}
    for _, v in pairs(playersData) do
        insert(data, {discord = v.avatar, kills = tonumber(v.kills), name = v.name})
    end
    sort(data, function(a, b)
        return a.kills > b.kills
    end)
    TriggerClientEvent('ev:showLeaderboard', playerId, true, data)
end)