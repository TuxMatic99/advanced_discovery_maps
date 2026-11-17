-- ADM: registro de medios confirmados por cliente (Luanti 5.10+).
-- Un PNG presente en el disco NO implica que el cliente pueda dibujarlo.
local core = minetest
local P = persistent_map
local sessions = {}
local MAX_INFLIGHT = 3
local RETRY_US = 3000000
local TIMEOUT_US = 15000000
local function now() return core.get_us_time() end

local function session_for(name)
    local session = sessions[name]
    if not session then
        session = {files = {}, inflight = 0, epoch = 0, serial = 0}
        sessions[name] = session
    end
    return session
end

-- Los transmisores ya existentes pueden registrar archivos entregados sin reenviarlos.
function P.media_mark_ready(name, filename)
    if type(name) ~= "string" or name == "" or type(filename) ~= "string" then return end
    local s = session_for(name)
    local old = s.files[filename]
    if old and old.status == "ready" then return end
    if old and old.status == "pending" then
        s.inflight = math.max(0, s.inflight - 1)
    end
    s.files[filename] = {status = "ready"}
    s.epoch = s.epoch + 1
end

function P.media_epoch(name)
    local s = sessions[name]
    return s and s.epoch or 0
end

function P.media_is_ready(name, filename)
    local s = sessions[name]
    return s ~= nil and s.files[filename] ~= nil
        and s.files[filename].status == "ready"
end

-- True: disponible en cliente. False: ausente, pendiente o en espera.
function P.media_request(name, filename)
    if type(filename) ~= "string" or not filename:match("^tile_[%w_%-]+%.png$") then
        return false
    end
    local player = core.get_player_by_name(name)
    if not player then return false end
    local s = session_for(name)
    local t = now()
    local record = s.files[filename]
    if record then
        if record.status == "ready" then return true end
        if record.status == "pending" then
            if t - record.since <= TIMEOUT_US then return false end
            -- Transferencia perdida: permitir un reintento acotado.
            s.inflight = math.max(0, s.inflight - 1)
            record.status, record.retry_at = "retry", t + RETRY_US
        end
        if record.retry_at and t < record.retry_at then return false end
    end
    if s.inflight >= MAX_INFLIGHT then return false end

    local filepath = P.map_path .. filename
    local f = io.open(filepath, "rb")
    if not f then return false end
    f:close()

    s.serial = s.serial + 1
    local ticket = s.serial
    s.files[filename] = {status = "pending", since = t, ticket = ticket}
    s.inflight = s.inflight + 1
    local accepted = core.dynamic_add_media({filepath = filepath, to_player = name}, function(pname)
        if sessions[name] ~= s then return end
        local current = s.files[filename]
        if not current or current.ticket ~= ticket then return end
        s.inflight = math.max(0, s.inflight - 1)
        if pname == name then
            current.status = "ready"
            s.epoch = s.epoch + 1
        else
            current.status = "retry"
            current.retry_at = now() + RETRY_US
        end
    end)
    if not accepted then
        local current = s.files[filename]
        if current and current.ticket == ticket then
            s.inflight = math.max(0, s.inflight - 1)
            current.status, current.retry_at = "retry", t + RETRY_US
        end
        return false
    end
    return false
end

-- P5A: recuperación de transferencias atascadas, sin sondear cada fotograma.
local housekeeping_elapsed = 0
core.register_globalstep(function(dt)
    housekeeping_elapsed = housekeeping_elapsed + dt
    if housekeeping_elapsed < 1 then return end
    housekeeping_elapsed = 0
    local t = now()
    for _, session in pairs(sessions) do
        for _, record in pairs(session.files) do
            if record.status == "pending" and t - record.since > TIMEOUT_US then
                session.inflight = math.max(0, session.inflight - 1)
                record.status = "retry"
                record.retry_at = t + RETRY_US
            end
        end
    end
end)

core.register_on_leaveplayer(function(player)
    sessions[player:get_player_name()] = nil
end)
