-- Holy webhook system by god nediad

---@class discord.webhook.field
---@field name string 256 symbols
---@field value string 1024 symbols
---@field inline? boolean

---@alias discord.webhook.fields discord.webhook.field[]

---@class discord.webhook.image
---@field url string

---@class discord.webhook.footer
---@field icon_url? string
---@field text string 2048 symbols

---@class discord.webhook.author
---@field icon_url? string
---@field name string 256 symbols
---@field url? string

---@class discord.webhook.embed
---@field title? string 256 symbols
---@field description? string 4096 symbols
---@field color? number decimal
---@field fields? discord.webhook.fields
---@field thumbnail? discord.webhook.image
---@field image? discord.webhook.image
---@field author? discord.webhook.author
---@field footer? discord.webhook.footer
---@field timestamp? string | osdate ISO 8601
local embed = { } do
    embed.__index = embed

    function embed:begin()
        self.begin = nil

        return self
    end

    ---@param str string 256 symbols
    function embed:setTitle(str)
        self.title = str

        return self
    end

    ---@param str string 4096 symbols
    function embed:setDescription(str)
        self.description = str

        return self
    end

    -- Append description content.
    ---@param str string 4096 symbols
    function embed:append(str)
        self.description = (self.description or '') .. str

        return self
    end

    ---@param url string
    function embed:setThumbnail(url)
        self.thumbnail = { url = url }

        return self
    end

    ---@param url string
    function embed:setImage(url)
        self.image = { url = url }

        return self
    end

    ---@param name string 256 symbols
    ---@param value string 1024 symbols
    ---@param inline? boolean
    function embed:newField(name, value, inline)
        self.fields = self.fields or { }
        table.insert(self.fields, { name = name, value = value, inline = inline })
        
        return self
    end

    ---@param name string 256 symbols
    ---@param icon_url? string
    ---@param url? string
    function embed:setAuthor(name, icon_url, url)
        self.author = { name = name, icon_url = icon_url, url = url }
        
        return self
    end

    ---@param text string 2048 symbols
    ---@param icon_url? string
    function embed:setFooter(text, icon_url)
        self.footer = { text = text, icon_url = icon_url }
        
        return self
    end

    ---@param unix? number
    function embed:setTimestamp(unix)
        unix = unix or os.time()
        self.timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', unix)

        return self
    end

    ---@param hex string HEX
    ---@return discord.webhook.embed
    function embed:setHEX(hex)
        hex = hex:gsub('^#', '') -- remove "#"
        self.color = tonumber(hex, 16)

        return self
    end

    ---@return table
    function embed:getPayload()
        return { -- holyshit letsgo
            title = self.title,
            description = self.description,
            color = self.color,
            fields = self.fields,
            thumbnail = self.thumbnail,
            image = self.image,
            author = self.author,
            footer = self.footer,
            timestamp = self.timestamp
        }
    end
end

---@alias discord.webhook.embeds discord.webhook.embed[]

