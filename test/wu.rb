require "../wu"
require "date"

t1 = Time.at(1453885269).to_date
puts WU.station_history("KNYC", t1)
puts WU.current_observation("KNYC")
