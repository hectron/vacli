require "json"
require "net/http"

class VaccineSpotter
  API_URL = "https://www.vaccinespotter.org/api/v0/states".freeze

  def self.find_in(state, vaccine_type: nil, zipcodes: [])
    new(state, vaccine_type, zipcodes).find
  end

  def initialize(state, vaccine_type, zipcodes)
    @state = state
    @vaccine_type = vaccine_type
    @zipcodes = zipcodes
  end

  def find
    uri = URI("#{API_URL}/#{@state}.json")
    data = JSON.parse(Net::HTTP.get(uri))

    data["features"].each_with_object([]) do |feature, appointments|
      properties = feature.dig("properties")
      next unless properties["appointments_available"]
      next if @vaccine_type && !properties["appointment_vaccine_types"][@vaccine_type]
      next if @zipcodes.any? && !@zipcodes.include?(properties["postal_code"])

      relevant_appointments = properties["appointments"].reject do |appointment|
        next true unless appointment.has_key?("vaccine_types")
        @vaccine_type && !appointment["vaccine_types"].include?(@vaccine_type)
      end

      if relevant_appointments.any?
        appointments.concat(relevant_appointments)
        unique_vaccine_types = relevant_appointments.flat_map{ |a| a["vaccine_types"] }.uniq

        puts <<~MSG.split.join(" ")
          Found #{relevant_appointments.size} appointment(s) for the #{unique_vaccine_types.join(" and ")} vaccine
          at #{properties["provider"]} #{properties["name"]} - #{properties["city"]}, #{properties["state"]} #{properties["postal_code"]}
        MSG
        puts "Appointment URL: #{properties["url"]}\n\n"
      end
    end
  end
end
