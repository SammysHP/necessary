local imagebox = require("wibox.widget.imagebox")

local icongenerator = {}

function icongenerator.new(path, extension, width)
    extension = extension or "png"

    return setmetatable({}, {
        __mode = 'k',
        __index = function(self, key)
            -- -- Should not happen
            -- if rawget(self, key) ~= nil then
            --     return self[key]
            -- end

            local icon = imagebox(path .. key .. "." .. extension, false)

            if width then
                icon.forced_width = width
            end

            self[key] = icon
            return icon
        end
    })
end

return icongenerator
