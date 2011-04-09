#! /usr/bin/env ruby
#encoding: UTF-8

#dmesg-extension for Notifications and human-readable formatting.

require 'RNotify'
require 'yaml'
require_relative 'nil_mod.rb'
require_relative 'hash_mod.rb'

include ExtendedNil
include HashRename

# ==Zeitberechnung
#
# Berechnet aus einer übergebenen Zeit (in Sekunden) einen
# sinnvollen Timestamp in dem Format
#
# <tt>Jahre Wochen Tage Stunden Minuten Sekunden</tt>
#
# Beispiel: <i>[ 2y 12w 15d 22h 15m 10s] event</i>
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

#==tatsächliche Uptime
#
#Berechnet die momentane Uptime des Computers,
#in dem eigenen Ausgabeformat.
#
#- Liefert den String zurück
#- wenn true übergeben wird, wird der String vorher schon ausgegeben.
def get_actual_uptime(val=false)
  basetime= (%x[cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1 | tr -d "\n"]).to_i
  
  output = calc_time basetime

  puts "#{output}" if val==true 
  return output 
end

#==gegebene Zeit
#
#Berechnet aus einer gegebenen Zeit(in Sekunden) 
#den Timestamp. 
#Dient eigentlich nur als wrapper für _calc_time_
def get_given_uptime(given)
  basetime = given.to_i
  
  output = calc_time basetime

  return output 
end

#==Leerzeichenstring
#
#Gibt einen String mit der übergebenen Anzahl an 
#Leerzeichen zurück.
def fill_space(val)
  whitespace = ""
  val.times do 
    whitespace+=" "
  end
  return whitespace
end

#==Optionenbehandlung
#
#Es existieren folgende Optionen:
#*  keine Option gesetzt: Standardausgabe, wobei Timestamps
#   durch menschenlesbare Werte ersetzt sind:
#*  -i Gibt die tatsächliche Uptime am Ende mit aus.
#*  -f(t/u) Spezifiert die dmesg Ausgabe erwartet entweder t oder u im Anschluss
#*  -ft Gibt hinter jedem Eintrag die tatsächliche Ereigniszeit aus
#*  -fu Gibt hinter jedem Eintrag aus wie lange es schon her ist.
#*  -d daemon-mode. Es erfolgt keine direkte Ausgabe in die 
#   Konsole, man wird über notfiy's über neue Nachrichten im Kernellog (dmesg)
#   benachrichtigt. Sollten andere Optionen gesetzt sein, werden diese
#   behandelt bevor in den Daemon-Mode gewechselt wird.
def get_options
  opt = Hash.new
  ARGV.each do |a|
    arg = a.dup
    if arg.gsub!("-","")
      arg.each_char {|c| opt[c.to_sym]=true}
    else 
      puts "invalid option."
      exit
    end
    opt[:ft]=true if (opt[:f] && opt[:t])
    opt[:fu]=true if (opt[:f] && opt[:u])
    if opt[:ft] && opt[:fu]
      puts "Only one format-option is allowed."
      exit
    end
  end
  return opt
end

#==daemon-Konfiguration
#
#Die Einstellungsmöglichkeiten des daemon-modes
#könnten so umfangreich werden, dass
#Optionen nicht mehr genügen um sinnvoll zu konfigurieren.
#Deshalb soll die folgende Datei der Konfiguration
#dienen:
#<tt>user_home_directory/.upmsgrc</tt>
#Weitere Hilfe zur Erstellung der Datei wird folgen.
def get_config
  config_file = YAML.load(File.open(ENV['HOME']+'/.upmsgrc'))
  config_names = {"Timeout" => :to,
    "Extratimeout per line" => :exto,
    "Check for new Events" => :evt
  }
  return h_rename(config_file, config_names)
end

#==Kernobjekt
#
#Ein Objekt dieser Klasse repräsentiert ein Laufinstanz für
#den modifizierten dmesg-Dienst. Er enthält Konfigurationen
#für die Ausgabe (Wahl der Methode), sowie weitere Einstellungen
#insbesondere für den daemon-Modus. 
#
class Upmsg
  attr_accessor :opt, :dmesg, :config
  
  def initialize(options=nil, config = nil)
    @opt = options  
    @config = config
    @opt||=get_options
    @config||=get_config
  end

  #===formatierter dmesg-Output
  #
  #Gibt den dmesg Output formatiert auf der Konsole aus.
  #Es wird implizit vorausgesetzt, dass vorher _get_options_
  #durchgeführt wurde.
  #Wenn nicht wird es Standardformatiert und somit der Timestamp der 
  #Uptime zur Zeit des Events ausgegeben.
  def show
    dmesg = %x[dmesg]
    if opt[:fu]
      now = (%x[cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1 | tr -d "\n"])
    elsif opt[:ft]
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
        if opt[:fu]
          diff = now.to_i - time.to_i
          time = get_given_uptime(diff)
        elsif opt[:ft]
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

  #===daemon-Mode
  #
  #Startet das Programm im daemon-mode.
  #Es wird in regelmäßigen Abständen(Default 5 Sekunden)
  #auf Änderungen in der dmesg-Struktur geprüft. Wenn
  #ja werden diese Änderungen, mit brauchbaren Timestamps versehen,
  #als Notification an den notification-daemon und damit
  #an den Window-Manager gesendet. Es folgt normalerweise
  #eine Bubbleausgabe auf dem Bildschirm.
  def daemonize
    dmesg = %x[dmesg]
    puts "daemon up and running..."
    while( true ) 
      sleep @config[:evt]
      current = %x[dmesg]
      Notify.init("dmesg")
      begin
        if (current.length > dmesg.length)
          text = current[dmesg.length..(current.length-1)]
          text = text.gsub(/\[\s*\d+.\d+\]/,'')
          summary = "dmesg: "+%x[date +"%H:%M:%S"]+"up: "+get_actual_uptime
          notification = Notify::Notification.new(summary, text, nil)
          notification.timeout=((@config[:to] + (text.count("\n") * @config[:exto]).to_i)*1000)
          notification.show
        end
        dmesg = current
        current = %x[dmesg]
        sleep 2
      end while (current.length > dmesg.length)
      Notify.uninit
    end
  end

end

run = Upmsg.new 
run.show if (run.opt.length == 0) || run.opt[:ft] || run.opt[:fu]
if run.opt[:i]
  run.show
  puts "Current Uptime: "+get_actual_uptime
end
daemonize if run.opt[:d]