---@class Webhook
---@field url string
---@field username? string
---@field avatar_url? string
---@field content? string
---@field tts? boolean
---@field embeds? discord.webhook.embeds
local webhook = { } do
    webhook.__index = webhook

    function webhook:begin(url)
        self.begin = nil -- Press F
        self.url = url
        
        return self
    end

    ---@return discord.webhook.embed
    function webhook:newEmbed()
        self.embeds = self.embeds or { }
        local object = setmetatable({ }, { __index = embed }):begin()
        table.insert(self.embeds, object)

        return object
    end

    ---@param username? string
    ---@param avatar_url? string
    function webhook:setUser(username, avatar_url)
        self.username = username
        self.avatar_url = avatar_url

        return self
    end

    ---@param str string 2000 symbols
    function webhook:setContent(str)
        self.content = str

        return self
    end

    -- Append text to content.
    ---@param str string 2000 symbols
    function webhook:append(str)
        self.content = (self.content or '') .. str

        return self
    end

    ---@param tts boolean
    function webhook:setTTS(tts)
        self.tts = tts
        
        return self
    end

    -- Push webhook
    ---@return boolean, table?
    function webhook:push()
        if not self.url or #self.url < 1 or not self.url:find('^https://discord.com') then return false end

        local headers = {
            ['Content-Type'] = 'application/json'
        }

        local payload = {
            username = self.username,
            avatar_url = self.avatar_url,
            content = self.content,
            tts = self.tts,
            embeds = (self.embeds and #self.embeds > 0) and { } or nil,
        }

        -- parsing embeds
        if payload.embeds then
            for k, data in self.embeds do
                table.insert(payload.embeds, data:getPayload())
            end
        end

        local body = game:GetService('HttpService'):JSONEncode(payload)

        if request then
            -- ^^ if env have "request"

            local response = request({
                Url = self.url,
                Method = 'POST',
                Headers = headers,
                Body = body
            })

            return response.Success, response
        elseif game.HttpPost then
            return select(1, pcall(game.HttpPost, game, self.url, body, headers))
        end

        return false
    end
end

-- idk
local hooks = { stack = {} } do
    ---@class Hook
    ---@field fn function
    ---@field args any[]
    local hook = {} do
        hook.__index = hook

        function hook:begin(fn, ...)
            self.begin = nil
            self.args = { ... }
            self.fn = fn

            table.insert(hooks.stack, self)

            return self
        end

        function hook:unhook(cleanup)
            if self.fn and self.args then
                if cleanup then
                    local index = table.find(hooks.stack, self)
                    if index then table.remove(hooks.stack, index) end
                end

                return pcall(self.fn, table.unpack(self.args))
            end

            return false
        end
    end

    function hooks.unhook()
        for _, self in ipairs(hooks.stack) do
            self:unhook(false)
        end

        hooks.stack = {}
    end

    function hooks.new(fn, ...)
        if type(fn) ~= 'function' then return false end
        return setmetatable({ }, { __index = hook }):begin(fn, ...)
    end

    function hooks.connection(connection)
        if typeof(connection) ~= 'Instance' or not connection:IsA('RBXScriptConnection') then return false end
        return hooks.new(connection.Disconnect, connection)
    end

    hooks.hook = hook
end

-- ok now super mega fly
local fly = { } do
    fly.connection = nil
    fly.velocity = nil
    fly.speed = 16

    ---@return boolean
    function fly.enable()
        if fly.connection then return false end
        local self = game:GetService('Players').LocalPlayer
        local char = self.Character
        local humanoid = char and char:FindFirstChild('Humanoid')
        
        local head = char and char:FindFirstChild('Head')
        local root = char and char:FindFirstChild('HumanoidRootPart')
        if not char then return false end

        humanoid.PlatformStand = true
        head.Anchored = true

        local velocity = Instance.new('BodyVelocity')
        velocity.Velocity = Vector3.new(0, 0, 0)
        velocity.MaxForce = Vector3.new(0, 0, 0)
        velocity.Parent = root

        fly.velocity = velocity

        fly.connection = game:GetService('RunService').Heartbeat:Connect(function(delta)
            local camera = workspace.CurrentCamera

            local moveDirection = humanoid.MoveDirection * (fly.speed * delta)
            local cameraPos = camera.CFrame.Position
            local headPosition = head.CFrame.Position

            local objectSpaceVelocity = CFrame.new(cameraPos, Vector3.new(headPosition.X, cameraPos.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
            head.CFrame = CFrame.new(headPosition) * (camera.CFrame - cameraPos) * CFrame.new(objectSpaceVelocity)
        end)

        return true
    end

    ---@return boolean
    function fly.reset()
        if not fly.connection then return false end

        fly.connection:Disconnect()
        fly.connection = nil

        local self = game:GetService('Players').LocalPlayer
        local char = self.Character
        local humanoid = char and char:FindFirstChild('Humanoid')
        local head = char and char:FindFirstChild('Head')
        local root = char and char:FindFirstChild('HumanoidRootPart')

        humanoid.PlatformStand = false
        head.Anchored = false

        if fly.velocity then
            fly.velocity:Destroy()
            fly.velocity = nil
        end

        if root then
            root.Velocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end

        for _, part in char:GetDescendants() do
            if part:IsA('BasePart') then
                part.Velocity = Vector3.new(0, 0, 0)
                part.RotVelocity = Vector3.new(0, 0, 0)
                if part.AssemblyLinearVelocity then
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
                if part.AssemblyAngularVelocity then
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end

        return true
    end
end

-- nowclip
local noclip = { } do
    noclip.connection = nil
    noclip.collisions = {}

    ---@return boolean
    function noclip.enable()
        if noclip.connection then return false end
        
        local self = game:GetService('Players').LocalPlayer
        local char = self.Character
        if not char then return false end

        for _, part in char:GetDescendants() do
            if part:IsA('BasePart') then
                noclip.collisions[part] = part.CanCollide
            end
        end

        noclip.connection = game:GetService('RunService').Stepped:Connect(function()
            local char = self.Character
            if not char then return end

            for _, part in char:GetDescendants() do
                if part:IsA('BasePart') then
                    part.CanCollide = false
                end
            end
        end)

        return true
    end

    ---@return boolean
    function noclip.reset()
        if not noclip.connection then return false end

        noclip.connection:Disconnect()
        noclip.connection = nil

        local self = game:GetService('Players').LocalPlayer
        local char = self.Character
        if not char then return false end

        for _, part in char:GetDescendants() do
            if part:IsA('BasePart') then
                if noclip.collisions[part] ~= nil then
                    part.CanCollide = noclip.collisions[part]
                else
                    if part.Name == 'HumanoidRootPart' then
                        part.CanCollide = false
                    else
                        part.CanCollide = true
                    end
                end
            end
        end

        noclip.collisions = {}

        return true
    end

    noclip.onCharacter = game:GetService('Players').LocalPlayer.CharacterAdded:Connect(function(char)
        if noclip.connection then
            task.wait(0.1)
            noclip.collisions = {}
            for _, part in char:GetDescendants() do
                if part:IsA('BasePart') then
                    noclip.collisions[part] = part.CanCollide
                end
            end
        end
    end)
end

-- server hop
local serverhop = { } do
    ---@param toLowPop boolean Teleport to less players.
    ---@return boolean, string?
    function serverhop.teleport(toLowPop)
        local ok, err = pcall(function()
            local servers = {}

            local req = game:HttpGet('https://games.roblox.com/v1/games/' .. game.PlaceId .. '/servers/Public?sortOrder=' .. (toLowPop and 'Asc' or 'Desc') .. '&limit=100&excludeFullGames=true')
            local body = game:GetService('HttpService'):JSONDecode(req)

            if body and body.data then
                for _, v in next, body.data do
                    if type(v) == 'table' and tonumber(v.playing) and tonumber(v.maxPlayers) then
                        if v.playing < v.maxPlayers and v.id ~= game.JobId then
                            table.insert(servers, { id = v.id, playing = v.playing, maxPlayers = v.maxPlayers, ping = v.ping or 0 })
                        end
                    end
                end
            end

            if #servers > 0 then
                table.sort(servers, function(a, b)
                    if toLowPop then
                        return a.playing < b.playing
                    else
                        return a.playing > b.playing
                    end
                end)
                
                local pool = {}
                for i = 1, math.min(10, #servers) do table.insert(pool, servers[i]) end
                
                local server = pool[math.random(#pool)]
                game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, server.id, game:GetService('Players').LocalPlayer) -- Is this async?
                return string.format('Teleporting to server (%d/%d players)...', server.playing, server.maxPlayers)
            else
                return 'No available servers found'
            end
        end)

        return ok, err
    end
end

local lib = { } do
    lib.serverhop = serverhop
    lib.noclip = noclip
    lib.hooks = hooks
    lib.fly = fly
    
    -- Create new webhook object.
    ---@param url string https://discord ...
    ---@return Webhook
    function lib.createWebhook(url)
        return setmetatable({ }, { __index = webhook }):begin(url)
    end

    ---@class pretty_table.opts
    ---@field maxDepth number? max depth
    ---@field indent number? indent

    ---@param tbl table | any
    ---@param opts pretty_table.opts?s
    ---@return string
    function lib.prettyTable(tbl, opts)
        opts = type(opts) == 'table' and opts or {}
        local maxDepth = type(opts.maxDepth) == 'number' and opts.maxDepth or math.huge
        local startIndent = type(opts.indent) == 'number' and opts.indent or 0

        local out = {}
        local visiting = {}

        local function indent(level)
            return string.rep('\t', level)
        end

        local function prettyValue(v)
            if type(v) == 'string' then
                return string.format('%q', v)
            end
            return tostring(v)
        end

        local function isEmptyTable(t)
            return next(t) == nil
        end

        local function tableAddr(t)
            return tostring(t)
        end

        local function dump(t, depth)
            local tp = type(t)
            if tp ~= 'table' then
                table.insert(out, prettyValue(t))
                return
            end

            local addr = tableAddr(t)

            if visiting[t] then
                table.insert(out, '<recursive ' .. addr .. '>')
                return
            end

            if depth >= maxDepth then
                table.insert(out, '{ ... } -- ' .. addr)
                return
            end

            if isEmptyTable(t) then
                table.insert(out, '{ } -- ' .. addr)
                return
            end

            visiting[t] = true

            table.insert(out, '{ -- ' .. addr .. '\n')

            local k, v = next(t, nil)
            while k ~= nil do
                table.insert(out, indent(depth + 1))
                table.insert(out, '[' .. prettyValue(k) .. '] = ')

                if type(v) == 'table' then
                    dump(v, depth + 1)
                else
                    table.insert(out, prettyValue(v))
                end

                table.insert(out, ',\n')
                k, v = next(t, k)
            end

            table.insert(out, indent(depth) .. '}')
            visiting[t] = nil
        end

        dump(tbl, startIndent)
        return table.concat(out)
    end
end

return lib