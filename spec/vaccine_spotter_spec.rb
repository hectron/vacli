require "spec_helper"
require_relative "../vaccine_spotter"
require_relative "../vacli" # constants

describe VaccineSpotter do
  CURRENT_PATH = File.expand_path(File.dirname(__FILE__)).freeze

  describe "#find_in" do
    before do
      fixture = File.read(File.join(CURRENT_PATH, "fixtures", "states_il_response.json"))
      allow(Net::HTTP).to receive(:get).and_return(fixture)

      allow($stdout).to receive(:puts)
    end

    it "calls the API to the correct state" do
      expect(Net::HTTP).to receive(:get).with(URI("#{VaccineSpotter::API_URL}/IL.json"))

      VaccineSpotter.find_in("IL", vaccine_type: nil)
    end

    MANUFACTURERS.each do |manufacturer|
      it "returns appointments for #{manufacturer}" do
        appointments = VaccineSpotter.find_in("IL", vaccine_type: manufacturer)

        expect(appointments.flat_map { |a| a["vaccine_types"] }.uniq).to include(manufacturer)
      end
    end

    it "filters the results by zipcode" do
      appointments = VaccineSpotter.find_in("IL", zipcodes: ["60601"])

      expect(appointments).to be_empty

      appointments = VaccineSpotter.find_in("IL", zipcodes: ["60453"])

      expect(appointments).not_to be_empty
    end
  end
end
