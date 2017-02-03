require 'httparty'
require 'pry-byebug'

class ModWallet
  include HTTParty

  base_uri '127.0.0.1:3000'

  def create_account(account_id, account_type)
    response = self.class.post('/accounts', { query: {account_id: account_id, account_type: [account_type], country_code: 'kz'} })
    response['account_id']
  end

  def create_emission_document(id, folder_id, target_account_id, amount)
    self.class.post('/documents', {
      query: {
        id: id.to_s,
        folder_id: folder_id,
        type: 'emission',
        target: {target_message: { ru: 'text', en: 'text' }},
        params: {
          target_account_id: target_account_id.to_s,
          amount: amount.to_s
        }
      }
    })
  end

  def create_transfer_document(id, folder_id, source_account_id, target_account_id, amount)
    self.class.post('/documents', {
      query: {
        id: id.to_s,
        folder_id: folder_id,
        type: 'transfer',
        target: {target_message: { ru: 'text', en: 'text' }},
        params: {
          source_account_id: source_account_id.to_s,
          target_account_id: target_account_id.to_s,
          amount: amount.to_s
        }
      }
    })
  end

  def execute_document(document_id)
    self.class.put("/documents/#{document_id}/execute")
  end

  def get_balance(account_id)
    response = self.class.get("/accounts/#{account_id}/balance")
    response['balance']['current_balance_amount'].to_f
  end
end
