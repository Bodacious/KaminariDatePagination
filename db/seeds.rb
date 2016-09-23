require "faker"
100.times do |index|
  date = index.days.from_now.beginning_of_day

  count = rand(5)

  count.times do
    Event.create! name: Faker::Company.bs, starts_at: date + rand(23).hours
  end
end