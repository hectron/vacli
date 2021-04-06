require "optparse"

$stdout.sync = true

STATES = ["AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]

MODERNA = "moderna".freeze
PFIZER = "pfizer".freeze
JJ = "jj".freeze
MANUFACTURERS = [MODERNA, PFIZER, JJ].freeze

if $PROGRAM_NAME == __FILE__
  # default options
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

  parser.on("-z", "--zipcodes ZIPCODE,ZIPCODE,ZIPCODE", Array, "Comma-separated (without space inbetween) zip codes to filter by.") do |zipcodes|
    options[:zipcodes] = zipcodes
  end

  parser.parse!(into: options)

  if options.keys.none?
    puts parser.to_s
    exit(1)
  end

  require_relative "./vaccine_spotter"
  VaccineSpotter.find_in(options[:state], vaccine_type: options[:manufacturer], zipcodes: options[:zipcodes])
end

