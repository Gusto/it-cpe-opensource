#
# Cookbook:: cpe_yo
# Recipes:: default
#
# Gusto CPE Chef Cookbooks
# Copyright 2019 ZenPayroll, Inc., dba Gusto
#
# This product includes software developed by
# ZenPayroll, Inc., dba Gusto (http://www.gusto.com/).
#

# Uncomment me to see an immediate, scheduled test alert!
# cpe_yo 'It looks like you are using a computer.' do
#   subtitle 'Can I help you with that?'
#   poofs_on_cancel true
#   delivery_sound 'example.aiff'
#   content_image 'example.jpg'
#   action_path 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
#   action_btn 'Yes!'
#   icon 'example.jpg'
#   action :schedule
# end

# Uncomment me to see an immediate, unscheduled test alert!
# cpe_yo 'It looks like you are using a computer.' do
#   subtitle 'Can I help you with that?'
#   poofs_on_cancel true
#   delivery_sound 'example.aiff'
#   content_image 'example.jpg'
#   action_path 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
#   action_btn 'Yes!'
#   icon 'example.jpg'
#   action :send
# end

# Uncomment me to schedule an alert in time for Unix Time Overflow, when
# everything breaks.
# cpe_yo 'Computers are now done.' do
#   subtitle 'Get a book.'
#   poofs_on_cancel true
#   action_path 'https://www.google.com/search?q=unix+time+overflow'
#   action_btn 'ok then...'
#   action :schedule
#   at DateTime.parse('Jan 19 2038 03:14:07')
# end

cpe_yo 'Configure Yo scheduler' do
  action :configure
  only_if { node['cpe_yo']['configure'] }
  not_if { node['cpe_yo']['user_alert_blacklist'].include? node.console_user }
end
