class Video < ActiveRecord::Base
  ILLEGAL_CHARS = /[\/\?\<\>\\\:\*\|\"]/

  belongs_to :tivo

  serialize :data, Hash

  scope :queued,      lambda { where(queued: true) }
  scope :by_captured, lambda { order(:captured_at) }

  def self.parse(hash, tivo)
    captured_at = Time.at(hash["Details"]["CaptureDate"].to_i(16))
    title       = hash["Details"]["Title"]
    episode     = hash["Details"]["EpisodeTitle"]

    scope = where(tivo_id: tivo.id, captured_at: captured_at, title: title, episode: episode)
    scope.first || scope.create(data: hash)
  end

  def until_deleted?
    links["CustomIcon"] && links["CustomIcon"]["Url"].match(/save-until-i-delete-recording/)
  end

  def full_download_url
    links["Content"]["Url"] + "&Format=video/x-tivo-mpeg" + Tivo::Downloader.session
  end

  def size
    details["SourceSize"].to_i
  end

  def episode_number
    details["EpisodeNumber"]
  end

  def station
    details['SourceStation']
  end

  def protected?
    links["Content"]["Available"] == "No"
  end

  def ignore?
    ["0", "1"].include?(details["UniqueId"])
  end

  def folder
    clean(title).gsub(/\.+$/, '') if title.present? && episode.present?
  end

  def filename
    name = clean([title, episode_number, episode].reject(&:blank?).join(' - '))
    File.join([folder, "#{name} (Recorded #{captured_at.strftime('%b %d, %Y')}, #{clean(station)}).TiVo"].reject(&:blank?))
  end

  def details
    data["Details"]
  end

  def links
    data["Links"]
  end

  def clean(str)
    str.gsub(ILLEGAL_CHARS, '')
  end
end

# {
#   "Details"=>{
#     "ContentType"=>"video/x-tivo-raw-tts",
#     "SourceFormat"=>"video/x-tivo-raw-tts",
#     "Title"=>"Person of Interest",
#     "SourceSize"=>"5200936960",
#     "Duration"=>"3658000",
#     "CaptureDate"=>"0x54ED3AAE",
#     "ShowingDuration"=>"3540000",
#     "StartPadding"=>"60000",
#     "EndPadding"=>"60000",
#     "ShowingStartTime"=>"0x54ED3AEC",
#     "EpisodeTitle"=>"Blunt",
#     "Description"=>"Reese and Finch must protect a street-smart grifter after her plan to steal cash from a medical marijuana dispensary fails. Copyright Tribune Media Services,
#     Inc.",
#     "SourceChannel"=>"233",
#     "SourceStation"=>"WWMTDT",
#     "HighDefinition"=>"Yes",
#     "ProgramId"=>"EP014198470084",
#     "SeriesId"=>"SH01419847",
#     "EpisodeNumber"=>"416",
#     "StreamingPermission"=>"Yes",
#     "TvRating"=>"5",
#     "ShowingBits"=>"397315",
#     "SourceType"=>"2",
#     "IdGuideSource"=>"34884"
#   },
#   "Links"=>{
#     "Content"=>{
#       "Url"=>"http://192.168.2.22:80/download/Person%20of%20Interest.TiVo?Container=%2FNowPlaying&id=82559",
#       "ContentType"=>"video/x-tivo-raw-tts"
#     },
#     "CustomIcon"=>{
#       "Url"=>"urn:tivo:image:save-until-i-delete-recording",
#       "ContentType"=>"image/*",
#       "AcceptsParams"=>"No"
#     },
#     "TiVoVideoDetails"=>{
#       "Url"=>"https://192.168.2.22:443/TiVoVideoDetails?id=82559",
#       "ContentType"=>"text/xml",
#       "AcceptsParams"=>"No"
#     }
#   }
# }
