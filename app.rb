require 'sinatra'
require 'mongoid'
require 'dotenv'
require 'sinatra/flash'
require 'chartkick'

enable :sessions
set :public_folder, 'public'

Dotenv.load
Mongoid.load!('mongoid.yml', :development)

require './models/user'
require './models/address'
require './models/transaction'
require './client/blockchain_api_client'


get '/' do
  redirect to('/login')
end

get '/login' do
  erb :login
end

post '/login' do
  user = User.where(username: params[:username]).first
  if user && user.password == params[:password]
    session[:user_id] = user._id
    redirect '/dashboard'
  else
    flash[:error] = 'Invalid username or password.'
    redirect '/login'
  end
end

get '/logout' do
  session.clear
  redirect '/login'
end

get '/dashboard' do
  @user = User.find(session[:user_id])
  @addresses = @user.addresses || []

  @total_balance = @addresses.empty? ? 0 : @addresses.sum(&:total_balance_in_usd)

  daily_total_balance = Hash.new(0)

  unless @addresses.empty?
    @addresses.each do |address|
      address.transactions.desc(:timestamp).each do |transaction|
        # Check if the 'to_address' is the current address or if the 'from_address' includes the current address
        if transaction.to_address == address.btc_address || transaction.from_addresses.include?(address.btc_address)
          date = transaction.timestamp.to_date
          total_from_amounts = transaction.from_amounts.sum
          balance_change_btc = total_from_amounts - transaction.to_amount
          balance_change = BlockchainAPIClient.convert_btc_to_usd(balance_change_btc, CacheHelper.get_cached_btc_to_usd_rate)
          daily_total_balance[date] += balance_change
        end
      end
    end
  end

  # Formatting data for Chartkick
  @balance_over_time_data = {
    daily: daily_total_balance.transform_keys { |date| date.strftime('%Y-%m-%d') }
  }

  puts "Balance over time data: #{@balance_over_data}"
  erb :dashboard, layout: :layout
end

get '/signup' do
  erb :signup
end

post '/signup' do
  user = User.new(username: params[:username], password: params[:password])
  if user.save
    flash[:success] = 'Account successfully created. Please log in.'
    redirect '/login'
  else
    error_message = user.errors.full_messages.join(', ')
    flash[:error] = "Signup failed: #{error_message}"
    redirect '/signup'
  end
end
# Add a new Bitcoin address
post '/addresses' do
  user = User.find(session[:user_id])
  btc_address = params[:btc_address]

  existing_address = user.addresses.where(btc_address: btc_address).first

  if existing_address
    flash[:error] = 'BTC address already exists.'
  else
    begin
      # Attempt to retrieve the balance
      balance_response = BlockchainAPIClient.get_balance(btc_address)
      if balance_response && balance_response[btc_address.to_sym]
        final_balance_satoshi = balance_response[btc_address.to_sym][:final_balance]
        final_balance_btc = final_balance_satoshi.to_f / 100_000_000
        btc_to_usd_rate = CacheHelper.get_cached_btc_to_usd_rate
        # Convert BTC to USD
        usd_amount = BlockchainAPIClient.convert_btc_to_usd(final_balance_btc, btc_to_usd_rate)

        # Create a new Address object with balances
        address = Address.new(
          btc_address: btc_address,
          user: user,
          total_balance_in_usd: usd_amount,
          total_balance_in_satoshi: final_balance_satoshi
        )
        if address.save
          flash[:success] = 'BTC address added successfully.'
        end
      else
        flash[:error] = 'Invalid BTC address or unable to retrieve balance.'
      end
    rescue RestClient::BadRequest => e
      flash[:error] = 'Invalid BTC address. Please check and try again.'
    end
  end
  redirect '/dashboard'
end

# Remove a Bitcoin address
delete '/remove_address/:id' do
  user = User.find(session[:user_id])

  address = user.addresses.find(params[:id])
  if address && address.destroy
    puts "Address #{address.btc_address} removed successfully" # Add this line
    flash[:success] = 'BTC address removed successfully.'
  else
    puts "Failed to remove address with ID: #{params[:id]}" # Add this line
    flash[:error] = 'Failed to remove BTC address.'
  end

  redirect '/dashboard'
end

# Get all Bitcoin addresses and their balances
# Get transactions for a specific address
get '/transactions/:address' do
  @user = User.find(session[:user_id])
  @address = @user.addresses.where(btc_address: params[:address]).first
  response = BlockchainAPIClient.get_single_address(@address.btc_address)
  transactions_data = response[:txs]
  btc_to_usd_rate = CacheHelper.get_cached_btc_to_usd_rate
  # add paging and a loop to get all transactions
  # for now leave as 50 transactions
  @transactions = transactions_data.map do |tx_data|
    outputs = tx_data[:out].sort_by { |out| -out[:value] } # Sort outputs in descending order of value
    from_amounts_btc = tx_data[:inputs].map { |input| (input[:prev_out][:value] / 100_000_000.0).round(8) }
    change_amounts_btc = outputs[1..-1].map { |out| (out[:value] / 100_000_000.0).round(8) }
    to_amount_btc = (outputs[0][:value] / 100_000_000.0).round(8)

    Transaction.create!(
      address: @address,
      transaction_id: tx_data[:hash],
      from_addresses: tx_data[:inputs].map { |input| input[:prev_out][:addr] },
      change_addresses: outputs[1..-1].map { |out| out[:addr] }, # Skip the first output (recipient address)
      to_address: outputs[0][:addr], # Recipient address is the one with the highest amount
      change_amounts: change_amounts_btc,
      change_amounts_in_usd: change_amounts_btc.map { |amt| BlockchainAPIClient.convert_btc_to_usd(amt, btc_to_usd_rate) },
      from_amounts: from_amounts_btc,
      from_amounts_in_usd: from_amounts_btc.map { |amt| BlockchainAPIClient.convert_btc_to_usd(amt, btc_to_usd_rate) },
      to_amount: to_amount_btc,
      to_amount_in_usd: BlockchainAPIClient.convert_btc_to_usd(to_amount_btc, btc_to_usd_rate),
      timestamp: tx_data[:time]
    )
  end

  erb :transactions, layout: :'layout'
end

module CacheHelper
  @rate_cache = { value: nil, updated_at: Time.now - 2 * 3600 }

  def self.get_cached_btc_to_usd_rate
    if Time.now - @rate_cache[:updated_at] > 3600
      @rate_cache[:value] = BlockchainAPIClient.get_exchange_rates[:USD][:last]
      @rate_cache[:updated_at] = Time.now
    end

    @rate_cache[:value]
  end
end

## test db
get '/test_db' do
  begin
    test_user = User.create(username: "testuser", password: "testpass")
    "User created: #{test_user.username}"
  rescue => e
    "Error: #{e.message}"
  end
end
