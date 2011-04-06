#! /usr/bin/env ruby

#==Erweiterte Nil-Klasse
#Erweiterung darum, dass Standardzugriff <tt>[]</tt> 
#nun statt Error einen nil-Wert zurückliefert.
class NilClass
  def [] empty=nil
    return self
  end
end
