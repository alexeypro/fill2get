require "rubygems"
require "sinatra"
 
get '/' do
  erb :index
end

post '/save-answers' do
  erb :index
end
