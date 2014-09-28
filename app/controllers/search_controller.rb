class SearchController < ApplicationController
  before_action :authenticate_user!
  respond_to :json
  def search
    search = Search::ShopSense.new
    filters = {}
    filters[:price] = params[:price] if params[:price]
    filters[:color] = params[:color] if params[:color]
    render :json => search.search(params[:q], filters)
  end
end
