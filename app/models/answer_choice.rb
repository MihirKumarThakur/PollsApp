class AnswerChoice < ActiveRecord::Base

  validates :question_id, :text, :presence => true

  belongs_to :question
  has_many :responses
end
