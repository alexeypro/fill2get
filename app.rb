require 'rubygems'
require 'sinatra'

class String
  def ends_with?(str)
    str = str.to_str
    tail = self[-str.length, str.length]
    tail == str      
  end
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
    erb :thank_you
  end
end

get '/download' do
  right_referer = request.referer.ends_with?('/save-answers')
  if right_referer
    attachment "file_to_download.png"
  else
    redirect '/'
  end
end

post '/download' do
  redirect '/'
end
