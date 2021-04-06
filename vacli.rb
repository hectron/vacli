require "net/http"
require "json"
require "optparse"

$stdout.sync = true

STATES = ["AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]

MODERNA = "moderna".freeze
PFIZER = "pfizer".freeze
JJ = "jj".freeze
MANUFACTURERS = [MODERNA, PFIZER, JJ].freeze

options = {}
parser = OptionParser.new
parser.banner = "Usage: #{parser.program_name} [options]"
parser.release = "alpha"
parser.version = "0.0.1"
parser.program_name = "vacli.rb"

parser.on("-sSTATE", "--state=STATE", STATES, "USPS-abbreviated United States state to check.") do |state|
  options[:state] = state
end

parser.on("-m", "--manufacturer MANUFACTURER", MANUFACTURERS, "Vaccination manufacturer.", "Options: #{MANUFACTURERS.inspect}") do |manufacturer|
  options[:manufacturer] = manufacturer
end

parser.parse!(into: options)

if options.keys.none?
  puts parser.to_s
  exit
end

class VaccineSpotter
  API_URL = "https://www.vaccinespotter.org/api/v0/states".freeze

  def self.find_in(state, vaccine_type:)
    new(state, vaccine_type).find
  end

  def initialize(state, vaccine_type)
    @state = state
    @vaccine_type = vaccine_type
  end

  def find
    uri = URI("#{API_URL}/#{@state}.json")
    data = JSON.parse(Net::HTTP.get(uri))

    # find appointments
    data["features"].each do |feature|
      properties = feature.dig("properties")
      next if properties["appointments_available"] != true
      next if @manufacturer && !properties["appointment_vaccine_types"][@manufacturer]

      relevant_appointments = properties["appointments"].reject do |appointment|
        @manufacturer && !appointment["vaccine_types"].include?(@manufacturer)
      end

      if relevant_appointments.any?
        puts <<~MSG.split.join(" ")
      Found #{relevant_appointments.size} appointment(s) for the #{relevant_appointments.flat_map{|a| a["vaccine_types"]}.uniq.join(" and ")} vaccine
      at #{properties["provider"]} #{properties["name"]} - #{properties["city"]}, #{properties["state"]} #{properties["postal_code"]}
        MSG
        puts "Appointment URL: #{properties["url"]}\n\n"
      end
    end
  end
end

VaccineSpotter.find_in(options[:state], vaccine_type: options[:manufacturer])
