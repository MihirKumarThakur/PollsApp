class Question < ActiveRecord::Base
  validates :poll, :text, presence: true

  has_many :answer_choices
  belongs_to :poll

  has_many :responses, through: :answer_choices

  def results
    # N+1 way:
    # results = {}
    # self.answer_choices.each do |ac|
    #   results[ac.text] = ac.responses.count
    # end
    # results

    # 2-queries; all responses transferred:
    # results = {}
    # self.answer_choices.includes(:responses).each do |ac|
    #   results[ac.text] = ac.responses.length
    # end
    # results

    # 1-query way
    acs = self.answer_choices
      .select("answer_choices.*, COUNT(responses.id) AS num_responses")
      .joins(<<-SQL).group("answer_choices.id")
LEFT OUTER JOIN responses ON answer_choices.id = responses.answer_choice_id
SQL

    acs.inject({}) do |results, ac|
      results[ac.text] = ac.num_responses; results
    end
  end
end
