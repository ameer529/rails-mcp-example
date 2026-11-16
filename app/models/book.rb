class Book < ApplicationRecord
  validates :title, :author, presence: true

  scope :search, ->(query) {
    pattern = "%#{sanitize_sql_like(query.to_s)}%"
    where("title LIKE :pattern ESCAPE '\\' OR author LIKE :pattern ESCAPE '\\'", pattern: pattern).order(:title)
  }

  def as_tool_hash
    slice(:id, :title, :author, :year, :summary).symbolize_keys
  end
end
