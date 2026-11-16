class Book < ApplicationRecord
  validates :title, :author, presence: true

  scope :search, ->(query) {
    pattern = "%#{sanitize_sql_like(query.to_s)}%"
    where("title LIKE :pattern ESCAPE '\\' OR author LIKE :pattern ESCAPE '\\'", pattern: pattern).order(:title)
  }

  def to_listing
    slice(:id, :title, :author, :year).symbolize_keys
  end

  def to_detail
    to_listing.merge(summary:)
  end
end
