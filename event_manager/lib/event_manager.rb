require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def peak_hours(dates_registered)
    hours = dates_registered.collect {|date| date.strftime("%H")}
    total = 0
    hours.uniq.each {|hour| total = hours.count(hour) if hours.count(hour) > total } 
    max_hours = hours.collect {|hour| hour if hours.count(hour) == total }.compact.uniq
    "Most people registered during the following hour(s) of the day: #{max_hours.sort.join(", ")}"
end

def peak_days(dates_registered)
    day_hash = {'0' => "Sunday",
                '1' => "Monday",
                '2' => "Tuesday",
                '3' => "Wednesday",
                '4' => "Thursday",
                '5' => "Friday",
                '6' => "Saturday"
                }
    days = dates_registered.collect {|date| date.strftime("%w")}
    total = 0
    days.uniq.each {|day| total = days.count(day) if days.count(day) > total } 
    max_days = days.collect {|day| day_hash[day] if days.count(day) == total }.compact.uniq
    "Most people registered on the following day(s) of the week: #{max_days.sort.join(", ")}"
end

def clean_phone_number(number)
    digits = number.scan(/[0123456789]/).join("")
    
    if digits.length == 10
        digits
    elsif digits.length == 11 && digits[0] == '1'
        digits = digits[1..-1]
    else
        return false
    end

    digits = digits.split(//)
    area_code = digits.shift(3)
    first_three = digits.shift(3)
    last_four = digits
    "(" + area_code.join + ") " + first_three.join + " - " + last_four.join

end


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager initialized."

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
dates_registered = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  #commented out code only neccesary for iterations that were not required
  #phone = clean_phone_number(row[:homephone]) if clean_phone_number(row[:homephone])
  #dates_registered << DateTime.strptime(row[:regdate],"%m/%d/%y %H:%M")

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id,form_letter)
end


#puts peak_days(dates_registered)
    
#puts peak_hours(dates_registered)