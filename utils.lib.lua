local it = require('util.iterators')
local jsplit = require('util.jid').split
local mod_muc = module:depends('muc')

-- read allowed bot tokens from config
local ALLOWED_ZULIP_BOTS = module:get_option_array('allowed_zulip_bots', {})


-- Public functions

--- return iterator which iterates over each value in rooms _occupant table
-- @param table room
local function each_occupant(room)
  local function co_iter()
    for room_jid, occ_tbl in pairs(room._occupants) do
      local _, _, node = jsplit(room_jid)

      if node ~= 'focus' then
        coroutine.yield(occ_tbl)
      end
    end
  end

  return coroutine.wrap(function() co_iter() end)
end

--- returns iterator which iterates over each MUC room
-- compat with prosody MUC code < 0.11
local each_room do
  local rooms = rawget(mod_muc, 'rooms')

  each_room = rawget(mod_muc, 'each_room') or function() return it.values(rooms) end
end

--- returns the first session of occupants session table
-- @param table occupant
local function get_session(occupant)
  local _, session_stanza = next(occupant.sessions)

  return session_stanza
end

--- returns nick which is shown in jitsi frontend
-- @param table occupant
local function get_jitsi_nick_from_occupant(occupant)
  local stanza = get_session(occupant)

  return stanza:get_child_text('nick', 'http://jabber.org/protocol/nick')
end

--- returns the room object for the given room name
-- @param string room_name
local function get_room_from_room_name(room_name)
  for room in each_room() do
    local name = tostring(room:get_name()) or (room.jid and room.jid:match('^(.-)@.*$'))
    if room:get_name() == room_name then
      return room
    end
  end

  return nil
end

--- validate received bot token
-- @param string token
local function has_valid_bot_token(token)
  for _, btoken in ipairs(ALLOWED_ZULIP_BOTS) do
    if token == btoken then return true end
  end

  return false
end

--- parsed the received message
-- @param string msg
-- @param string trigger
local mention_patt = '^@%*%*%w+%*%*%s+([%w%_]+)%s?([%w%_%-]*).*$'
local priv_patt = '^([%w%_]+)%s?([%w%_%-]*).*$'
local function parse_message(msg, trigger)
  module:log('debug', 'Received message: %s', tostring(msg))
  if not msg or #msg <= 0 then
    module:log('debug', 'Received message is invalid')
    return nil
  end

  local cmd, arg
  local function process(c, a)
    cmd = c:lower()
    arg = a
  end

  if trigger == 'mention' then
    msg:gsub(mention_patt, process)
  else
    msg:gsub(priv_patt, process)
  end

  module:log('debug', 'Parsed command: %q', tostring(cmd))
  module:log('debug', 'Parsed args: %q', tostring(arg))

  return cmd, arg
end

return {
  each_occupant = each_occupant,
  each_room = each_room,
  get_session = get_session,
  has_valid_bot_token = has_valid_bot_token,
  get_jitsi_nick_from_occupant = get_jitsi_nick_from_occupant,
  get_room_from_room_name = get_room_from_room_name,
  parse_message = parse_message
}