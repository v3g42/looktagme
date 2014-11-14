class SearchController < ApplicationController
  before_action :authenticate_user!
  respond_to :json
  caches_action :proxy, :cache_path => Proc.new { |c| search_proxy_url(c.params[:url]) }, :expires_in => 2.hours
  caches_action :brands, :retailers, :expires_in => 2.hours
  def search
    text = params[:q]
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

  def proxy
    text = params[:url]
    if ::Scraper.uri?(text)
      @scraper = Scraper.new(text, request.env["HTTP_USER_AGENT"])
      render :text => @scraper.proxy
    else
      render :status => :unprocessable_entity
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
