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

function cooldown(spell)
   -- Gets table with spells that are on cooldown
   local timers = T(windower.ffxi.get_spell_recasts()):filter(function(x) return x ~= 0 end)

   -- Finds the spell ID from the spells resource table
   local spell_id = 0
   for k,_ in pairs(res.spells) do
      if res.spells[k].en:lower() == spell:lower() then
         spell_id = k
      end
   end

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