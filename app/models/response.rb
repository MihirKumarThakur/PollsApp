class Response < ActiveRecord::Base
  validates :answer_choice, :respondent_id, :presence => true

  belongs_to :answer_choice
  # will infer `:foreign_key => :respondent_id` from association name.
  belongs_to :respondent, :class_name => "User"

  validate :respondent_has_not_already_answered_question
  validate :respondent_is_not_poll_author

  private
  def respondent_is_not_poll_author
    poll_author_id = User
      .joins(:authored_polls => { :questions => :answer_choices })
      .where("answer_choices.id = ?", self.answer_choice_id)
      .pluck("users.id")
      .first

    if poll_author_id == self.respondent_id
      errors[:respondent_id] << "cannot be poll author"
    end
  end

  def respondent_has_not_already_answered_question
    _existing_responses = existing_responses

    if _existing_responses.empty?
      # user hasn't responded yet.
    elsif _existing_responses.map(&:id) == [self.id]
      # we're just updating the sole existing response.
    else
      errors[:respondent_id] << "cannot vote twice for question"
    end
  end

  def existing_responses
    sql = <<-SQL
      SELECT
        responses.*
      FROM
        responses
      JOIN
        answer_choices ON responses.answer_choice_id = answer_choices.id
      WHERE
        (responses.respondent_id = :respondent_id AND
          answer_choices.question_id = (
            SELECT
              answer_choices.question_id
            FROM
              answer_choices
            WHERE
              answer_choices.id = :answer_choice_id
            ))
      SQL

    Response.find_by_sql(
      [
        sql, {
          :answer_choice_id => self.answer_choice_id,
          :respondent_id => self.respondent_id
        }
      ]
    )
  end
end

