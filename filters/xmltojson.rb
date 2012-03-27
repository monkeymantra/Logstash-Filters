require "rubygems"
require 'i18n'
require "active_support/core_ext"
require "json"
require "logstash/namespace"
require "logstash/time"

# The xmltojson filter takes an xml message, gets rid of pesky escape characters,
# fixes quotes, and converts to json.
# 
# The use case it was designed for was a conversion from xml paired with the JSON
# filter to allow us to parse big XML documents.
#
class LogStash::Filters::XMLtoJSON < LogStash::Filters::Base

  config_name "xmltojson"
  plugin_status "beta"

  config :outfield, :validate => :string, :default => "jsonraw"
  config :infield, :validate => :string, :default => "@message"

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    events = []
    
    # Replace the escapes in the message with single quotes, then escape ampersands
    original_value = event[@infield].gsub('\\"', '"')
    begin
      json = Hash.from_xml(original_value).to_json
      filter_matched(event)
    rescue => e
      event.tags << "_xmlparsefailure"
      @logger.warn("Trouble parsing xml", :exception => e, :backtrace => e.backtrace)
    end
    # If for some reason the field is an array of values, take the first only.
    original_value = original_value.first if original_value.is_a?(Array)

    event["@fields"][@outfield] = json
    # Push this new event onto the stack at the LogStash::FilterWorker
    #event[@infield] = ''
    # Cancel this event, we'll use the newly generated ones above.
  end # def filter
end # class LogStash::Filters::Date
