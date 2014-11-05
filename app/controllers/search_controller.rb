class SearchController < ApplicationController
  before_action :authenticate_user!
  respond_to :json
  def search

    text = params[:q]

    if ::Scraper.uri?(text)
      @scraper = Scraper.new(text)
      data = @scraper.scrape
      data["type"] = "scraper"
      render :json => data
    else
      search = Search::ShopSense.new
      #search = Search::Semantics.new
      filters = {}
      filters[:price] = params[:price] if params[:price]
      filters[:color] = params[:color] if params[:color]
      filters[:brands] = params[:brands] if params[:brands]
      filters[:categories] = params[:categories] if params[:categories]
      offset = params[:offset] || 0
      limit = params[:limit] || 10
      render :json => search.search(text, filters,offset, limit)
    end

  end

  def brands
    search = Search::ShopSense.new
    render :json => search.get_brands(params[:q])
  end

  def retailers
    search = Search::ShopSense.new
    render :json => search.get_brands(params[:q])
  end

end
