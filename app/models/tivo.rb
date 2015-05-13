require 'io/console'

class Tivo < ActiveRecord::Base
  has_many :videos

  def self.reload_devices
    devices = `avahi-browse -p -t -r _tivo-videos._tcp`.split("\n").select {|s| /^=/.match(s) }

    transaction do
      update_all(online: false)

      devices.each do |device|
        parts = device.split(";")
        name = parts[3]
        host = parts[6]
        ip   = parts[7]

        scope = where(name: name, host: host)
        tivo = scope.first || scope.new
        tivo.ip = ip
        tivo.online = true
        tivo.save
      end
    end
  end

  def read_now_playing
    Tivo::Downloader.setup(ip, mac)
    Container.new("/NowPlaying", self)
  end

  def queue_downloads
    last_downloaded = videos.where(downloaded: true).order(captured_at: :desc).first.captured_at
    videos.by_captured.where('captured_at > ?', last_downloaded).each do |video|
      next if !video.until_deleted? || video.protected? || video.ignore? || video.queued?
      print video.filename
      print ": (y/n) "
      respsone = STDIN.getch
      puts respsone

      video.update_attribute(:queued, true) if respsone == "y"
    end
  end

  def download_queued
    Tivo::Downloader.setup(ip, mac)
    videos.queued.by_captured.each do |download|
      full_filename = File.join(download_dir, download.filename)
      puts full_filename
      FileUtils.mkdir_p(File.dirname(full_filename))

      File.open(full_filename, "wb") do |f|
        Tivo::Downloader.get(download.full_download_url, stream_body: true) do |chunk|
          f.write(chunk)
        end
      end

      s = File.size(full_filename)
      puts "Expected: #{download.size} Actual: #{s} Diff: #{download.size - s} %: #{(download.size - s) / download.size.to_f}"

      download.downloaded = true
      download.queued = false
      download.save

      sleep(5)
    end
  end

  class Downloader
    include HTTParty
    default_options[:verify] = false

    def self.setup(ip, mac)
      base_uri "https://#{ip}/TiVoConnect?Command=QueryContainer#{session}"
      digest_auth 'tivo', mac
      resp = get("")
      cookies.add_cookies(resp.headers['set-cookie']) if resp.headers['set-cookie']
    end

    def self.session
      "&Session=TivoToRuby"
    end
  end
end
