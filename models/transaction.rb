class Transaction
  include Mongoid::Document
  belongs_to :address

  field :transaction_id, type: String

  field :from_addresses, type: Array # Array of from addresses
  field :from_amounts, type: Array # Array of from amounts in BTC
  field :from_amounts_in_usd, type: Array # Array of from amounts in USD

  field :change_addresses, type: Array # Array of change addresses

  field :change_amounts, type: Array # Array of change amounts
  field :change_amounts_in_usd, type: Array # Array of change amounts in USD

  field :to_address, type: String # Recipient address
  field :to_amount, type: Float # Transaction amount for the recipient address
  field :to_amount_in_usd, type: Float # Transaction amount for the recipient address in USD
  field :timestamp, type: Time
end
