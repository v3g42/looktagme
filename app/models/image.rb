class Image
  include Mongoid::Document
  embeds_many :tags
  has_one :user

  field :image_url, type: String
  field :page_url, type: String

end
