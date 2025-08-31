class Avo::Resources::ShipwrightAdvice < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :project, as: :belongs_to
    field :ship_certification, as: :belongs_to
    field :description, as: :textarea
    field :status, as: :number
    field :shell_reward, as: :number
    field :completed_at, as: :date_time
  end
end
