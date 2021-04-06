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

  puts "Found vaccine appointments at #{properties["provider"]} #{properties["name"]} - #{properties["city"]}, #{properties["state"]} #{properties["postal_code"]}"
  puts "Appointment URL: #{properties["url"]}"
  vaccines_by_type = properties["appointments"].group_by { |apt| apt["type"] }

  vaccines_by_type.each do |type, appointments|
    puts "#{appointments.size} appointment(s) for the #{type} vaccine"
  end

  puts "\n"
end
