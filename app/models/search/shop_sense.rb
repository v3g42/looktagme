require 'rubygems'
require 'shopsense'


class Search::ShopSense
  PARTNER_ID = "uid2564-29493758-16"
  COLORS = JSON.parse(File.read(File.join(__dir__,"shop_sense/colors.json")))
  PRICES = JSON.parse(File.read(File.join(__dir__,"shop_sense/price_histogram.json")))


  def initialize
    @shopsense = Shopsense::API.new({'partner_id' => PARTNER_ID})

  end

  def self.prices()
    PRICES.map do |k|
      range = k["name"].gsub(/[,$]/, '').scan(/\w+/)
      {id: k["id"], range: range}
    end
  end


  def get_brands(search_string)
    raise "no search string provided!" if( search_string === nil)

    filterType = "filters=Brand"
    fts = "fts=" + search_string.split().join( '+').to_s
    args  = [filterType, fts].join( '&')

    return call_api( "/products/histogram?", args)
  end


  def search(query, options={}, offset=0, limit=10)


    filters = []
    categories = []
    query = "fts=#{URI.encode(query)}"
    if options[:color].present?
      options[:color].split("_").map do |color|
        filters << "c#{color}"
        end
    end
    if options[:price].present?
      filters = filters.concat([options[:price]])
    end
    if options[:brands].present?
      filters = filters.concat(options[:brands].split("_"))
    end
    if options[:categories].present?
      categories = categories.concat(options[:categories].split("_"))
    end
    fts = filters.map do |filter|
      "fl=#{filter}"
    end.join('&')
    cat = categories.map do |filter|
      "cat=#{filter}"
    end.join('&')
    offset = "offset=#{offset}"
    limit = "limit=#{limit}"
    args = [query,fts, offset, limit, cat].join( '&')
    filter(JSON.parse(call_api( __method__, args)))
  end



  def call_api( method, args = nil)

    method_url  = @shopsense.api_url  + (@shopsense.respond_to?("#{method}_path") ? @shopsense.send( "#{method}_path") : method )
    pid         = "pid="        + @shopsense.partner_id
    format      = "format="     + @shopsense.format
    site        = "site="       + @shopsense.site

    if( args === nil) then
      uri   = URI.parse( method_url.to_s + [pid, format, site].join('&').to_s)
    else
      uri   = URI.parse( method_url.to_s + [pid, format, site, args].join('&').to_s)
    end
    puts "Calling ShopSense API => #{uri}"
    return Net::HTTP.get( uri)
  end
  def filter(response)
    results = response["products"]
    puts results
    results=  results.map do |product|
      #TODO: This has to be based on the client
      image = product["image"]["sizes"]["Large"]
      {
          :title => product["name"],
          :description => product["description"],
          :price => product["priceLabel"],
          :currency => product["currency"],
          :seller_name => product["retailer"]["name"],
          :seller_url => product["clickUrl"],
          :image_url => image["url"],
          :image_width => image["width"],
          :image_height => image["height"]

      }
    end
    {
        :metadata => response["metadata"],
        :results => results
    }
  end
end