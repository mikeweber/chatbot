require 'open-uri'
require 'net/http'
require 'json'
require 'uri'

class Karma
  include Cinch::Plugin
  
  def initialize(*args)
     super
     @karma_points = JSON.parse open("http://#{$settings['settings']['persistence_url']}/scoreboard").read
   end
  
  $help_messages << "!props <nick>    Give props"
  match /props (.+)/, method: :props
  
  match /people/, method: :people
  
  $help_messages << "!element <nick>  Out of element"
  match /element (.+)/, method: :element
  
  $help_messages << "!grammar <nick>  Grammar violation"
  match /grammar (.+)/, method: :grammar
  
  $help_messages << "!points          shows your score"
  match /points/, method: :points
  
  $help_messages << "!scoreboard      shows all scores"
  match /scoreboard/, method: :scoreboard
  
  def userlist(m)
    m.channel.users.collect{|u| u.first.nick}
  end
  
  def people(m)
    m.reply userlist(m).inspect
  end
  
  def valid_message(m, nick)
    result = false
    if m.channel
      if userlist(m).include? nick
        result = true
      else
        m.reply "User not here" 
      end
    else
      m.reply "Do that in the channel please"
    end
    result
  end
  
  def props(m, nick)
    if valid_message(m, nick)
     
      if nick == m.user.nick
        reduce_points(m.user.nick, 50)
        m.reply "#{m.user.nick} loses 50 for patting himself on the back." 
      else
          add_points(nick, 10)
        m.reply "#{nick} is apparently awesome. +10 points."
      end
    end
  end
  
  def element(m, nick)
    if valid_message(m, nick)
      reduce_points(nick, 20)
      m.reply "#{nick} is out of his or her element. -20 points."
    end
  end
  
  def grammar(m, nick)
    if valid_message(m, nick)
      reduce_points(nick, 10)
      m.reply "#{nick} fails at grammar. -10 points."
    end
  end

  def points(m)
    m.reply points_for(m.user.nick)
  end

  def scoreboard(m)
    @karma_points.each do |j|
      m.reply points_for(j['nick'])
    end
  end
  
  # ****************************
  def record_for(nick)
    @karma_points.select{|j|j['nick']==nick}[0] || (@karma_points << {'nick' => nick, 'points' => 0}).last
  end

  def reduce_points(nick, number)
    record_for(nick)['points'] -= number
    post_points(nick)
  end

  def add_points(nick, number)
    record_for(nick)['points'] += number
    post_points(nick)
  end

  def post_points(nick)
    uri = URI.parse("http://#{$settings['settings']['username']}:#{$settings['settings']['password']}@#{$settings['settings']['persistence_url']}/#{nick}")
    Net::HTTP.post_form(uri,{'points' => record_for(nick)['points']})
  end

  def points_for(nick)
    "#{nick} has #{record_for(nick)['points']} points"
  end
  
end








