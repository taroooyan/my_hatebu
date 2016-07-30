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
    unless session[:cert].blank?
      render :text => session[:cert]
      return
    end

    api_key    = ENV["API_KEY"]
    secret_key = ENV["SECRET_KEY"]
    cert       = params[:cert]
    api_sig    = Digest::MD5.hexdigest(secret_key + "api_key" + api_key + "cert" + cert)
    url        = "http://auth.hatena.ne.jp/api/auth.json?api_key=#{api_key}&cert=#{cert}&api_sig=#{api_sig}"

    res  = Net::HTTP.get(URI.parse(url))
    json = JSON.parser.new(res).parse
  
    # error?
    if json['has_error']
      render :text => 'error occur'
      return
    end

    # if record of user not exists?
    unless User.find_by(cert: cert)
      # create new record
      u_info = json['user']
      user   = User.new
      user.attributes = {
        name: u_info["name"], 
        image_url: u_info["image_url"], 
        thumbnail_url: u_info["thumbnail_url"],
        cert: cert
      }
      user.save
    end

    # create session
    session[:cert] = cert

    render :text => u_info
  end
end
