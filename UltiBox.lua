-------------------------------------------------------------------------------------
-- UltiBox                                                                         --
-- A configurable mod for multiboxing                                              --
--                                                                                 --
-- To Do:                                                                          --
-- Add help command and text                                                       --
-- Add state for alt target that can be viewed and updated in game                 --
-- Add functions to handle job abilities                                           --
-- Mount Function: Add ability to set preferred mount and validate                 --
-- Consumables Function: Add ability to set consumables in game                    --
-- Add two_hour function that detects job and sends appropriate SP ability         --
-------------------------------------------------------------------------------------

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
require('chat')
config = require('config')

-- Local Imports
require('helper_functions')

--
local defaults = T{
   buffs = T{},
   mount = 'raptor',
   weaponskill = T{},
}

settings = config.load(defaults)

local color = T{
   ['green'] = 158,
   ['red'] = 39,
   ['notify'] = 166,
   ['message'] = 63,
}
key_pressed = ''

-------------------------------------------------------------------------------------
-- Windower Event Functions
-------------------------------------------------------------------------------------

windower.register_event('addon command', function(command, ...)
   command = command and command:lower()
   args = T{...}
   argstring = args:concat(' ')

   if command == 'warp' then
      warp()
   elseif command == 'shm' or command == 'showmount' then
      display_mount()
   elseif command == 'setm' or command == 'setmount' then
      set_mount(argstring)
   elseif command == 'mount' then
      mount()
   elseif command == 'sws' or command == 'setws' then
      set_weaponskill(args)
   elseif command == 'assist' then
      assist_toggle(argstring)
   elseif command == 'follow' then
      follow_toggle(argstring)
   elseif command == 'send' then
      send(args)
   elseif command == 'cast' then
      cast(args)
   elseif command == 'decurse' then
      decurse()
   elseif command == 'buffs' or command == 'displaybuffs' then
      display_buffs()
   elseif command == 'abf' or command == 'addbuff' then
      add_buff(argstring)
   elseif command == 'rbf' or command == 'removebuff' then
      remove_buff(argstring)
   elseif command == 'buff' then
      buff()
   elseif command == 'consumables' then
      consumables()
   elseif command == 'test' then
      -- for k,v in pairs(windower.ffxi.get_items('equipment')) do log(k,v) end
      for k,v in pairs(windower.ffxi.get_items(10, 57)) do log(k,v) end
   end
end)

windower.register_event('keyboard', function(key)
   if key == 28 or key == 1 then
      key_pressed = key
   end
end)

-------------------------------------------------------------------------------------
-- Utility Functions
-------------------------------------------------------------------------------------

function warp()
   local equipment = windower.ffxi.get_items('equipment')
   local item = windower.ffxi.get_items(equipment.right_ring_bag, equipment.right_ring)

   if item.id == 28540 then
      windower.send_command("input /item 'warp ring' <me>")
   else
      windower.send_command("input /equip ring2 'warp ring'; wait 11; input /item 'warp ring' <me>")
   end   
end

function display_mount()
   if settings.mount then
      windower.add_to_chat(color.message, 'Current mount is the '..settings.mount:color(color.green, color.message))
   else
      windower.add_to_chat(color.message, "No mount has been set")
   end
end

function set_mount(mount_name)
   if not T(windower.ffxi.get_key_items()):find(3055) then
      windower.add_to_chat(color.message, "You can't summon mounts")
      return
   elseif not is_mount(mount_name) then
      windower.add_to_chat(color.message, "That mount does not exist")
      return
   elseif not have_mount(mount_name) then
      windower.add_to_chat(color.message, "You don't have that mount")
      return
   end

   settings.mount = mount_name:lower()
   settings:save()
   windower.add_to_chat(color.message, "Mount has been set to "..settings.mount:color(color.green, color.message))
end

function mount()
   local buffs = windower.ffxi.get_player().buffs
   local mounted = false

   for _, buff in pairs(buffs) do
      if buff == 252 then
         mounted = true
      end
   end

   if mounted then
      windower.send_command('input /dismount')
   else
      windower.send_command('input /mount '..settings.mount)
   end
end

function set_weaponskill(args)
   local name = args[1]
   local skill = (table.concat(args, ' ')):gsub(name..' ', '')

   settings.weaponskill[name] = skill
   settings:save()
   if settings.multibox then multibox_binds() end
   log(skill..' has been saved for '..name)
end

function assist_toggle(assist_target)
   local player = windower.ffxi.get_player()
   
   if assist_target == '' then
      if not player.in_combat then
         windower.add_to_chat(color.message, "You are not in combat")
      else
         windower.send_command("send @others ub assist "..player.name)
      end

      return
   end

   if not player.in_combat then
      log('fire')
      windower.send_command("input /assist "..assist_target.."; wait 1.5; input /attack")
   else
      windower.send_command("input /attack")
      if player.target_locked then
         windower.send_command("setkey numpad* down; wait 0.1; setkey numpad* up")
      end
   end
