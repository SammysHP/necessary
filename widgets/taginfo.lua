local textbox = require("wibox.widget.textbox")
local awful = require("awful")

local taginfo = {}

local function refresh(w)
    return function (tag)
        if not tag then return end
        w:set_text(tag.master_count .. "/" .. tag.column_count .. " ")
    end
end

function taginfo.new(screen)
    local w = textbox()
    local callback = refresh(w)

    callback(screen.selected_tag)

    awful.tag.attached_connect_signal(screen, "property::master_count", callback)
    awful.tag.attached_connect_signal(screen, "property::column_count", callback)
    awful.tag.attached_connect_signal(screen, "property::selected", callback)

    return { widget = w }
end

return setmetatable(taginfo, { __call = function(_, ...) return taginfo.new(...) end })
