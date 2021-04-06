require "net/http"
require "json"
require "optparse"

$stdout.sync = true

API_URL = "https://www.vaccinespotter.org/api/v0/states".freeze
STATES = ["AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NB *↵*to NE in 1969", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]

options = {}
parser = OptionParser.new
parser.banner = "Usage: #{parser.program_name} [options]"
parser.release = "alpha"
parser.version = "0.0.1"
parser.program_name = "vacli.rb"

parser.on("-sSTATE", "--state=STATE", "USPS-abbreviated United States state to check") do |state|
  upcased_state = state&.upcase
  not_found = -> { raise "State #{state.inspect} not found" }
  STATES.find(not_found) { |us_state| state == us_state }
  options[:state] = state
end

parser.on("-m", "--manufacturer MANUFACTURER", String, "Vaccination manufacturer. Options: moderna, pfizer, jj") do |manufacturer|
  options[:manufacturer] = case manufacturer&.downcase
                           when "moderna"
                             "moderna"
                           when "pfizer"
                             "pfizer"
                           when "jj"
                             "johnson&johnson"
                           else
                             nil
                           end
end

parser.parse!(into: options)

if options.keys.none?
  puts parser.to_s
  exit
end

uri = URI("#{API_URL}/#{options[:state]}.json")
data = JSON.parse(Net::HTTP.get(uri))

# find appointments
data["features"].each do |feature|
  properties = feature.dig("properties")
  next unless properties["appointments_available"]

  # TODO come up with a geofiltering system
  # TODO filter by vaccine type
  # TODO daemon

  next if options[:manufacturer] && !properties["appointment_vaccine_types"][options[:manufacturer]]


  relevant_appointments = properties["appointments"].reject do |appointment|
    options[:manufacturer] && !appointment["vaccine_types"].include?(options[:manufacturer])
  end

  if relevant_appointments.any?
    puts <<~MSG.split.join(" ")
      Found #{relevant_appointments.size} appointment(s) for the #{relevant_appointments.flat_map{|a| a["vaccine_types"]}.uniq.join(" and ")} vaccine
      at #{properties["provider"]} #{properties["name"]} - #{properties["city"]}, #{properties["state"]} #{properties["postal_code"]}
    MSG
    puts "Appointment URL: #{properties["url"]}\n\n"
  end
end

