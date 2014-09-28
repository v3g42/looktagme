require 'rubygems'
require 'semantics3'

class Search::Semantics
  API_KEY = 'SEM3A1931CD48EE0C6A1DB4FA64D9D70DA7C'
  API_SECRET = 'MzMzZGQyYzliZmJiZjM2MzdkNzJjMDNhOGJkYTQ5MGU'

  def initialize
    @sem3 = Semantics3::Products.new(API_KEY, API_SECRET)
  end

  def search(query, options={})
    hash = {:search => query}
    hash.merge!(options)
    filter(@sem3.run_query("products", hash))
  end

  private
  def filter(response)
    results = response["results"]
    puts results
    results.map do |product|

        seller = product["sitedetails"][0] if product["sitedetails"].present?
        {
            :title => product["name"],
            :description => product["description"],
            :price => seller ? seller["latestoffers"][0]["price"]: product["price"],
            :currency => seller ? seller["latestoffers"][0]["currency"] : product["price_currency"],
            :seller_name => seller ? seller["name"] : "",
            :seller_url => seller ? seller["url"] : "",
            :image_url => product["images"][0],
            :raw_details => seller ? product["sitedetails"][0] : ""
        }
      {
          :metadata => nil,
          :results => results
      }
    end
  end
end