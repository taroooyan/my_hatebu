class UsersController < ApplicationController
  require "digest/md5"
  # use authentication of hatena
  def login

    api_key    = ENV["API_KEY"]
    secret_key = ENV["SECRET_KEY"]
    api_sig    = Digest::MD5.hexdigest(secret_key + "api_key" + api_key)
    redirect_to("http://auth.hatena.ne.jp/auth?api_key=#{api_key}&api_sig=#{api_sig}")
  end

  def session_register
    require 'net/http'
    require 'json'

    # already session exists?
    if session[:user_id].blank?
      api_key    = ENV["API_KEY"]
      secret_key = ENV["SECRET_KEY"]
      cert       = params[:cert]
      api_sig    = Digest::MD5.hexdigest(secret_key + "api_key" + api_key + "cert" + cert)
      
      url = "http://auth.hatena.ne.jp/api/auth.json?api_key=#{api_key}&cert=#{cert}&api_sig=#{api_sig}"
      res  = Net::HTTP.get(URI.parse(url))
      json = JSON.parser.new(res)
      user_id = json.parse()['user']['name']
      session[:user_id] = user_id
      render :text => 'Create ' + user_id
    else
      render :text => session[:user_id]
    end
  end
end
