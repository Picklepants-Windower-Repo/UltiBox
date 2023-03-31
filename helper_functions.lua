require('sets')
res = require('resources')

function get_target(type)
   local target = windower.ffxi.get_mob_by_target(type)

   if not target then
      log('No target - cancelling operation')
      return false
   end

   return target
end

function get_sub_target()
   windower.send_command("input /ta <stpt>")
      
   coroutine.sleep(.01) -- Credit to Rubenator for teaching me about coroutine
   while windower.ffxi.get_mob_by_target('stpt') do
      coroutine.sleep(1)
   end

   return get_target('lastst')
end

function cooldown(spell_id)
   -- Gets table with spells that are on cooldown
   local timers = T(windower.ffxi.get_spell_recasts()):filter(function(x) return x ~= 0 end)

   -- If spell is on cooldown, returns time remaining, otherwise returns false
   if timers[spell_id] and timers[spell_id] ~=0 then
      local minutes = math.floor(timers[spell_id]*0.01/60)
      local seconds = math.ceil(timers[spell_id]*0.01%60)
      
      if seconds < 10 then seconds = '0'..seconds end
      return minutes..':'..seconds
   else
      return false
   end
end

function spell_name_and_id(spell_name)
   for k,_ in pairs(res.spells) do
      if res.spells[k].en:lower() == spell_name:lower() then
         return res.spells[k].en, k
      end
   end
end

function remove(table, key)
   new_table = T{}
   for k,v in pairs(table) do
      if k ~= key then
         new_table[k] = v
      end
   end

   return new_table
end

function format_display_name(saved_name)
   if saved_name == '' then return false end

   saved_name = saved_name
      :gsub('_', ' ')

   return saved_name
end

function format_save_name(set_name)
   if set_name == '' then return false end

   set_name = set_name
      :gsub(' ', '_')

   return set_name
end