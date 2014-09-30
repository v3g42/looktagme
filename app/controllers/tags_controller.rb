class TagsController < ApplicationController
  before_action :authenticate_user!, :except => :index
  respond_to  :json,:html
  layout "editor"
  def edit
    return render status :bad_request unless params[:image_url]

    @page_url = params[:page_url]
    @image_url = params[:image_url]
    @domain = params[:domain]
    @dom_id = params[:dom_id]

    @image = Image.where(:image_url => params[:image_url]).first

    @prices = Search::ShopSense.prices

    @colors = Search::ShopSense::COLORS

  end

  def create
    #params.permit(:x, :y, :title, :description, :price, :seller, :seller_name, :seller_url, :image_url, :image_width, :image_height, :image_width, :id, :currency, :raw_details, :page_url)
    image = nil
    params.require(:tag).permit!
    image = current_user.images.where(:image_url => params[:image_url]).first
    unless(image)
      image = Image.new({:image_url => params[:image_url],:page_url =>  params[:page_url]})
      image.user = current_user
      return render :json => {:message => image.errors.join(",")},:status => :unprocessable_entity  unless image.save
    end
    t = Tag.new(params[:tag])
    t.image = image
    if(t.save)
      render :json => t
    else
      render :json => {:message => t.errors.join(",")},:status => :unprocessable_entity
    end

  end

  def index
    return render :json => {:message => "image_url or app_id not set"}, :status => :bad_request unless params[:image_url].present? || params[:app_id].present?
    user = User.where(:app_id => params[:app_id]).first
    if(user)
      image = user.images.where(:image_url => params[:image_url]).first
      if image
        render :json => image
      else
        render :json => {:message => "image_url not found"},:status => :not_found
      end

    else
      render :json => {:message => "app_id not found"},:status => :not_found
    end
  end
  def recent
    return render :json => {:message => "image_url not set"}, :status => :bad_request unless params[:image_url]

    image = Image.where(:image_url => params[:image_url]).first
    if image
      render :json => image
    else
      render :json => {:message => "image_url not found"},:status => :not_found
    end
  end

  def destroy
    t = Image.find(params[:image_id]).tags.find(params[:id])
    if(t.destroy)
      render :json => t
    else
      render :json => t, :status =>  :unprocessable_entity
    end
  end
end
