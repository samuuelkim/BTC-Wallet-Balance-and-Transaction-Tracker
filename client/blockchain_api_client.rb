require 'rest-client'
require 'json'

class BlockchainAPIClient
  API_URL = "https://blockchain.info"

  def self.get_single_address(bitcoin_address, limit = 50, offset = 0)
    path = "/rawaddr/#{bitcoin_address}?limit=#{limit}&offset=#{offset}"
    make_api_get_request(path)
  end

  def self.get_balance(address)
    addresses = [address]
    addresses_param = addresses.join("|")
    path = "/balance?active=#{addresses_param}"
    make_api_get_request(path)
  end

  def self.get_single_address(bitcoin_address, limit = 50, offset = 0)
    path = "/rawaddr/#{bitcoin_address}?limit=#{limit}&offset=#{offset}"
    make_api_get_request(path)
  end

  def self.get_multi_address(addresses, limit = 50, offset = 0)
    addresses = [address]
    addresses_param = addresses.join("|")
    path = "/multiaddr?active=#{addresses_param}&n=#{limit}&offset=#{offset}"
    make_api_get_request(path)
  end

  def self.get_exchange_rates
    path = "/ticker"
    response = make_api_get_request(path)
    response
  end

  def self.get_unspent_outputs(addresses, limit = 250, confirmations = 6)
    addresses = [address]
    addresses_param = addresses.join("|")
    path = "/unspent?active=#{addresses_param}&limit=#{limit}&confirmations=#{confirmations}"
    make_api_get_request(path)
  end

  def self.convert_btc_to_usd(amount_btc, usd_exchange_rate)
    final_balance_usd = amount_btc * usd_exchange_rate
    final_balance_usd.round(2)
  end

  def self.make_api_get_request(path)
    begin
      response = RestClient.get("#{API_URL}#{path}")
      JSON.parse(response.body, symbolize_names: true)
    rescue RestClient::ExceptionWithResponse => e
      puts "Error: GET #{API_URL}#{path} #{e.response&.body}"
      raise
    end
  end
end
