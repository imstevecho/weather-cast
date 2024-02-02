module WeathersHelper
  def is_today?(unix_time)
    Time.at(unix_time).to_date == Date.today
  end

  def human_readable_time(unix_time)
    Time.at(unix_time).strftime('%a, %b %d %I:%M %p')
  end
end
