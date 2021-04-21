load 'model/activity.rb'

require 'kafka'
require 'active_record'
require 'pry'

def valid_json?(json)
  JSON.parse(json)
  return true
rescue JSON::ParserError
  return false
end

# Database connection
db_config = YAML::load(File.open('db/config.yml'))
ActiveRecord::Base.establish_connection(db_config['development'])

# Kafka connection
kafka_config = YAML::load(File.open('config/kafka.yml'))
kafka = Kafka.new(kafka_config['url'])

# Consumers with the same group id will form a Consumer Group together.
consumer = kafka.consumer(group_id: kafka_config['group_id'])

# It's possible to subscribe to multiple topics by calling `subscribe`
# repeatedly.
consumer.subscribe(kafka_config['topic'])

# Stop the consumer when the SIGTERM signal is sent to the process.
# It's better to shut down gracefully than to kill the process.
trap('TERM') { consumer.stop }

# This will loop indefinitely, yielding each message in turn.
puts "--------------------STARTING---------------------"
consumer.each_message do |message|
  puts "TOPIC: #{message.topic}; MESSAGE PARTITION: #{message.partition}"
  puts "MESSAGE OFFSET: #{message.offset}"
  puts "MESSAGE KEY: #{message.key}; MESSAGE VALUE: #{message.value}"

  puts "Creating activity with params #{message.value}}"
  if valid_json?(message.value)
    begin
      Activity.create!(JSON.parse(message.value))
    rescue StandardError => e
      puts "Failed to create activity #{e.message}"
    end
  end

  puts "----------------------------------------------"
end
