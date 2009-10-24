require 'rubygems'
require 'net/https'
require 'sinatra'
require 'logger'

class String
  def ends_with?(str)
    str = str.to_str
    tail = self[-str.length, str.length]
    tail == str      
  end
end

configure do
  AUTH_EMAIL = "olexiy.prokhorenko@???.com"
  AUTH_PASSW = "password-i-have"
  DOC_ID_KEY = "t7ARau3VteZzobib4TFVX5Q"
  LOGS_FILE = "fill2get.log"
  DOWNLOAD_FILE = "file_to_download.png"    
  LOGGER = Logger.new(File.join('log', LOGS_FILE))
end 
 
get '/' do  
  erb :index
end

get '/save-answers' do
  erb :index
end

post '/save-answers' do
  no_firstname = (params == nil || params[:firstname].nil? || params[:firstname].empty?)
  no_lastname = (params == nil || params[:lastname].nil? || params[:lastname].empty?)
  if no_firstname || no_lastname
    @error_message = 'Please fill all fields!'
    erb :index
  else
    form_data = {}
    form_data[:firstname] = params[:firstname]
    form_data[:lastname] = params[:lastname]
    save_data form_data
    erb :thank_you
  end
end

get '/download' do
  right_referer = request.referer.ends_with?('/save-answers')
  if right_referer
    attachment DOWNLOAD_FILE
  else
    redirect '/'
  end
end

post '/download' do
  redirect '/'
end

def save_data(form_data)
  runner_id = Time.now.strftime("%y%m%d%H%M%S")
    
  http = Net::HTTP.new('www.google.com', 443)
  http.use_ssl = true
  path = '/accounts/ClientLogin'
  data = "accountType=HOSTED_OR_GOOGLE&Email=#{AUTH_EMAIL}&Passwd=#{AUTH_PASSW}&service=wise"
  headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
  resp, data = http.post(path, data, headers)
  cl_string = data[/Auth=(.*)/, 1]  
  headers["Authorization"] = "GoogleLogin auth=#{cl_string}"
  
  #spreadsheets_uri = 'http://spreadsheets.google.com/feeds/spreadsheets/private/full'
  #spreadsheet_uri = "http://spreadsheets.google.com/feeds/worksheets/#{DOC_ID_KEY}/private/full"  
  #my_spreadsheets = get_feed(spreadsheet_uri, headers)
  #print my_spreadsheets.body  

  update_spreadsheet_uri = "http://spreadsheets.google.com/feeds/list/#{DOC_ID_KEY}/od6/private/full"
  headers["Content-Type"] = "application/atom+xml"
  new_row = '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">'
  form_data.each_pair do |key, value|
    new_row += "<gsx:#{key} xmlns:gsx=\"http://schemas.google.com/spreadsheets/2006/extended\">#{value}</gsx:#{key}>"
  end
  new_row += '</atom:entry>'
  post_response = post_to_feed(update_spreadsheet_uri, new_row, headers) 
  
  LOGGER.warn " INFO: [#{runner_id}] post response is: #{post_response}"   
  LOGGER.warn " INFO: [#{runner_id}] post response code is: #{post_response.code}"   
  
  unless post_response.code.to_i == 201
    form_data.each_pair do |key, value|
      LOGGER.warn "ERROR: [#{runner_id}] was not saved to Google Spreadsheet '#{DOC_ID_KEY}': #{key} = #{value}"
    end
  end  
  
end

# get '/test' do
#   form_data = {}
#   form_data[:firstname] = "Abc"
#   form_data[:lastname] = "Ggg"
#   save_data form_data
# end

def get_feed(uri, headers=nil)
  uri = URI.parse(uri)
  Net::HTTP.start(uri.host, uri.port) do |http|
    return http.get(uri.path, headers)
  end
end

def post_to_feed(uri, data, headers)
  uri = URI.parse(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  return http.post(uri.path, data, headers)
end