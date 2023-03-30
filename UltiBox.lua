_addon.name = 'UltiBox'
_addon.author = 'Picklepants'
_addon.version = '1.0.0'
_addon.commands = {'ub', 'ultibox'}
_addon.language = 'english'

-------------------------------------------------------------------------------------
-- Imports and State
-------------------------------------------------------------------------------------

-- Windower Libraries
require('logger')
require('sets')
require('strings')
require('tables')
res = require('resources')
config = require('config')

local defaults = {
   weaponskill = {},
}

settings = config.load(defaults)
settings:save('all')


-------------------------------------------------------------------------------------
-- Windower Event Functions
-------------------------------------------------------------------------------------

windower.register_event('addon command', function(command, ...)
   command = command and command:lower()
   args = T{...}

   if command == 'mount' then
      mount()
   elseif command == 'warp' then
      warp()
   elseif command == 'sws' or command == 'setws' then
      set_weaponskill(args)
   elseif command == 'attack' then
      attack_toggle()
   elseif command == 'follow' then
      follow_toggle()
   elseif command == 'send' then
      send(args)
   elseif command == 'self' then
      cast_self(args)
   elseif command == 'other' then
      cast_other(args)
   elseif command == 'nuke' then
      nuke(args)
   elseif command == 'decurse' then
      decurse()
   elseif command == 'consumables' then
      consumables()
   elseif command == 'test' then
      local timers = T(windower.ffxi.get_spell_recasts()):filter(function(x) return x ~= 0 end)
      local spell_id = res.spells:en('Aquaveil'):keyset()
      -- log(spell_id, timers[spell_id])
      for k,v in pairs(timers) do log(k,v) end
      if timers[spell_id] ~= 0 then
         -- time remaining = 
         -- log('Spell cooldown remaining '..time_remaining)
      end
   end
end)

-------------------------------------------------------------------------------------
-- Utility Functions
-------------------------------------------------------------------------------------

function warp()
   local equipment = windower.ffxi.get_items('equipment')
   local bag = equipment['right_ring_bag']
   local index = equipment['right_ring']
   local item_data = windower.ffxi.get_items(bag, index)

   if item_data.id == 28540 then
      windower.send_command("input /item 'warp ring' <me>")
   else
      windower.send_command("input /equip ring2 'warp ring'; wait 11; input /item 'warp ring' <me>")
   end   
end

function mount()
   local player = windower.ffxi.get_player()
   local mounted = false

   for _, buff in pairs(player.buffs) do
      if buff == 252 then
         mounted = true
      end
   end

   if mounted then
      windower.send_command('input /dismount')
   else   
      windower.send_command('input /mount raptor')
   end
end

function set_weaponskill(args)
   local name = args[1]
   local skill = (table.concat(args, ' ')):gsub(name..' ', '')

   settings.weaponskill[name] = skill
   settings:save('all')
   if settings.multibox then multibox_binds() end
   log(skill..' has been saved for '..name)
end

function attack_toggle()
      attacking = true
      windower.send_command("send picklepants /attack; wait 1; send @others /assist picklepants; wait 2; send @others /attack; wait 1; send @others /follow picklepants")
end

function follow_toggle()
   local following = windower.ffxi.get_player().follow_index

   if not following then
      windower.send_command("input /follow picklepants")
   else
      windower.send_command("setkey numpad7 down; wait 0.1; setkey numpad7 up")
   end
end

function get_target(type)
   local target = windower.ffxi.get_mob_by_target(type)

   if not target then
      log('No target - cancelling operation')
      return false
   end

   return target
end

function send(args)
   local name = args[1]
   local command = args[2]
   local spell = args[3]
   local target = ''

   if args[4] then
      for i=4, args:length() do
         spell = spell:append(' '..args[i])
      end
   end

   if command == 'self' then
      target = '<me>'
   elseif command == 'other' then
      target = get_target('lastst')
   elseif command == 'nuke' then
      target = get_target('t')
   end

   windower.send_command("send "..name.." ub "..command.." "..spell.." "..target)
end

function cast_self(args)
   local target = args:last()
   local spell = args[1]

   if args:length() > 2 then
      for i=2, args:length() do
         spell = spell:append(' '..args[i])
      end
   end

   windower.send_command("input /ma "..spell.." "..target)
end

function cast_other(args)
   local target = get_target('lastst')
   if not target then return end

   windower.send_command("send "..table.concat(args, " ").." "..target.name)
end

function nuke(args)
   local target = get_target('t')
   if not target then return end
   for k,v in pairs(args) do log(k,v) end
   windower.send_command("send skookum /p Casting "..args[2].." on "..target.name)
   windower.send_command("send "..table.concat(args, " ").." "..target.id)
end

function decurse()
   local buffs = T(windower.ffxi.get_player().buffs)
   local target = get_target('lastst')
   if not target then return end

   local dispel_priority = T{
      [4] = 'paralyna',
      [5] = 'blindna',
      [6] = 'silena',
      [3] = 'poisona'
   }

   local dispel = flase
   for _,v in pairs(buffs) do
      if dispel_priority[v] then
         dispel = dispel_priority[v]
      end
   end
  
   if dispel then
      windower.send_command("send skookum /p Casting "..dispel.." on "..target.name)
      windower.send_command("send skookum /ma "..dispel.." "..target.name)
      return
   end

   windower.send_command("send skookum /p Nothing to dispel")
end

function consumables()
   local buffs = T(windower.ffxi.get_player().buffs)

   for k,v in pairs(buffs) do
      log(k,v)
   end

   log(table.contains(buffs, 251))

   if not table.contains(buffs, 251) then
      windower.send_command("send skookum /item 'melon pie' <me>")
      windower.send_command("send skookum /p Activating food buff")
   elseif not table.contains(buffs, 43) then
      windower.send_command("send skookum /item 'yagudo drink' <me>")
      windower.send_command("send skookum /p Using refresh drink")
   else
      windower.send_command("send skookum /p I'm all buffed up!")
   end
end