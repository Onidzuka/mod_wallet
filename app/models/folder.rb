class Folder < ApplicationRecord
  has_many :documents

  validates :folder_id, presence: true, numericality: { greater_than: 0 }, uniqueness: true
end