end

function follow_toggle(target)
   local player = windower.ffxi.get_player()

   if target == '' then
      windower.send_command("send @others ub follow "..player.index)
      return
   end

   if not player.follow_index then
      windower.ffxi.follow(tonumber(target))
   else
      windower.ffxi.follow()
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
      target = get_sub_target()
      if target then target = target.id end
   elseif command == 'nuke' then
      target = get_target('t')
      if target then target = target.id end
   end
   
   if not target then
      windower.add_to_chat(color.notify, 'No target - cancelling operation')
      return
   end
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

   local spell_name, spell_id = spell_name_and_id(spell)
   local cooldown = cooldown(spell_id)

   if cooldown then
      windower.send_command("input /p "..spell_name.." cooldown remaining "..cooldown)
   else
      windower.send_command("input /p Casting "..spell_name.." on "..target_name)
      windower.send_command('input /ma "'..spell_name..'" '..target_id)
   end
end

function decurse(target)
   local buffs = T(windower.ffxi.get_player().buffs)
   local dispel = flase
   local debuffs = T{
      [3] = 'poisona',
      [4] = 'paralyna',
      [5] = 'blindna',
      [6] = 'silena',
      [7] = 'stona',
      [8] = 'viruna',
      [9] = 'cursna',
      [20] = 'cursna',
      [31] = 'viruna',
   }
   local magic_debuffs = T{
      [10] = true,  -- Stun
      [11] = true,  -- Bind
      [12] = true,  -- Weight
      [13] = true,  -- Slow
      [14] = true,  -- Charm
      [15] = true,  -- Doom
      [16] = true,  -- Amnesia
      [17] = true,  -- Charm -- again?
      [18] = true,  -- Gradual Petrification
      [128] = true, -- Burn
      [129] = true, -- Frost
      [130] = true, -- Choke
      [131] = true, -- Rasp
      [132] = true, -- Shock
      [133] = true, -- Drown
      [134] = true, -- Dia
      [135] = true, -- Bio
      [136] = true, -- STR Down
      [137] = true, -- DEX Down
      [138] = true, -- VIT Down
      [139] = true, -- AGI Down
      [140] = true, -- INT Down
      [141] = true, -- MND Down
      [142] = true, -- CHR Down
      [146] = true, -- Accuracy Down
      [147] = true, -- Attack Down
      [148] = true, -- Evasion Down
      [149] = true, -- Defense Down
   }

   for k,v in pairs(buffs) do
      if debuffs[v] then
         dispel = debuffs[v]
      elseif magic_debuffs[v] then
         dispel = 'erase'
      end
   end
  
   if dispel then
      windower.send_command("send skookum /ma "..dispel.." picklepants")
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
      local name, id = spell_name_and_id(format_display_name(k))
      windower.add_to_chat(158, name)
   end
end

function add_buff(buff)
   local buff_name, buff_id = spell_name_and_id(buff)

   if not buff_name and not buff_id then
      log('Invalid buff name')
      return
   end

   if settings.buffs[format_save_name(buff_name):lower()] then
      log('Buff is already saved')
      return
   end

   local buff_cast_time = res.spells[buff_id].cast_time
   
   settings.buffs[format_save_name(buff_name)] = {id = buff_id, cast_time = buff_cast_time}
   settings:save()
   log(buff_name..' has been added to buffs')
end

function remove_buff(buff)
   if buff:lower() == 'all' then
      settings.buffs = T{}
      settings:save()
      log('All buffs have been removed')
      return
   end
   local buff_name, buff_id = spell_name_and_id(buff)

   if not buff_name and not buff_id then
      log('Invalid buff name')
      return
   end

   if not settings.buffs[format_save_name(buff_name):lower()] then
      log('That buff is not in saved buffs')
      return
   end

   settings.buffs = remove(settings.buffs, format_save_name(buff_name):lower())
   settings:save()
   log(buff_name..' has been removed from buffs')
end

function buff()
   if settings.buffs:length() < 1 then
      windower.send_command("send skookum /p No buffs to cast")
      return
   end

   local buff_string = ''
   for k, v in pairs(settings.buffs) do
      local wait_time = v.cast_time * 2 + 3
      buff_string = buff_string:append("ub cast "..format_display_name(k).." <me>; wait "..wait_time.."; ")
   end
   log(buff_string)
   windower.send_command(buff_string)
end

function consumables()
   local buffs = T(windower.ffxi.get_player().buffs)

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