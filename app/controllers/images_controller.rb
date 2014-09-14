class ImagesController < ApplicationController
  respond_to :html, :json

  def edit
    return render status :bad_request unless params[:image_url]

    @image = Image.where(:image_url => params[:image_url]).first

  end
end
