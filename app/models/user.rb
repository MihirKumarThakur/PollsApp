class User < ActiveRecord::Base
  attr_accessible :user_name

  validates :user_name, :presence => true

  has_many(
    :authored_polls,
    :class_name => "Poll",
    :foreign_key => :author_id,
  )

  has_many :responses, :foreign_key => :respondent_id
end
