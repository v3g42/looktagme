class Tag
  include Mongoid::Document
  has_one :user
  embedded_in :image

  field :x, type: Float
  field :y, type: Float
  field :title, type: String
  field :description, type: String
  field :price, type: Float
  field :seller_url, type: String
  field :seller_name, type: String
  field :image_url, type: String
  field :image_width, type: Float
  field :image_height, type: Floa

  validates_presence_of :x, :y, :title, :description, :image_url, :seller_url, :seller_name

end
