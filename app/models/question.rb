class Question < ActiveRecord::Base
  attr_accessible :poll_id, :text

  validates :poll_id, :text, :presence => true

  has_many :answer_choices
  belongs_to :poll

  def results
    select_sql = <<-SQL
      answer_choices.*,
      COUNT(responses.id) AS response_count
    SQL

    responses_joins_sql = <<-SQL
      LEFT OUTER JOIN
        responses ON answer_choices.id = responses.answer_choice_id
    SQL

    answer_choices = self
      .answer_choices
      .select(select_sql)
      .joins(responses_joins_sql)
      .group("answer_choices.id")

    {}.tap do |results|
      answer_choices.each do |answer_choice|
        results[answer_choice.text] =
          Integer(answer_choice.response_count)
      end
    end
  end
end
