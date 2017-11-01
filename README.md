# Blockchain.rb

This repository contains a [blockchain implementation](https://hackernoon.com/learn-blockchains-by-building-one-117428612f46) described by [Daniel van Flymen](https://github.com/dvf) in pure ruby and sinatra.

### Installation

This will only require [`sinatra`](http://www.sinatrarb.com/) to run.

```ruby
gem install sinatra
```

To start the server, run

```
ruby server.rb
```

and it will be running on [localhost:4567](localhost:4567) by default. 

### Endpoints

##### /mine

Mines the current transactions and adds them to the blockchain.

##### /transactions/new

Creates a new transaction and adds it to the pending transactions to be mined.

###### Parameters:
- sender - address of the sender
- recipient - address of the recipient
- amount

##### /chain

View the current blockcain.

##### /nodes/register

Registers new nodes with the current node

###### Parameters:
- nodes - array of new nodes to register

##### /nodes/resolve

Validates the current node's blockchain with all registered nodes to obtain the most recent one.

