local awful = require("awful")
local gears = require("gears")
local textbox = require("wibox.widget.textbox")

local volume = {}

function volume:_update_widget()
    awful.spawn.easy_async("amixer -M sget " .. self._channel, function(stdout, stderr, reason, exit_code)
        local status = stdout
        local volume = string.match(status, "(%d?%d?%d)%%")

        status = string.match(status, "%[(o[^%]]*)%]")

        if not status then
            volume = "🔊 ?"
        elseif string.find(status, "on", 1, true) then
            volume = "🔊 " .. volume
        else
            volume = "🔇 " .. volume
        end

        self.widget.text = volume
    end)
end

function volume:raise()
    awful.spawn("amixer -q set " .. self._channel .. " 1+ unmute", false)
    self:_update_widget()
end

function volume:lower()
    awful.spawn("amixer -q set " .. self._channel .. " 1- unmute", false)
    self:_update_widget()
end

function volume:mute()
    awful.spawn("amixer -q set " .. self._channel .. " toggle", false)
    self:_update_widget()
end

--- Create a new volume widget.
-- @treturn volume
-- @function necessary.widgets.volume.new
function volume.new(args)
    local self = setmetatable({}, { __index = volume })

    local args = args or {}
    local timeout = args.timeout or 30
    local terminal = terminal or args.terminal or "x-terminal-emulator"
    self._channel = args.channel or "Master"

    self.widget = textbox()

    self.widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function() self:mute() end),
        awful.button({ }, 3, function() awful.spawn(terminal .. " -e alsamixer", false) end),
        awful.button({ }, 4, function() self:raise() end),
        awful.button({ }, 5, function() self:lower() end)
    ))

    gears.timer.start_new(timeout, function() self:_update_widget(); return true end):emit_signal("timeout")

    return self
end

return volume
