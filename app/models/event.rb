class Event < ApplicationRecord

  include PaginatesByDate

  date_pagination_column_name :starts_at

  scope :active, -> { where(state: "active") }

end
