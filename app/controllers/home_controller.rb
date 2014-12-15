class HomeController < ApplicationController
  respond_to :html, :json
  caches_action :index, :about, :howitworks, :layout => false
  before_action :authenticate_user!, :only => :embed
  def index
    @page = params[:page] || 1
    @limit = params[:limit] || 30
    @total  = Image.count
    @images = Image.page(@page).per(@limit).desc(:_id)
  end

  def about
     render layout: 'company'
  end

  def embed
     
  end

  def howitworks

  end
end
