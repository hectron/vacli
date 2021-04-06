require "spec_helper"
require_relative "../vacli"

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
  end
end
