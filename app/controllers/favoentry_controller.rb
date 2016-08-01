class FavoentryController < ApplicationController
  require 'rss'
  require 'open-uri'
  require 'date'
  require 'time'

  def show
    @entries = get_entry()
  end

  # If argument is nil, time of now into final_time
  # final_time is unix time
  def get_entry(final_time = Time.now.to_i)
    user = User.find_by(cert: session[:cert])

    url  = "http://b.hatena.ne.jp/#{user[:name]}/favorite.rss?until=#{final_time}"
    # rss server will check UserAgent. So we need to camouflage UserAgent
    opt = {}
    opt['User-Agent'] = 'Opera/9.80 (Windows NT 5.1)'
    open(url, opt) do |res|
      rss     = RSS::Parser.parse(res)
      entries = Array.new
      last_entry_date = ""
      rss.items.each do |item|
        entry = Hash.new
        entry[:title]       = item.title
        entry[:link]        = item.link
        entry[:description] = item.description
        entry[:creator]     = item.dc_creator
        entry[:date]        = last_entry_date = item.dc_date.strftime("%Y-%m-%d %H:%M:%S")
        entry[:favicon]   = item.content_encoded.scan(/<img src="(.+?)"/)[0].join

        # This code is bad. There is a better way than it.
        entry[:head_text] = item.content_encoded.match(/<p>([^<]+?)<\/p>/).to_s.delete("</p>").delete("<p>")

        # Get img of entry. if site have no img, use something text instead of img
        # text is displayed by view
        star_image_url = "http://b.hatena.ne.jp/entry/image/"
        entry[:entry_img] = item.content_encoded.scan(/<img src="(.+?)"/)[1].join
        unless star_image_url+entry[:link] == item.content_encoded.scan(/<img src="(.+?)"/)[1].join
          entry[:entry_img] = item.content_encoded.scan(/<img src="(.+?)"/)[1].join
        else entry[:entry_img] = nil
        end 

        entry[:tags] = []
        item.dc_subjects.each do |tag|
          entry[:tags] << tag.content
        end

        # get bookmark count
        puts
        puts
        count_api_url = "http://api.b.st-hatena.com/entry.count?url="
        open(count_api_url+entry[:link]) {|count| entry[:bookmarkcount] = count}
        puts entry[:bookmarkcount].to_i
        puts
        puts

        entries << entry
      end

      user[:last_entry_date] = last_entry_date
      user.save
      return entries
    end
  end

  def add_show_entry
    user = User.find_by(cert: session[:cert])
    @entries = get_entry(Time.parse(user[:last_entry_date]).to_i)
    render
  end
end
