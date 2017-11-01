require "digest"

class Blockchain
  attr_accessor :chain, :current_transactions, :nodes

  def initialize
    @chain                = []
    @current_transactions = []
    @nodes                = []

    # Create the genesis block
    new_block(100, 1)
  end

  # Creates a new block in the Blockchain
  #
  #   proof:         Proof given by the Proof of Work Algorithm
  #   previous_hash: (Optional) hash of the previous block
  #
  #   Returns: a new block
  def new_block(proof, previous_hash = hash(last_block))
    block = {
      index:         chain.length + 1,
      timestamp:     Time.now.to_i,
      transactions:  current_transactions,
      proof:         proof,
      previous_hash: previous_hash,
    }

    # Reset the current transactions
    @current_transactions = []

    # Add block to the chain
    chain << block

    block
  end

  # Creates a new transaction to be added to the next block
  #
  #   sender:    Address of the sender
  #   recipient: Address of the recipient
  #   amount:    Amount
  #
  #   Returns: index of the last block
  def new_transaction(sender:, recipient:, amount:)
    transaction = {
      sender:    sender,
      recipient: recipient,
      amount:    amount
    }

    current_transactions << transaction

    last_block[:index]
  end

  # Simple Proof of Work Algorithm:
  #  - Find a number p' such that hash(pp') contains leading 4 zeroes, where p
  #    is the previous p'
  #  - p is the previous proof, and p' is the new proof
  #
  #   last_proof: integer of last proof
  #
  # Returns: number of proof
  def proof_of_work(last_proof)
    proof = 0
    while valid_proof(last_proof, proof) == false
      proof += 1
    end

    proof
  end

  # Validates the Proof: Does hash(last_proof, proof) contain 4 leading zeroes?
  #
  #   last_proof: Previous Proof
  #   proof:      Current Proof
  #
  # Returns: boolean of correct or not
  def valid_proof(last_proof, proof)
    guess      = "#{last_proof}#{proof}".encode
    guess_hash = Digest::SHA256.hexdigest(guess)

    guess_hash.split(//).first(4).join == "0000"
  end

  # Creates a SHA256 hash of a block
  #
  #   block: a block to be hashed
  #
  # Returns: hash of block
  def hash(block)
    Digest::SHA256.hexdigest(block.to_s.encode)
  end

  def last_block
    chain.last
  end

  # Add nodes to out list of nodes, parses out parameters
  #
  #   address: url of node
  #
  # Returns: nil
  def register_node(address)
    nodes << address.gsub(/\/.*/, "")
  end

  # Determine if a given blockchain is valid
  #
  #   chain: blockchain to test
  #
  # Returns: boolean of whether or not the chain is valid
  def valid_chain(chain)
    last_block = chain[0]
    current_index = 1

    while current_index < chain.length
      block = chain[current_index]
      puts "Last Block: #{last_block}"
      puts "Block: #{block}"
      puts "\n====================\n"

      # Check if the hash of the block is correct
      return false if block[:hash] != hash(last_block)

      # Check that the proof of work is correct
      return false if valid_proof(last_block[:proof], block[:proof])

      last_block = block
      current_index += 1
    end

    # All blocks in the chain are valid
    return true
  end

  # This is our Consensus Algorithm. It resolves conflicts by replacing our
  # chain with the longest one in the network.
  #
  # Returns: true if the chain was replaced, false if not
  def resolve_conflicts
    neighbors = nodes
    new_chain = []

    # We are only looking for chains longer than ours
    max_length = chain.length

    neighbors.each do |node|
      response = Net::HTTP.get(URI.parse("#{node}/chain"))

      if response
        length = JSON.parse(response)["length"]
        chain  = JSON.parse(response)["chain"]

        if length > max_length && valid_chain(chain)
          max_length = length
          new_chain = chain
        end
      end
    end

    if new_chain.any?
      @chain = new_chain
      true
    else
      false
    end
  end
end
