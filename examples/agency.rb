require_relative "../lib/bristow"

pirate_talker = Bristow::Agent.new(
    name: "PirateSpeaker",
    description: "Agent for translating input to pirate-speak",
    system_message: 'Given a text, you will translate it to pirate-speak.',
)

travel_agent = Bristow::Agent.new(
    name: "TravelAgent",
    description: "Agent for planning trips",
    system_message: 'Given a destination, you will plan a trip. You will respond with an itinerary that includes dates, times, and locations only.',
)

agency = Bristow::Agencies::Supervisor.create(agents: [pirate_talker, travel_agent])

messages = agency.chat([
    { role: "user", content: "I want to go to New York. Please plan my trip and tell me about it as if you were a pirate." }
]) do |part|
    print part
end


puts messages