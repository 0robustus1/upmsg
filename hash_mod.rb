#! /usr/bin/env ruby
#encoding: UTF-8

#=Hashmodifikationen

#Das Modul enthält eine Methode 
#zum Umbenennen der Keys eines Hash.
module HashRename

  #==Hashkeys umbenennen.
  #
  #Die Methode benennt die Keys, die auch im zweiten
  #Hash zu finden sind, in den Wert um, der dem Key im 
  #zweiten Hash zugewiesen wurde.
  def h_rename(hash, new_keynames)
    modified = Hash.new
    hash.each_key do |k| 
      modified[new_keynames[k]] = hash[k]
    end
    return modified
  end 
end
