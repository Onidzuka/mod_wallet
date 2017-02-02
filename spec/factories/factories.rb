FactoryGirl.define do
  factory :account do
    identity_number { Account.generate_base58 }
    country_code 'kz'

    factory :blocked_account do
      after(:create) do |account|
        create(:blocked_to_debit,  account: account)
        create(:blocked_to_credit, account: account)
      end
    end

    factory :agent do
      after(:create) {|account| account.add_role(:agent)}
    end

    factory :agent_with_balance do
      after(:create) do |account|
        folder = Folder.create!(folder_id: 1)
        account.add_role(:agent)
        params = {id: '1', type: 'emission', params: {target_account_id: account.id, amount: '500000' }}

        account.target_documents.new(
            params: params,
            status: 'executed',
            document_type: 'emission',
            document_number: 1,
            amount: 500000,
            folder_id: folder.id
        ).save!

        account.balances.new(
            amount: 500000,
            account_id: account.id,
            document_id: account.target_documents.first.id
        ).save!

        CorrespondentAccount.create(amount: -500000)
      end
    end

    factory :corporate do
      after(:create) {|account| account.add_role(:corporate)}
    end

    factory :individual do
      after(:create) {|account| account.add_role(:individual)}
    end

    factory :merchant do
      after(:create) {|account| account.add_role(:merchant)}
    end

    factory :merchant_and_agent do
      after(:create) do |account|
        account.add_role(:merchant)
        account.add_role(:agent)
      end
    end
  end

  factory :blocked_to_credit, class: BlockedOperation do
    operation 'credit'
  end

  factory :blocked_to_debit, class: BlockedOperation do
    operation 'debit'
  end

  factory :folder do
    sequence :folder_id
  end

  factory :document do
    params "{id: '1', type: 'emission', params: {target_account_id: '1', amount: '1000.0' }}"
    status 'executed'
    document_type 'emission'
    amount 1000.0
    association :folder
    sequence :document_number
  end
end
