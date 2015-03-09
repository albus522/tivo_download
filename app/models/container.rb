class Container
  attr_reader :videos
  attr_reader :total_items

  def initialize(name, tivo)
    @name = name
    @tivo = tivo
    @videos = []
    load_container
  end

  def reload
    @total_items = nil
    @videos = []
    load_container
  end

  def load_container(offset = 0)
    puts "&Container=#{URI.encode_www_form_component(@name)}&AnchorOffset=#{offset}&ItemCount=50&Recurse=Yes"
    resp = Tivo::Downloader.get("&Container=#{URI.encode_www_form_component(@name)}&AnchorOffset=#{offset}&ItemCount=50&Recurse=Yes")
    raise "Invalid response received", resp.parsed_response.inspect unless resp.parsed_response.key?("TiVoContainer")

    hash = resp.parsed_response["TiVoContainer"]
    @total_items ||= hash["Details"]["TotalItems"].to_i

    if hash["Item"]
      raise "Returned items count does not match" unless hash["ItemCount"].to_i == hash["Item"].size
      hash["Item"].each {|i| @videos << Video.parse(i, @tivo) }
    end

    load_container(offset + 50) if @videos.size < @total_items
  end
end

# {
#   "TiVoContainer"=>{
#     "Details"=>{
#       "ContentType"=>"x-tivo-container/tivo-videos",
#       "SourceFormat"=>"x-tivo-container/tivo-dvr",
#       "Title"=>"Now Playing",
#       "LastChangeDate"=>"0x54F3C6F2",
#       "TotalItems"=>"40",
#       "UniqueId"=>"/NowPlaying"
#     },
#     "SortOrder"=>"Type,CaptureDate",
#     "GlobalSort"=>"Yes",
#     "ItemStart"=>"0",
#     "ItemCount"=>"40",
#     "Item"=>[...]
#   }
# }
