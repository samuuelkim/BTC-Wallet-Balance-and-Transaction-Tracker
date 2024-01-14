# Cointracker_hiring
To run clone the branch
get into the cointracker directory
> bundle install
> ruby app.rb
Open a new terminal
> irb
> require './app.rb'
this will be your connection to mongo to validate and see all the documents

Open the port that it is describing it should be 127.0.0.1:4567

Create a new account 
Log in to said account
Add a btc address
Once add a proper address you can click on view transactions and that will generate the 50 latest transactions
Doing so will also populate the data in the chart

Technology used:
Ruby, ERB, Sinatra, Mongoid

Considerations:
> When populating the transaction table I only show the latest 50 transactions
> I split it up and have clickables to expand addresses when there are more than 3 address or values
> Since a BTC is a utxo we have to keep track of change
> I sort the values of to so that we know very clearly whow the receipient address is (the highest)
> Made sure to handle all the from addresses and change addresses separately
> Calculate the price of BTC by taking the response from the API for total (divide by 100,000,000 to convert from satoshi to btc)
> Then cache the results of the current USD price to avoid subsequent calls and then take that value and multiply it by the BTC
> All users, transactions, and addresses are stored in a Mongoid model and can be recalled in the IRB terminal
> Users also uses Bcrypt so that in the data base we don't actually see the users password when pulled up
> Some small considerations include success and error flashes when adding / removing BTC + signing up and logging in

I just had really fun with this.  Setting up the back end was really quick as it mirrors what I do on a day to day for a project at Anchor.  The challenging part was the front end and making it visually appealing.  I am very excited to share this.
