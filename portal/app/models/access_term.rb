class AccessTerm < ActiveRecord::Base

  include ReadOnlyModels

  # attr_accessible :title, :body
  has_many :access_term_associations
end