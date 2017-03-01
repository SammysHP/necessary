local awful = require("awful")
local gears = require("gears")
local capi = {
    client = client,
}

local dropdown = {}

--- Toggle a dropdown client.
-- @param string prog_cmd The command to run
-- @tparam table args Arguments.
-- @tparam[opt=1] number args.width Width of the client 0..1 in percent, above 1 in pixels
-- @tparam[opt=0.4] number args.height Height of the client 0..1 in percent, above 1 in pixels
-- @tparam[opt=false] boolean args.sticky If the client should stay visible on all tags
-- @tparam[opt=awful.screen.focused()] screen args.screen Screen on which the client should be toggled
-- @tparam[opt=awful.placement.top] object args.placement The placement of the client
-- @function necessary.utils.dropdown.toggle
function dropdown.toggle(prog_cmd, args)
    args            = args           or {}
    local width     = args.width     or 1
    local height    = args.height    or 0.4
    local sticky    = args.sticky    or false
    local screen    = args.screen    or awful.screen.focused()
    local placement = args.placement or awful.placement.top

    -- at least one screen should be available
    if not screen then return end

    -- Create weak value table that stores references to all dropdown clients on a screen.
    -- Each screen can contain one client per command, but multiple commands are possible.
    if not screen.necessary_dropdown_clients then
        screen.necessary_dropdown_clients = setmetatable({}, { __mode = 'v' })
    end

    -- between 0 and 1 => percent, above 1 => pixels
    if width  <= 1 then width  = screen.workarea.width  * width  end
    if height <= 1 then height = screen.workarea.height * height end

    -- Helper that sets client properties so that they can be re-applied each time the client is toggled.
    local function setup_client(c)
        c.floating = true
        c.ontop = true
        c.above = true
        c.sticky = sticky
        c.size_hints_honor = false
        c.skip_taskbar = true
        c.titlebars_enabled = false
        c.width = width - 2 * c.border_width
        c.height = height - 2 * c.border_width
        placement(c)
        c:raise()
    end

    local c = screen.necessary_dropdown_clients[prog_cmd]
    if c and c.valid then
        -- client is available for this command

        -- move to selected tag
        if not c:isvisible() then
            c.hidden = true
            c:move_to_tag(screen.selected_tag)
        end

        -- toggle visibility
        if c.hidden then
            setup_client(c)
            c.hidden = false
            capi.client.focus = c
        else
            c.hidden = true
            c:tags({})
        end
    else
        -- no suitable client, create one
        awful.spawn(
            prog_cmd,
            {},
            function (c)
                screen.necessary_dropdown_clients[prog_cmd] = c

                -- Workaround to set client properties after all rules are applied
                -- See https://github.com/awesomeWM/awesome/pull/1487
                gears.timer.delayed_call(function() setup_client(c) end)
            end
        )
    end
end

return setmetatable(dropdown, { __call = function(_, ...) return dropdown.toggle(...) end })
