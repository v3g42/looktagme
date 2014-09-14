require 'rubygems'
require 'semantics3'

class Search::Semantics
  API_KEY = 'SEM3A1931CD48EE0C6A1DB4FA64D9D70DA7C'
  API_SECRET = 'MzMzZGQyYzliZmJiZjM2MzdkNzJjMDNhOGJkYTQ5MGU'

  def initialize
    @sem3 = Semantics3::Products.new(API_KEY, API_SECRET)
  end

  def search(query)
    filter(@sem3.run_query("products", {:search => query}))
  end

  private
  def filter(response)
    results = response["results"]
    results.map do |product|
      if product["sitedetails"].present?
        seller = product["sitedetails"][0]
        {
            :title => product["name"],
            :description => product["description"],
            :price => seller["latestoffers"][0]["price"],
            :currency => seller["latestoffers"][0]["currency"],
            :seller_name => seller["name"],
            :seller_url => seller["url"],
            :image_url => product["images"][0],
            :raw_details => product["sitedetails"][0]
        }
      end
    end
  end
end