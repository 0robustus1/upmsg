#! /usr/bin/env ruby
#encoding: UTF-8
#Der Ersatz für dmesg. Hiermit werden die Timestamps zum ersten mal leserlich
#angezeigt. 
def get_actual_uptime(val=false)
  $basetime= (%x[cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1 | tr -d "\n"]).to_i
  $sec=$basetime % 60
  $min=$basetime / 60 % 60
  $hours=$basetime / 60 / 60 % 24
  $days=$basetime / 60 / 60 / 24 % 7
  $weeks=$days / 60 / 60 / 24 / 7 % 52
  $years=$days / 60 / 60 / 24 / 365

  output=""
  output+="#{$years}y" if $years>0
  output+=" #{$weeks}w" if $weeks>0
  output+=" #{$days}d" if $days>0
  output+=" #{$hours}h" if $hours>0
  output+=" #{$min}m " if $min>0
  output+="#{$sec}s"
  
  puts "#{output}" if val==true #Für die Ausgabe
  return output #Für Rücklieferung
end

def get_given_uptime(given)
  $basetime= given.to_i
  $sec=$basetime % 60
  $min=$basetime / 60 % 60
  $hours=$basetime / 60 / 60 % 24
  $days=$basetime / 60 / 60 / 24 % 7
  $weeks=$days / 60 / 60 / 24 / 7 % 52
  $years=$days / 60 / 60 / 24 / 365

  
  output=""
  output+="#{$years}y" if $years>0
  output+=" #{$weeks}w" if $weeks>0
  output+=" #{$days}d" if $days>0
  output+=" #{$hours}h" if $hours>0
  output+=" #{$min}m " if $min>0
  output+="#{$sec}s"
  
  return output #Für Rücklieferung
end

def fill_space(val)
  whitespace = ""
  val.times do 
    whitespace+=" "
  end
  return whitespace
end

$dmesg = %x[dmesg]
$now_length = (get_actual_uptime).length
$dmesg.each_line do |line|
  time = line[/\[\s*\d+.\d+\]/]
  if time 
    time = time[/\d+/]
    time = get_given_uptime(time)
    space = fill_space($now_length - time.length)
    puts line.gsub(/\[\s*\d+.\d+\]/ , "[#{space}#{time}]")
  end
end
