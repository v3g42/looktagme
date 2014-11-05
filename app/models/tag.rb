class Tag
  include Mongoid::Document
  has_one :user
  embedded_in :image

  field :x, type: Float
  field :y, type: Float
  field :title, type: String
  field :description, type: String
  field :price, type: String
  field :seller_url, type: String
  field :seller_name, type: String
  field :image_url, type: String
  field :image_width, type: Float
  field :image_height, type: Float
  field :currency, type: String
  field :page_url, type: Float

  #validates_presence_of :x, :y, :title, :description, :image_url, :seller_url, :seller_name
  validates_presence_of :x, :y, :image_url, :seller_url

end
