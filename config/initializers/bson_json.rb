

module Mongoid::Document
  def serializable_hash(options = nil)
    h = super(options)
    h['id'] = h.delete("_id").to_s
    h
  end
end