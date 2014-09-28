require 'rubygems'
require 'shopsense'


class Search::ShopSense
  PARTNER_ID = "uid7025-25426545-48"
  COLORS = [{name:'Black', color: 'rgb(0,0,0)', id:16},
       {name:'Gray', color: 'rgb(127,127,127)', id:14},
       {name:'Silver', color: 'rgb(192,192,192)', id:19},
       {name:'White', color: 'rgb(255,255,255)', id:15},
       {name:'Red', color: 'rgb(255,0,0)', id:7},
       {name:'Pink', color: 'rgb(255,20,147)', id:17},
       {name:'Purple', color: 'rgb(128,0,128)', id:8},
       {name:'Blue', color: 'rgb(0,0,255)', id:10},
       {name:'Green', color: 'rgb(0,255,0)', id:13},
       {name:'Yellow', color: 'rgb(255,255,0)', id:4},
       {name:'Gold', color: 'rgb(255,215,0)', id:18},
       {name:'Orange', color: 'rgb(255,127,0)', id:3},
       {name:'Brown', color: 'rgb(139,69,19)', id:1},
       {name:'Beige', color: 'rgb(245,245,220)', id:20}
  ]
  PRICES = [
      {
          id: "7",
          name: "$0 – $25",
          count: 251080
      },
      {
          id: "8",
          name: "$25 – $50",
          count: 288822
      },
      {
          id: "9",
          name: "$50 – $100",
          count: 314239
      },
      {
          id: "10",
          name: "$100 – $150",
          count: 166197
      },
      {
          id: "11",
          name: "$150 – $250",
          count: 175435
      },
      {
          id: "12",
          name: "$250 – $500",
          count: 169180
      },
      {
          id: "13",
          name: "$500 – $1,000",
          count: 96312
      },
      {
          id: "14",
          name: "$1,000 – $2,500",
          count: 59846
      },
      {
          id: "15",
          name: "$2,500 – $5,000",
          count: 15673
      },
      {
          id: "16",
          name: "$5,000+",
          count: 6593
      }
  ]


  def initialize
    @shopsense = Shopsense::API.new({'partner_id' => PARTNER_ID})

  end

  def self.prices()
    PRICES.map do |k|
      range = k[:name].gsub(/[,$]/, '').scan(/\w+/)
      {id: k[:id], range: range}
    end
  end

  def search(query, options={})


    filters = []
    query = "fts=#{query}"
    if options[:color].present?
      options[:color].split("_").map do |color|
        filters << "c#{color}"
        end
    end
    if options[:price].present?
      filters << options[:price].gsub("_",",")
    end

    fts = filters.map do |filter|
      "fl=#{filter}"
    end.join('&')
    args = [query,fts].join( '&')
    filter(JSON.parse(call_api( __method__, args)))
  end



  def call_api( method, args = nil)
    method_url  = @shopsense.api_url  + @shopsense.send( "#{method}_path")
    pid         = "pid="        + @shopsense.partner_id
    format      = "format="     + @shopsense.format
    site        = "site="       + @shopsense.site

    if( args === nil) then
      uri   = URI.parse( method_url.to_s + [pid, format, site].join('&').to_s)
    else
      uri   = URI.parse( method_url.to_s + [pid, format, site, args].join('&').to_s)
    end

    return Net::HTTP.get( uri)
  end
  def filter(response)
    results = response["products"]
    puts results
    results=  results.map do |product|
      #TODO: This has to be based on the client
      image = product["image"]["sizes"]["Medium"]
      {
          :title => product["name"],
          :description => product["description"],
          :price => product["priceLabel"],
          :currency => product["currency"],
          :seller_name => product["retailer"]["name"],
          :seller_url => product["pageUrl"],
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