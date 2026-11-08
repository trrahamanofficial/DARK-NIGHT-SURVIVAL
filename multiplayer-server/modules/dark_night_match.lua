-- DARK NIGHT: SURVIVAL authoritative co-op match.
-- Clients submit input intents only. The server owns player positions and match state.
local M = {}
local OP_INPUT, OP_STATE = 1, 2
local MAX_PLAYERS, TICK_RATE, MOVE_SPEED = 4, 10, 4.0
local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end
local function public_state(state)
  local players = {}
  for user_id, p in pairs(state.players) do
    players[user_id] = { x = p.x, z = p.z, yaw = p.yaw, ready = p.ready }
  end
  return { tick = state.tick, players = players, host_user_id = state.host_user_id }
end
function M.match_init(context, params)
  return {
    state = { tick = 0, players = {}, host_user_id = nil, created_at = os.time() },
    tick_rate = TICK_RATE,
    label = nk.json_encode({ mode = "coop", max_players = MAX_PLAYERS, protocol = 1 })
  }
end
function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
  local count = 0
  for _ in pairs(state.players) do count = count + 1 end
  if count >= MAX_PLAYERS and not state.players[presence.user_id] then
    return nil, "This co-op session is full."
  end
  return state
end
function M.match_join(context, dispatcher, tick, state, presences)
  for _, presence in ipairs(presences) do
    if not state.players[presence.user_id] then
      state.players[presence.user_id] = { x = 0, z = 0, yaw = 0, ready = false, last_input_tick = tick }
      if not state.host_user_id then state.host_user_id = presence.user_id end
    end
  end
  dispatcher.broadcast_message(OP_STATE, nk.json_encode(public_state(state)), nil, nil, true)
  return state
end
function M.match_leave(context, dispatcher, tick, state, presences)
  for _, presence in ipairs(presences) do state.players[presence.user_id] = nil end
  if state.host_user_id and not state.players[state.host_user_id] then
    state.host_user_id = nil
    for user_id in pairs(state.players) do state.host_user_id = user_id; break end
  end
  return state
end
function M.match_loop(context, dispatcher, tick, state, messages)
  state.tick = tick
  for _, message in ipairs(messages) do
    if message.op_code == OP_INPUT then
      local player = state.players[message.sender.user_id]
      if player then
        local ok, input = pcall(nk.json_decode, message.data)
        if ok and type(input) == "table" then
          local x = clamp(tonumber(input.move_x) or 0, -1, 1)
          local z = clamp(tonumber(input.move_z) or 0, -1, 1)
          local yaw = tonumber(input.yaw) or player.yaw
          local length = math.sqrt(x*x + z*z)
          if length > 1 then x = x / length; z = z / length end
          player.x = clamp(player.x + x * MOVE_SPEED / TICK_RATE, -500, 500)
          player.z = clamp(player.z + z * MOVE_SPEED / TICK_RATE, -500, 500)
          player.yaw = clamp(yaw, -100000, 100000)
          player.last_input_tick = tick
        end
      end
    end
  end
  if tick % 2 == 0 then
    dispatcher.broadcast_message(OP_STATE, nk.json_encode(public_state(state)), nil, nil, true)
  end
  return state
end
function M.match_terminate(context, dispatcher, tick, state, grace_seconds) return state end
function M.match_signal(context, dispatcher, tick, state, data) return state, data end
nk.register_match("dark_night_coop", M)
