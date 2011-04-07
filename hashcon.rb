#! /usr/bin/env ruby


module ConHash
 def contract(hash, new_name)
  modified = Hash.new
  hash.each_key do |k| 
    modified[new_name[k]] = hash[k]
  end
  return modified
 end 
end
