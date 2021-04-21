load 'model/activity.rb'

require 'kafka'
require 'pry'
require 'json'
require 'yaml'
require 'faker'

def generate_activity
  {
    username: Faker::Internet.username(specifier: 5..8),
    user_ip: Faker::Internet.ip_v4_address,
    user_agent: Faker::Internet.user_agent,
    topic: Faker::Lorem.word,
    action: ['POST', 'PUT', 'DELETE', 'PATCH', 'GET'].sample,
    result: Activity::RESULTS.sample,
    data: Faker::ProgrammingLanguage.creator,
  }
end

# Kafka connection
kafka_config = YAML::load(File.open('config/kafka.yml'))
kafka = Kafka.new(kafka_config['url'])

# Instantiate a new producer.
# `async_producer` will create a new asynchronous producer.
producer = kafka.async_producer(
  # Trigger a delivery once 100 messages have been buffered.
  delivery_threshold: 100,

  # Trigger a delivery every 10 seconds.
  delivery_interval: 10,
)

# Stop the producer when the SIGTERM signal is sent to the process.
# It's better to shut down gracefully than to kill the process.
trap('TERM') { producer.shutdown }

while true
  puts '---------------------------------------'
  activity = generate_activity
  data = JSON.dump(activity)
  puts "Producing an event with data #{activity}"
  # Add a message to the producer buffer.
  producer.produce(data, topic: kafka_config['topic'])

  sleep(1)
end
