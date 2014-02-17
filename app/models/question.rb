class Question < ActiveRecord::Base
  attr_accessible :poll_id, :text

  validates :poll_id, :text, :presence => true

  has_many :answer_choices
  belongs_to :poll

  def results
    # Note that this somewhat tortured solution serves two goals:
    # 1. Avoid N+1 query
    # 2. Avoid fetching all the `Response`s (there could be many!)

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

    # Here's a simpler solution that fails goal #2:
    # answer_choices = self
    #   .answer_choices
    #   .includes(:responses)
    # {}.tap do |results|
    #   answer_choices.each do |ac|
    #     results[ac.text] = ac.responses.length
    #   end
    # end
  end
end
