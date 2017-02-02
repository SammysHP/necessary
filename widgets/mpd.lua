local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local textbox = require("wibox.widget.textbox")
local mpc = require("necessary.libs.mpc")

local mpd = {}

function mpd:_update_widget()
    local state = self._state.status.state

    local function playlist_status()
        local total = tonumber(self._state.status.playlistlength)
        local track = self._state.status.song and tonumber(self._state.status.song) or 0
        track = total > 0 and track + 1 or 0

        return track .. "/" .. total
    end

    if state == "play" then
        self.widget.text = "▶ " .. playlist_status()
    elseif state == "pause" then
        self.widget.text = "⏸ " .. playlist_status()
    elseif state == "stop" then
        self.widget.text = "⏹ " .. playlist_status()
    else
        self.widget.text = "❌ -/-"
    end

    local tooltip_text = ""
    if self._state.currentsong.title then
        tooltip_text = tooltip_text .. '<span weight="bold" size="larger">' .. self._state.currentsong.title .. '</span>'
        if self._state.currentsong.album then
            tooltip_text = tooltip_text .. '\nfrom <span weight="bold">' .. self._state.currentsong.album .. '</span>'
        end
        if self._state.currentsong.album then
            tooltip_text = tooltip_text .. '\nby <span weight="bold">' .. self._state.currentsong.artist .. '</span>'
        end
    else
        tooltip_text = ''
    end

    self._tooltip.markup = tooltip_text
end

function mpd:toggle_play()
    self._client:toggle_play()
end

function mpd:next()
    self._client:send("next")
end

function mpd:previous()
    self._client:send("previous")
end

--- Create a new mpd widget.
-- @tparam table args Arguments.
-- @tparam[opt=localhost] string args.host MPD server host
-- @tparam[opt=port] number args.host MPD server port
-- @tparam[opt=] string args.password MPD server password
-- @tparam[opt=Mod4] string args.modkey Modkey for mouse bindings
-- @tparam[opt=false] boolean args.delayed_connect Connect to localhost only if mpd is running
-- @tparam[opt=60] number args.delayed_timeout Timeout for delayed connect retry
-- @tparam[opt=ncmpcpp] string args.client MPD client to launch
-- @tparam[opt=x-terminal-emulator] string args.terminal Terminal emulator for ncmpcpp fallback
-- @treturn mpd
-- @function necessary.widgets.mpd.new
function mpd.new(args)
    local self = setmetatable({
        _state = {
            status      = { state = "err", playlistlength = 0, song = 0 },
            currentsong = {},
        },
    }, { __index = mpd })

    args = args or {}
    local host            = args.host or "localhost"
    local port            = args.port or 6600
    local password        = args.password or ""
    local modkey          = args.modkey or modkey or "Mod4"
    local delayed_connect = host == "localhost" and args.delayed_connect
    local delayed_timeout = args.delayed_timeout or 60
    local terminal        = args.terminal or terminal or "x-terminal-emulator"
    local mpdclient       = args.client or terminal .. " -e ncmpcpp"

    self.widget = textbox()

    self._tooltip = awful.tooltip({
        objects = { self.widget },
        delay_show = beautiful.tooltip_delay or 0,
    })

    self._client = mpc.new(host, port, password,
        function(err)
            self._state = {
                status      = { state = "err", playlistlength = 0, song = 0 },
                currentsong = {},
            }
            self:_update_widget()
        end,

        "status", function(success, result)
            if not success then return end
            self._state.status = result
        end,

        "currentsong", function(success, result)
            if not success then return end
            self._state.currentsong = result
            self:_update_widget()
        end
    )

    self:_update_widget()

    if delayed_connect then
        -- TODO Update to awesome > 4.0
        local timer = gears.timer({
            timeout   = delayed_timeout,
            -- autostart = true,
            -- callback  = function()
            -- end
        })
        timer:connect_signal("timeout", function()
            timer:stop()
            awful.spawn.easy_async("pgrep -u mpd mpd", function(stdout, stderr, reason, exit_code)
                if exit_code == 0 then
                    self._client:_connect()
                else
                    timer:start()
                end
            end)
        end)
        timer:start()
        timer:emit_signal("timeout")
    else
        self._client:_connect()
    end

    self.widget:buttons(awful.util.table.join(
        awful.button({        }, 1, function() self:toggle_play() end),
        awful.button({        }, 3, function()
                                        awful.spawn(mpdclient, false)
                                    end),
        awful.button({ modkey }, 1, function() self:previous() end),
        awful.button({ modkey }, 3, function() self:next() end)
    ))

    return self
end

return mpd
