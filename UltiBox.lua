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
require('strings')
require('tables')
config = require('config')

-- Local Imports
require('helper_functions')

local defaults = T{
   weaponskill = T{},
   buffs = T{}
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
   elseif command == 'cast' then
      cast(args)
   elseif command == 'decurse' then
      decurse()
   elseif command == 'dbfs' or command == 'displaybuffs' then
      display_buffs()
   elseif command == 'abf' or command == 'addbuff' then
      add_buff(args:concat(' '))
   elseif command == 'rbf' or command == 'removebuff' then
      remove_buff(args:concat(' '))
   elseif command == 'buff' then
      buff()
   elseif command == 'consumables' then
      consumables()
   elseif command == 'test' then
      -- finds mob in local mob array with the given name
      local mobs = T(windower.ffxi.get_mob_array()):with('id', 17248264)
      for k,v in pairs(mobs) do log(k,v) end

      -- log('----------------------------------------------')
      
      local target = windower.ffxi.get_mob_by_target('t')
      -- for k,v in pairs(target) do log(k,v) end
      -- log(target.id)
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

function send(args)
   local name = args[1]
   local command = args[2]
   local spell = args:slice(3, args:length()):concat(' ')
   local target = ''

   if command == 'self' then
      target = '<me>'
   elseif command == 'other' then
      target = get_target('lastst')
      if target then target = target.id end
   elseif command == 'nuke' then
      target = get_target('t')
      if target then target = target.id end
   end
   
   if not target then return end
   windower.send_command("send "..name.." ub cast "..spell.." "..target)
end

function cast(args)
   local target_id = args:last()
   local spell = args:slice(1, args:length()-1):concat(' ')
   local target_name = ''
   
   if target_id == '<me>' then
      target_name = 'myself'
   else
      target_name = T(windower.ffxi.get_mob_array()):with('id', tonumber(target_id)).name
   end

   log(target_id, spell, target_name)

   local spell_name, spell_id = spell_name_and_id(spell)
   local cooldown = cooldown(spell_id)

   if cooldown then
      windower.send_command("input /p "..spell_name.." cooldown remaining "..cooldown)
   else
      windower.send_command("input /p Casting "..spell_name.." on "..target_name)
      windower.send_command('input /ma "'..spell_name..'" '..target_id)
   end
end

function decurse()
   local target = get_target('lastst')
   if not target then return end

   local buffs = T(windower.ffxi.get_player().buffs)
   local dispel = flase
   local dispel_priority = T{
      [4] = 'paralyna',
      [5] = 'blindna',
      [6] = 'silena',
      [3] = 'poisona'
   }
   
   for _,v in pairs(buffs) do
      if dispel_priority[v] then
         dispel = dispel_priority[v]
      end
   end
  
   if dispel then
      windower.send_command("ub send other skookum"..dispel)
   else
      windower.send_command("send skookum /p Nothing to dispel")
   end
end

function display_buffs()
   if settings.buffs:length() < 1 then
      log('There are no saved buffs')
      return
   end
   
   log('Current buffs:')
   for k,_ in pairs(settings.buffs) do
      local name, id = spell_name_and_id(k)
      windower.add_to_chat(158, name)
   end
end

function add_buff(buff)
   local buff_name, buff_id = spell_name_and_id(buff)

   if not buff_name and not buff_id then
      log('Invalid buff name')
      return
   end

   if settings.buffs[buff_name:lower()] then
      log('Buff is already saved')
      return
   end

   local buff_cast_time = res.spells[buff_id].cast_time
   
   settings.buffs[buff_name] = {id = buff_id, cast_time = buff_cast_time}
   settings:save('all')
   log(buff_name..' has been added to buffs')
end

function remove_buff(buff)

end

function buff()

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