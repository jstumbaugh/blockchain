require "sinatra"
require "json"
require "securerandom"
require "net/http"
require_relative "blockchain"

blockchain      = Blockchain.new
node_identified = SecureRandom.uuid.gsub(/-/, "")

get "/mine" do
  # Run the Proof of Work algorithm to get next proof
  last_block = blockchain.last_block
  last_proof = last_block[:proof]
  proof      = blockchain.proof_of_work(last_proof)

  # We must recieve an award for finding the proof.
  # The sender is 0 to signify we have mined a coin.
  blockchain.new_transaction(
    sender:    "0",
    recipient: node_identified,
    amount:    1
  )

  # Forge a new block by adding it to the chain
  block = blockchain.new_block(proof)

  response = {
    message:       "New Block Forged",
    index:         block[:index],
    transactions:  block[:transactions],
    proof:         block[:proof],
    previous_hash: block[:previous_hash],
  }

  status 200
  body response.to_json
end

post "/transactions/new" do
  sender    = params["sender"]
  recipient = params["recipient"]
  amount    = params["amount"]

  if sender.nil? || recipient.nil? || amount.nil?
    status 400
    body "Missing Values"
  else
    index = blockchain.new_transaction(
      sender:    sender,
      recipient: recipient,
      amount:    amount
    )

    response = { message: "Transaction will be added in block #{index}" }

    status 201
    body response.to_json
  end
end

get "/chain" do
  {
    chain:  blockchain.chain,
    length: blockchain.chain.length,
  }.to_json
end

post "nodes/register" do
  nodes = params["nodes"]

  if nodes == []
    status 400
    body "Error: Please supply a valid list of nodes"
  end

  nodes.each do |node|
    blockchain.register_node(node)
  end

  response = {
    message:     "New nodes have been added",
    total_nodes: blockchain.nodes,
  }

  status 201
  body response.to_json
end

get "nodes/resolve" do
  replaced = blockchain.resolve_conflicts

  response =
    if replaced
      {
        message: "Our chain was replaced",
        new_chain: blockchain.chain,
      }
    else
      {
        message: "Our chain is authoritative",
        chain: blockchain.chain,
      }
    end

  status 200
  body response.to_json
end

# set port: 4568
