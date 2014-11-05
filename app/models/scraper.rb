require 'wombat'

class Scraper


 class << self
   def uri?(string)
     uri = URI.parse(string)
     %w( http https ).include?(uri.scheme)
   rescue URI::BadURIError
     false
   rescue URI::InvalidURIError
     false
   end
 end

 def initialize(url)
   @base_url = URI.parse(url)
 end

  def scrape
    u = @base_url
    Wombat.crawl do
      base_url "#{u.scheme}://#{u.host}:#{u.port}"
      path "#{u.path}?#{u.query}"

      seller_url u.to_s
      description({xpath: ".//meta[@name='description']/@content"})
      price(css: 'price')
      title({xpath: ".//title"})
      images({ css: "img" }, :iterator) do
        width({ xpath: ".//@width" })
        height({ xpath: ".//@height" })
        src({ xpath: ".//@src" })
      end
    end
  end

end