#! /usr/bin/env ruby
#encoding: UTF-8
#Der Ersatz für dmesg. Hiermit werden die Timestamps zum ersten mal leserlich
#angezeigt.

require 'libnotify'

def calc_time(basetime)
  sec=basetime % 60
  min=basetime / 60 % 60
  hours=basetime / 60 / 60 % 24
  days=basetime / 60 / 60 / 24 % 7
  weeks=days / 60 / 60 / 24 / 7 % 52
  years=days / 60 / 60 / 24 / 365

  output=""
  output+="#{years}y" if years>0
  output+=" #{weeks}w" if weeks>0
  output+=" #{days}d" if days>0
  output+=" #{hours}h" if hours>0
  output+=" #{min}m " if min>0
  output+="#{sec}s"
  
  return output
end
def get_actual_uptime(val=false)
  basetime= (%x[cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1 | tr -d "\n"]).to_i
  
  output = calc_time basetime

  puts "#{output}" if val==true 
  return output 
end

def get_given_uptime(given)
  basetime = given.to_i
  
  output = calc_time basetime

  return output 
end

def fill_space(val)
  whitespace = ""
  val.times do 
    whitespace+=" "
  end
  return whitespace
end

def put_dmesg
  dmesg = %x[dmesg]
  if $opt[:fu]
    now = (%x[cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1 | tr -d "\n"])
  elsif $opt[:ft]
    now = Time.new
    nowstamp = (%x[cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1 | tr -d "\n"])

  else 
    now = get_actual_uptime
  end
  now_length = now.to_s.length
  dmesg.each_line do |line|
    time = line[/\[\s*\d+.\d+\]/]
    if time 
      time = time[/\d+/]
      if $opt[:fu]
        diff = now.to_i - time.to_i
        time = get_given_uptime(diff)
      elsif $opt[:ft]
        diff = nowstamp.to_i - time.to_i
        time = (now - diff).to_s #weil time sonst Time-Objekt ist
      else
        time = get_given_uptime(time) 
      end
      space = fill_space(now_length - time.length)
      puts line.gsub(/\[\s*\d+.\d+\]/ , "[#{space}#{time}]")
    end
  end
end

#Optionenbehandlung
#Es existieren folgende Optionen:
#keine Option gesetzt: Standardausgabe, wobei Timestamps
#durch menschenlesbare Werte ersetzt sind:
#-up :: Gibt die tatsächliche Uptime am Ende mit aus.
#-f(t/u) :: Spezifiert die dmesg Ausgabe erwartet entweder t oder u im Anschluss
#-ft :: Gibt hinter jedem Eintrag die tatsächliche Ereigniszeit aus
#-fu :: Gibt hinter jedem Eintrag aus wie lange es schon her ist.
##-d :: daemon-mode. Es erfolgt keine direkte Ausgabe in die 
#Konsole, man wird über notfiy's über neue Nachrichten im Kernellog (dmesg)
#benachrichtigt. Sollten andere Optionen gesetzt sein, werden diese
#behandelt bevor in den Daemon-Mode gewechselt wird.
def get_options
  $opt = Hash.new
  ARGV.each do |arg|
    case arg
    when "-up" then $opt[:up]=true
    when "-ft" then $opt[:ft]=true
    when "-fu" then $opt[:fu]=true
    when "-d" then $opt[:d]=true
    end
  end
end

def daemonize
  $dmesg = %x[dmesg]
  while( true ) 
    sleep 5
    current = %x[dmesg]
    begin
      if (current.length > $dmesg.length)
        text = current[$dmesg.length..(current.length-1)]
        text = text.gsub(/\[\s*\d+.\d+\]/,'')
        notification = Libnotify.new do |n|
          n.summary = "dmesg: "+%x[date +"%H:%M:%S"]+"up: "+get_actual_uptime
          n.body = text
          #n.append = true
          # Timeout ist mind. 2 Sekunden, plus die Hälfte die Zeilen in s
          n.timeout = 2 + (text.count("\n")*0.5) 
          n.urgency = :normal
          n.append = false
          #evtl n.icon_path 
        end
        notification.show!
      end
      $dmesg = current
      current = %x[dmesg]
      sleep 2
    end while (current.length > $dmesg.length)
  end
end
get_options 
put_dmesg if $opt.length == 0
put_dmesg if $opt[:ft] || $opt[:fu]
if $opt[:up]
  put_dmesg
  puts "Current Uptime: "+get_actual_uptime
end
daemonize if $opt[:d]
