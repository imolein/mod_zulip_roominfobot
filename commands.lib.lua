local it = require('util.iterators')
local ut = module:require('utils')

local HOST = string.match(module:get_host(), '^conference%.(.*)$')

--- Available commands

local commands = {}

--- Returns help message
function commands.help()
  return [[The following commands are available:
* **list_meetings**         - lists all open meetings and the number of participants
* **meetings**              - lists all open meetings and their participants
* **participants $meeting** - lists all participants of a meeting - replace $meeting with the meeting name]]
end

--- Returns open meetings rooms with user number
local meetings_line_format = '* [%s](https://' .. HOST .. '/%s) (%d participants)'
function commands.list_meetings()
  local room_list = { 'The following meetings are currently open:\n' }

  for room in ut.each_room() do
    local count = it.count(ut.each_occupant(room))
    local room_name = tostring(room:get_name())
    table.insert(room_list, meetings_line_format:format(room_name, room_name, count))
  end

  if #room_list == 1 then
    return 'Currently there are no open meetings.'
  end

  return table.concat(room_list, '\n')
end

--- Returns participants of a given room name
local parti_line_format = '* %s'
local parti_header_format = 'The following participants are in meeting [%s](https://' .. HOST .. '/%s):'
function commands.participants(room_name)
  if not room_name or #room_name == 0 or not room_name:find('%S') then
    return 'The name of the meeting is required.\ne.g. `@JitsiBot participants mordor`'
  end

  local parti_list = { parti_header_format:format(room_name, room_name) }
  local room = ut.get_room_from_room_name(room_name)

  if not room then
    return ('There is no open meetings with the name %q.'):format(room_name)
  end

  for occupant in ut.each_occupant(room) do
    local nick = ut.get_jitsi_nick_from_occupant(occupant)

    table.insert(parti_list, parti_line_format:format(nick and nick:find('%S') and nick or 'Fellow Jitster'))
  end

  return table.concat(parti_list, '\n')
end

-- Returns open meeting rooms and their participants
local meetings_parti_line_format = '   * %s'
function commands.meetings()
  local room_list = { 'The following meetings are currently open:\n' }

  for room in ut.each_room() do
    local parti_list = {}
    local parti_count = 0

    for occupant in ut.each_occupant(room) do
      local nick = ut.get_jitsi_nick_from_occupant(occupant)
      parti_count = parti_count + 1

      table.insert(parti_list, meetings_parti_line_format:format(nick and nick:find('%S') and nick or 'Fellow Jitster'))
    end

    local room_name = tostring(room:get_name())
    table.insert(room_list, meetings_line_format:format(room_name, room_name, parti_count))
    table.insert(room_list, table.concat(parti_list, '\n'))
  end

  if #room_list == 1 then
    return 'Currently there are no open meetings.'
  end

  return table.concat(room_list, '\n')
end


return commands