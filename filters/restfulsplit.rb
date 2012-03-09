require "rubygems"
require "logstash/namespace"
require "logstash/time"

# The split filter is for splitting multiline messages into separate events.
#
# An example use case of this filter is for taking output from the 'exec' input
# which emits one event for the whole output of a command and splitting that
# output by newline - making each line an event.
#
# The end result of each split is a complete copy of the event
# with only the current split section of the given field changed.
class LogStash::Filters::RestfulSplit < LogStash::Filters::Base

  config_name "restfulsplit"
  plugin_status "beta"

  # The string to split on. This is usually a line terminator, but can be any
  # string.
  # Modifying this to have it split on "&"
  # config :terminator, :validate => :string, :default => "&"
  config :terminator, :validate => :string, :default => "&"


  # The field which value is split by the terminator, default @fields.rest
  config :field, :validate => :string, :default => "rest"
  config :outfield, :validate => :string, :default => "@fields"

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    events = []

    original_value = event["@fields"][@field]
    # If for some reason the field is an array of values, take the first only.
    original_value = original_value.first if original_value.is_a?(Array)

    # Make sure ruby drops trailing empty splits
    splits = original_value.split(@terminator)
    #or splits[1].empty?
    splits.each do |value|
      # the next if should handle empty or double ampersands
      next if value.empty?
      key, value = value.split '=', 2
      value = false if value == "false"
      event["@fields"][key] = value
      # Push this new event onto the stack at the LogStash::FilterWorker
    end
    filter_matched(event)
    # Cancel this event, we'll use the newly generated ones above.
  end # def filter
end # class LogStash::Filters::Date
