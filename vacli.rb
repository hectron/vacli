require "net/http"
require "json"
require "optparse"

$stdout.sync = true

STATES = ["AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]

MODERNA = "moderna".freeze
PFIZER = "pfizer".freeze
JJ = "jj".freeze
MANUFACTURERS = [MODERNA, PFIZER, JJ].freeze

if $PROGRAM_NAME == __FILE__
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

    data["features"].each_with_object([]) do |feature, appointments|
      properties = feature.dig("properties")
      next unless properties["appointments_available"]
      next if @vaccine_type && !properties["appointment_vaccine_types"][@vaccine_type]

      relevant_appointments = properties["appointments"].reject do |appointment|
        next true unless appointment.has_key?("vaccine_types")
        @vaccine_type && !appointment["vaccine_types"].include?(@vaccine_type)
      end

      if relevant_appointments.any?
        appointments.concat(relevant_appointments)

        puts <<~MSG.split.join(" ")
      Found #{relevant_appointments.size} appointment(s) for the #{relevant_appointments.flat_map{|a| a["vaccine_types"]}.uniq.join(" and ")} vaccine
      at #{properties["provider"]} #{properties["name"]} - #{properties["city"]}, #{properties["state"]} #{properties["postal_code"]}
        MSG
        puts "Appointment URL: #{properties["url"]}\n\n"
      end
    end
  end
end
