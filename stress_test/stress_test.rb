# Instructions
# 1. rake db:migrate:reset db:seed          # before running the test, clear the database
# 2. puma -t 8:32 -w 4 -p 3000              # run puma web server in a clustered mode
# 3. ruby stress_test/stress_test.rb        # run test

require_relative 'mod-wallet'
require 'parallel'

class Application
  attr_accessor :accounts, :wallet

  def initialize
    self.accounts = []
    self.wallet   = ModWallet.new
  end

  def run
    agent_id = wallet.create_account(123456789, 'agent')
    wallet.create_emission_document(123456789, agent_id, 10000.0)
    wallet.execute_document(123456789)

    10.times do |index|
      account_id = ('84102030033' + index.to_s).to_i
      individual_id = wallet.create_account(account_id, 'individual')
      accounts.push(individual_id)
    end

    document_id = 10

    accounts.each do |account_id|
      document_id += 1
      wallet.create_transfer_document(document_id, agent_id, account_id, 1000.0)
      wallet.execute_document(document_id)
    end

    puts 'Accounts balances'
    puts accounts_balances.inspect
    puts "total #{total_money}"
    puts "----------------------------------------------------"

    source_account = accounts.first
    document_id = 30

    Parallel.map(1..500, in_processes: 4, progress: 'In progress..') do
      document_id += 1
      target_account = (accounts - [source_account]).sample

      wallet.create_transfer_document(document_id, source_account, target_account, 10.0)
      wallet.execute_document(document_id)
      source_account = target_account
    end

    puts 'Accounts balances'
    puts accounts_balances.inspect
    puts "total #{total_money}"
  end

  def accounts_balances
    self.accounts.map do |account|
      [account, wallet.get_balance(account)]
    end
  end

  def total_money
    total = 0
    accounts_balances.each {|balance | total += balance[1] }
    total
  end
end

Application.new.run
