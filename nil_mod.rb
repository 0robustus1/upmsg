#! /usr/bin/env ruby
#encoding: UTF-8

#Modifikationen für NilClass


#Methode(n) zur Erweiterung
#der NilClass.
module ExtendedNil
  
  #==Erweiterte Nil-Klasse
  #Erweiterung darum, dass Standardzugriff <tt>[]</tt> 
  #nun statt Error einen nil-Wert zurückliefert.
  class NilClass
    def [] empty=nil
      return self
    end
  end

end
