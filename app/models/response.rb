class Response < ActiveRecord::Base
  validates :answer_choice, :respondent, presence: true

  belongs_to :answer_choice, inverse_of: :responses
  # will infer `:foreign_key => :respondent_id` from association name.
  belongs_to :respondent, class_name: "User"

  has_one :question, through: :answer_choice

  validate :respondent_has_not_already_answered_question
  validate :respondent_is_not_poll_author

  def sibbling_responses
    # 2-query way
    self.question.responses
      .where("responses.respondent_id = ?", self.respondent_id)
      .where(
        "(:id IS NULL) OR (responses.id != :id)",
        id: self.id
      )
  end

  private
  def respondent_is_not_poll_author
    # The 3-query slow way:
    # poll_author_id = self.answer_choice.question.poll.author_id

    # 1-query; joins two extra tables.
    poll_author_id = Poll
      .joins(questions: :answer_choices)
      .where("answer_choices.id = ?", self.answer_choice_id)
      .pluck("polls.author_id")
      .first

    if poll_author_id == self.respondent_id
      errors[:respondent_id] << "cannot be poll author"
    end
  end

  def respondent_has_not_already_answered_question
    return if sibbling_responses.empty?
    errors[:respondent_id] << "cannot vote twice for question"
  end
end
