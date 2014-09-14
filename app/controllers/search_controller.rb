class SearchController < ApplicationController
  before_action :authenticate_user!
  respond_to :json
  def search
    search = Search::Semantics.new
    render :json => search.search(params[:q])
  end
end
