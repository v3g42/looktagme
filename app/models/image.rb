class Image
  include Mongoid::Document
  embeds_many :tags
  belongs_to :user

  field :image_url, type: String
  field :page_url, type: String

end
