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
    raise "start_time is not a date" if !start_time.respond_to?(:to_date)

    uri = build_history_uri(station, start_time, end_time)
    res = make_request(uri)

    raise "response is not a hash" if !res.respond_to?(:{})

    history = res["history"]

    raise "history is not a hash" if !history.respond_to?(:{})

    days = history["days"]

    raise "days is not iterable" if !days.respond_to?(:each)

    days.map {|day| toObservations(day) }.reduce {|a, c| a + c}
  end

  def format_date (n)
    n.strftime("%Y%m%d")
  end

  def format_epoch (n)
    Time.at(n).strftime("%Y%m%d")
  end

  private


  def make_request (uri)
    puts uri
    body = Net::HTTP.get(uri)
    JSON.parse(snowdepth(body))
  end

  def build_condition_uri (station)
    URI("http://api.wunderground.com/api/606f3f6977348613/conditions/units:english/v:2.0/q/#{station}.json")
  end

  def build_history_uri (station, t1, t2)
    start_time = format_date(t1)
    end_time = t2 ? format_date(t2) : ""
    puts "#{station} #{start_time} #{end_time}"

    URI("http://api.wunderground.com/api/606f3f6977348613/history_#{start_time}#{end_time}/units:english/v:2.0/q/#{station}.json")
  end

  def snowdepth (json)
    json.gsub(/\"snowdepth\": T,/, "")
  end

  def toObservations (day)
    raise "day is not a hash" if !day.respond_to?(:{})

    observations = day["observations"]
    raise "missing observations array" if !observations.respond_to?(:each)

    observations.map {|obs| toObservation(obs) }
  end

  def toObservation (obs)

    date = obs["date"]

    if !date.respond_to?(:{})
      puts "why isnt date a hash"
      return
    end

    epoch = date["epoch"]
    temperature = obs["temperature"]

    return {"time" => epoch, "temperature" => temperature}
  end

end

