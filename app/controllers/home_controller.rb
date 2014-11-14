class HomeController < ApplicationController
  respond_to :html, :json
  #caches_action :index, :about, :howitworks, :layout => false
  def index
    @page = params[:page] || 1
    @limit = params[:limit] || 30
    @total  = Image.count
    @images = Image.page(@page).per(@limit).desc(:_id)
  end

  def about
     render layout: 'company'
  end
  def howitworks

  end
end
