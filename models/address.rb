class Address
  include Mongoid::Document
  belongs_to :user
  field :btc_address, type: String
  field :total_balance_in_usd, type: Float
  field :total_balance_in_satoshi, type: Float

  has_many :transactions

  validates :btc_address, uniqueness: true
end
