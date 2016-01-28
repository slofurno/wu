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
      raise "start_time is not a date"
    end 

    uri = build_history_uri(station, start_time, end_time)
    res = make_request(uri)

    if !res.is_a?(Hash)
      raise "response is not a hash"
    end

    history = res["history"]

    if !history.is_a?(Hash)
      raise "history is not a hash"
    end

    days = history["days"]

    if !days.is_a?(Array)
      raise "days is not an array"
    end

    return days.map {|day| toObservations(day) }.reduce {|a, c| a + c}
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
    return JSON.parse(snowdepth(body))
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

  def snowdepth (json)
    json.gsub(/\"snowdepth\": T,/, "")
  end

  def toObservations (day)

   if !day.is_a?(Hash)
    raise "day is not a hash"
   end

   observations = day["observations"]

   if !observations.is_a?(Array)
    raise "missing observations array"
   end

   return observations.map {|obs| toObservation(obs) }
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

