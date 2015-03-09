class Tivo < ActiveRecord::Base

  def self.reload_devices
    devices = `avahi-browse -p -t -r _tivo-videos._tcp`.split("\n").select {|s| /^=/.match(s) }

    transaction do
      update_all(online: false)

      devices.each do |device|
        parts = device.split(";")
        name = device[3]
        host = device[6]
        ip   = device[7]

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

  class Downloader
    include HTTParty
    default_options[:verify] = false

    def self.setup(ip, mac)
      base_uri "https://#{ip}/TiVoConnect?Command=QueryContainer#{session}"
      digest_auth 'tivo', mac
      resp = get("")
      cookies.add_cookies(resp.headers['set-cookie'])
    end

    def self.session
      "&Session=TivoToRuby"
    end
  end
end
