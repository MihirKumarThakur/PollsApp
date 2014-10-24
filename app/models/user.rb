class User < ActiveRecord::Base
  validates :user_name, presence: true

  has_many(
    :authored_polls,
    class_name: "Poll",
    foreign_key: :author_id,
  )

  has_many :responses, foreign_key: :respondent_id

  def completed_polls
    poll_completion_counts
      .having("COUNT(DISTINCT questions.id) = COUNT(responses.id)")
  end

  def uncompleted_polls
    poll_completion_counts
      .having("COUNT(DISTINCT questions.id) > COUNT(responses.id)")
      .having("COUNT(responses.id) > 0")
  end

  private
  def poll_completion_counts
    select_sql = <<-SQL
polls.*,
COUNT(DISTINCT questions.id) AS num_questions,
COUNT(responses.id) AS num_responses
SQL

    # the interpolation in here is not ideal (I'm lazy tonight), but it is
    # actually safe from injection attack because the end-user doesn't
    # get to pick DB ids.
    joins_sql = <<-SQL
LEFT OUTER JOIN (
  SELECT
    *
  FROM
    responses
  WHERE
    responses.respondent_id = #{self.id}
) AS responses ON answer_choices.id = responses.answer_choice_id
SQL

    # It annoys me that the `HAVING` can't use the column aliases...
    Poll
      .select(select_sql)
      .joins(questions: :answer_choices)
      .joins(joins_sql)
      .group("polls.id")
  end
end
