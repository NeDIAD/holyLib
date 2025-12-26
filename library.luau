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

local lib = { } do
    -- Create new webhook object.
    ---@param url string https://discord ...
    ---@return Webhook
    function lib.createWebhook(url)
        return setmetatable({ }, { __index = webhook }):begin(url)
    end
end