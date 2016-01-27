require 'json'
require 'net/http'
require 'date'

module WU
  extend self

  def current_observation (station)

    uri = build_condition_uri(station)
    res = make_request(uri)
    
    current = res["current_observation"]
    return toObservation(current)

  end

  def station_history (station, start_time, end_time=nil)

    if !start_time.is_a?(Date)
      puts "start_time is not a date"
      return
    end 

    uri = build_history_uri(station, start_time, end_time)
    res = make_request(uri)

    if !res.is_a?(Hash)
      puts "response is not a hash"
      return
    end

    history = res["history"]

    if !history.is_a?(Hash)
      puts "history is not a hash"
      return
    end

    days = history["days"]

    if !days.is_a?(Array)
      puts "days is not an array"
      return
    end

    observations = days.map {|day| day["observations"].map {|obs| toObservation(obs) } }
    return observations.reduce {|a, c| a + c}
  end

  def format_date (n)
    return n.strftime("%Y%m%d")
  end

  def format_epoch (n)
    return Time.at(n).strftime("%Y%m%d")
  end

  private

  def make_request (uri)
    puts uri
    body = Net::HTTP.get(uri)
    return JSON.parse(unfuck(body))
  end

  def build_condition_uri (station)
    return URI("http://api.wunderground.com/api/606f3f6977348613/conditions/units:english/v:2.0/q/#{station}.json")
  end

  def build_history_uri (station, t1, t2)
    start_time = format_date(t1)
    end_time = t2 ? format_date(t2) : ""
    puts "#{station} #{start_time} #{end_time}"

    uri = URI("http://api.wunderground.com/api/606f3f6977348613/history_#{start_time}#{end_time}/units:english/v:2.0/q/#{station}.json")
    return uri
  end

  def unfuck (json)
    json.gsub(/\"snowdepth\": T,/, "")
  end

  def toObservation (obs)

    date = obs["date"]

    if !date.is_a?(Hash)
      puts "why isnt date a hash"
      return
    end

    epoch = date["epoch"]
    temperature = obs["temperature"]
    
    return {"time" => epoch, "temperature" => temperature}
  end

end

t1 = Time.at(1453885269).to_date
#t2 = Date.new(2016, 1, 1) 
puts WU.station_history("KNYC", t1)
puts WU.current_observation("KNYC")

