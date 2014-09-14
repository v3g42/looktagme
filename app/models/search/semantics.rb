require 'httparty'
class Search::Semantics
  include HTTParty
  base_uri "https://api.semantics3.com"

  def initialize
    @headers = {
        "api_key" => "SEM3A1931CD48EE0C6A1DB4FA64D9D70DA7C",
        "api_secret" => "MzMzZGQyYzliZmJiZjM2MzdkNzJjMDNhOGJkYTQ5MGU"
    }
  end

  def search(query, options={})
    search = {:search => query}
    options.merge!({:headers => @headers, :query => {:q => search.to_json}})
    response = self.class.get('/test/v1/products', options)
    filter(response)
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