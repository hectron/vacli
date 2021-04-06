require "optparse"
require_relative "./constants"

$stdout.sync = true

if $PROGRAM_NAME == __FILE__
  # default options
  options = {}
  parser = OptionParser.new
  parser.banner = "Usage: #{parser.program_name} [options]"
  parser.release = "alpha"
  parser.version = "0.1.0"
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

