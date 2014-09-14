class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include User::AuthDefinitions
  include User::Roles

  has_many :identities

  has_many :images


  field :email, type: String
  field :image, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :roles_mask, type: Integer

  field :app_id, type: String
  
  validates_presence_of :email, :first_name, :last_name

  before_create :generate_app_id

  def full_name
    "#{first_name} #{last_name}"
  end

  protected

  def generate_app_id
    self.app_id = SecureRandom.hex(10)
    generate_app_id if User.where(app_id: self.app_id).exists?
  end

end
