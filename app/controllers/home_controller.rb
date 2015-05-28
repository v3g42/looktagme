class HomeController < ApplicationController
  respond_to :html, :json
  caches_action :index, :about, :howitworks, :layout => false, :if => Proc.new{|c|!c.request.format.json?}
  before_action :authenticate_user!, :only => :embed
  def index
    @page = params[:page] || 1
    @limit = params[:limit] || 30
    @offset = @page.to_i * @limit.to_i
    @total  = Image.count
    @images = Image.page(@page).per(@limit).desc(:_id)
    respond_to do |format|
      format.html {render :index}
      format.json {render :json => {results: @images.to_json.html_safe, metadata: {page: @page, total: @total, limit: @limit, offset: @offset}} }

    end
  end

  def about
     render layout: 'company'
  end

  def embed
     
  end

  def howitworks

  end

  def heartbeat
    render text: "Hello darling!"
  end
end
