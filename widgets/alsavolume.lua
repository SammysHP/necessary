local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local textbox = require("wibox.widget.textbox")

local alsavolume = {}

function alsavolume:_update_widget()
    awful.spawn.easy_async("amixer -M sget " .. self._channel, function(stdout, stderr, reason, exit_code)
        local status = stdout
        local volume = string.match(status, "(%d?%d?%d)%%")
        local sscolor = beautiful.widget_fg_urgent or beautiful.bg_urgent or "#ff0000"
        local colorinactive = beautiful.widget_fg_inactive or beautiful.fg_normal or "#ffffff"

        status = string.match(status, "%[(o[^%]]*)%]")

        if not status then
            volume = "??"
        elseif string.find(status, "on", 1, true) then
            volume = volume .. "%"
        else
            volume = '<span strikethrough="true" strikethrough_color="' .. sscolor .. '" color="' .. colorinactive .. '">' .. volume .. '%</span>'
        end

        self.widget.markup = volume
    end)
end

function alsavolume:raise()
    awful.spawn("amixer -q set " .. self._channel .. " 1+ unmute", false)
    self:_update_widget()
end

function alsavolume:lower()
    awful.spawn("amixer -q set " .. self._channel .. " 1- unmute", false)
    self:_update_widget()
end

function alsavolume:mute()
    awful.spawn("amixer -q set " .. self._channel .. " toggle", false)
    self:_update_widget()
end

--- Create a new ALSA volume widget.
-- @tparam table args Arguments.
-- @tparam[opt=Master] string args.channel ALSA channel to monitor and control
-- @tparam[opt=x-terminal-emulator] string args.terminal Terminal emulator for alsamixer
-- @tparam[opt=30] number args.timeout Timeout for widget update
-- @treturn alsavolume
-- @function necessary.widgets.alsavolume.new
function alsavolume.new(args)
    local self = setmetatable({}, { __index = alsavolume })

    local args = args or {}
    local timeout = args.timeout or 30
    local terminal = args.terminal or terminal or "x-terminal-emulator"
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

return setmetatable(alsavolume, { __call = function(_, ...) return alsavolume.new(...) end })
