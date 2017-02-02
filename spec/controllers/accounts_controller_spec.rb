require 'rails_helper'

RSpec.describe AccountsController do
  let(:active_account) { create(:individual) }
  let(:blocked_account) { create(:blocked_account) }
  let(:closed_account) { create(:individual, closed: true) }
  let(:account_with_balance) { create(:agent_with_balance) }

  describe '#create' do
    let(:iin)                     { 950740000130 }
    let(:encoded_iin)             { Base58.encode(iin) }

    context "when given account type 'individual' in parameters" do
      it 'creates an account with type individual' do
        post :create, params: { account_id: iin, country_code: 'kz', account_type: ['individual'] }
        account = Account.last

        expect(Account.count).to eql(1)
        expect(account.has_role? :individual).to be true
        expect(account.roles.count).to eql(1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json({
          account_id: encoded_iin,
          status: 'success'
        })
      end
    end

    context "when given account type 'agent' in parameters" do
      it 'creates an account with type agent' do
        post :create, params: { account_id: iin, country_code: 'kz', account_type: ['agent'] }
        account = Account.last

        expect(Account.count).to eql(1)
        expect(account.has_role? :agent).to be true
        expect(account.roles.count).to eql(1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json({
          account_id: encoded_iin,
          status: 'success'
        })
      end
    end

    context "when given account type 'merchant' in parameters" do
      it 'creates an account with type merchant' do
        post :create, params: { account_id: iin, country_code: 'kz', account_type: ['merchant'] }
        account = Account.last

        expect(Account.count).to eql(1)
        expect(account.has_role? :merchant).to be true
        expect(account.roles.count).to eql(1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json({
          account_id: encoded_iin,
          status: 'success'
        })
      end
    end

    context "when given account type 'corporate' in parameters" do
      it 'creates an account with type corporate' do
        post :create, params: { account_id: iin, country_code: 'kz', account_type: ['corporate'] }
        account = Account.last

        expect(Account.count).to eql(1)
        expect(account.has_role? :corporate).to be true
        expect(account.roles.count).to eql(1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json({
          account_id: encoded_iin,
          status: 'success'
        })
      end
    end

    context "when given account type 'agent' and 'merchant' in parameters" do
      it 'creates an account with type corporate and agent' do
        post :create, params: { account_id: iin, country_code: 'kz', account_type: ['agent', 'merchant'] }
        account = Account.last

        expect(Account.count).to eql(1)
        expect(account.has_role? :agent).to be true
        expect(account.has_role? :merchant).to be true
        expect(account.roles.count).to eql(2)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json({
          account_id: encoded_iin,
          status: 'success'
        })
      end
    end

    context 'when given wrong parameters' do
      it 'returns an error' do
        post :create, params: { account_type: ['invalid_type'] }

        expect(Account.count).to eql(0)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::InvalidAccountType'
        })
      end
    end

    context 'when given no parameters' do
      it 'returns an error' do
        post :create

        expect(Account.count).to eql(0)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::InvalidRequest'
        })
      end
    end

    context 'when given an identity number that already exists in parameters' do
      before { post :create, params: { account_id: iin, country_code: 'kz', account_type: ['individual'] } }

      it 'returns an error' do
        post :create, params: { account_id: iin, country_code: 'kz', account_type: ['individual'] }

        expect(Account.count).to eql(1)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Validation failed: Identity number has already been taken'
        })
      end
    end

    context 'when given empty values in parameters' do
      it 'returns an error' do
        post :create, params: { account_id: '', country_code: '', account_type: ['individual'] }

        expect(Account.count).to eql(0)
        expect(response.body).to include_json({
            status: 'error',
            message: "Validation failed: Identity number can't be blank, Country code can't be blank"
        })
      end
    end
  end

  describe '#block' do
    context 'blocking account command' do
      context 'when given a command to block both for credit and debit' do
        it ' blocks a target account both for credit and debit' do
          post :block, params: { account_id: active_account.identity_number, operations: ['credit', 'debit'] }

          expect(BlockedOperation.count).to eql(2)
          expect(BlockedOperation.where(account_id: active_account.id, operation: 'credit').exists?).to be true
          expect(BlockedOperation.where(account_id: active_account.id, operation: 'debit').exists?).to be true
          expect(response.body).to include_json({
            status: 'success'
          })
        end
      end

      context 'when given a command to block for credit only' do
        it ' blocks for a target account for credit' do
          post :block, params: { account_id: active_account.identity_number, operations: ['credit'] }

          expect(BlockedOperation.count).to eql(1)
          expect(BlockedOperation.where(account_id: active_account.id, operation: 'credit').exists?).to be true
          expect(response.body).to include_json({
            status: 'success'
          })
        end
      end

      context 'when given a command to block for debit only' do
        it ' blocks for a target account for debit' do
          post :block, params: { account_id: active_account.identity_number, operations: ['debit'] }

          expect(BlockedOperation.count).to eql(1)
          expect(BlockedOperation.where(account_id: active_account.id, operation: 'debit').exists?).to be true
          expect(response.body).to include_json({
            status: 'success'
          })
        end
      end

      context 'when given invalid parameters' do
        it 'returns an error' do
          post :block, params: { account_id: active_account.identity_number, operations: ['debit', 'invalid_operation'] }

          expect(BlockedOperation.count).to eql(0)
          expect(response.body).to include_json({
            status: 'error',
            message: 'Validation failed: Operation invalid',
          })
        end
      end

      context 'when commands come multiple times' do
        it 'checks if a target account is blocked' do
          2.times do
            post :block, params: { account_id: active_account.identity_number, operations: ['credit', 'debit'] }
          end

          expect(BlockedOperation.count).to eql(2)
          expect(BlockedOperation.where(account_id: active_account.id.to_s, operation: 'credit').exists?).to be true
          expect(BlockedOperation.where(account_id: active_account.id.to_s, operation: 'debit').exists?).to be true
          expect(response.body).to include_json({
            status: 'success'
          })
        end
      end

      context 'when given invalid command' do
        it 'returns an error' do
          put :block, params: { account_id: blocked_account.identity_number }

          expect(BlockedOperation.count).to eql(2)
          expect(response.body).to include_json({
            status: 'error',
            message: 'Exceptions::InvalidRequest'
          })
        end
      end

      context 'when account is not found' do
        it 'returns an error and exceptions message' do
          post :block, params: { account_id: '99999', operations: ['credit', 'debit'] }

          expect(response.body).to include_json({
            status: 'error',
            message: "Couldn't find Account"
          })
        end
      end

      context 'when account is closed' do
        it 'returns an error' do
          post :block, params: { account_id: closed_account.identity_number, operations: ['credit', 'debit'] }

          expect(response.body).to include_json({
            status: 'error',
            message: 'Exceptions::AccountClosed'
          })
        end
      end

    end
  end

  describe '#unblock' do
    context 'unblocking account command' do
      context 'when given a command to unblock both for credit and debit' do
        it ' unblocks a target account both for credit and debit' do
          put :unblock, params: { account_id: blocked_account.identity_number, operations: ['credit', 'debit'] }

          expect(BlockedOperation.count).to eql(0)
          expect(response.body).to include_json({
            status: 'success'
          })
        end
      end

      context 'when given a command to unblock for credit' do
        it ' unblocks a target account for credit' do
          put :unblock, params: { account_id: blocked_account.identity_number, operations: ['credit'] }

          expect(BlockedOperation.count).to eql(1)
          expect(BlockedOperation.first.operation).to eql('debit')
          expect(response.body).to include_json({
            status: 'success'
          })
        end
      end

      context 'when given a command to unblock for debit' do
        it ' unblocks a target account for debit' do
          put :unblock, params: { account_id: blocked_account.identity_number, operations: ['debit'] }

          expect(BlockedOperation.count).to eql(1)
          expect(BlockedOperation.first.operation).to eql('credit')
          expect(response.body).to include_json({
            status: 'success'
          })
        end
      end

      context 'when a target account is not blocked' do
        it 'returns an error' do
          put :unblock, params: { account_id: active_account.identity_number, operations: ['debit', 'credit'] }

          expect(response.body).to include_json({
            status: 'error',
            message: 'Exceptions::AccountNotBlocked'
          })
        end
      end

      context 'when given no parameters' do
        it 'returns an error' do
          put :unblock, params: { account_id: blocked_account.identity_number }

          expect(BlockedOperation.count).to eql(2)
          expect(response.body).to include_json({
            status: 'error',
            message: 'Exceptions::InvalidRequest'
          })
        end
      end

      context 'when account not found' do
        it 'returns an error' do
          put :unblock, params: { account_id: '99999', operations: ['credit', 'debit'] }

          expect(response.body).to include_json({
            status: 'error',
            message: "Couldn't find Account"
          })
        end
      end

      context 'when account closed' do
        it 'returns an error' do
          put :unblock, params: { account_id: closed_account.identity_number, operations: ['credit', 'debit'] }

          expect(response.body).to include_json({
            status: 'error',
            message: 'Exceptions::AccountClosed'
          })
        end
      end
    end
  end

  describe '#close' do
    context 'closing account command' do
      context 'when given a command to close' do
        it 'it  closes a target account' do
          put :close, params: { account_id: active_account.identity_number }

          expect(response).to have_http_status(:ok)
          expect(active_account.reload.closed?).to be true
          expect(response.body).to include_json({status: 'success'})
        end
      end

      context 'when account not found' do
        it 'returns an error' do
          not_existing_account_id = 777
          put :close, params: { account_id: not_existing_account_id }

          expect(response.body).to include_json({
            status: 'error',
            message: "Couldn't find Account"
          })
        end
      end
    end
  end

  describe '#balance' do
    context 'account balance request' do
      it " returns a target account's balance" do
        get :balance, params: {account_id: account_with_balance.identity_number}

        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json({
          status: 'success',
          balance: {
            held_balance_amount: '0.0',
            available_balance_amount: '500000.0'
          }
        })
      end

      context "when target account's current balance is 0.0" do
        it ' returns current balance' do
          get :balance, params: {account_id: active_account.identity_number}

          expect(response).to have_http_status(:ok)
          expect(response.body).to include_json({
            status: 'success',
            balance: {
              held_balance_amount: '0.0',
              available_balance_amount: '0.0'
            }
          })
        end
      end

      context 'when account has some blocked amount' do
        before do
          params1 = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: account_with_balance.identity_number, target_account_id: active_account.identity_number, amount: '200.0'}}
          params2 = {id: '3', folder_id: '3', type: 'transfer', params: {source_account_id: account_with_balance.identity_number, target_account_id: active_account.identity_number, amount: '200.0'}}
          CreateDocument.call(params: params1)
          CreateDocument.call(params: params2)
        end

        it ' returns available and held balance amount' do
          get :balance, params: {account_id: account_with_balance.identity_number}

          expect(response).to have_http_status(:ok)
          expect(response.body).to include_json({
            status: 'success',
            balance: {
              held_balance_amount: '400.0',
              available_balance_amount: '499600.0'
            }
          })
        end
      end

      context 'when account closed' do
        it 'returns an error' do
          get :balance, params: {account_id: closed_account.identity_number}

          expect(response.body).to include_json({
            status: 'error',
            message: 'Exceptions::AccountClosed'
          })
        end
      end

      context 'when account not found' do
        it 'returns an error' do
          get :balance, params: {account_id: '55555'}

          expect(response.body).to include_json({
            status: 'error',
            message: "Couldn't find Account"
          })
        end
      end
    end
  end

  describe '#history' do
    let(:account1) {create(:account)}
    let(:account2) {create(:account)}

    context 'account history request' do
      context 'when given limit 5' do
        before do
          emission_params = {type: 'emission', target: { target_message: 'emission' }}
          withdrawal_params = {type: 'withdrawal', target: { target_message: 'withdrawal' }}
          transfer_params = {
            type: 'transfer',
            target: {
              source_message: 'transfer from your wallet',
              target_message: 'transfer to your wallet'
            }
          }

          create(:document, params: emission_params, target_account_id: account1.id, status: 'created')
          3.times {create(:document, params: transfer_params, document_type: 'transfer', source_account_id: account1.id, target_account_id: account2.id)}
          5.times {create(:document, params: emission_params, target_account_id: account1.id)}
          create(:document, params: withdrawal_params, target_account_id: account1.id, document_type: 'withdrawal')
        end

        context 'when limit is 5' do
          it 'it returns account history with limit 5' do
            get :history, params: { account_id: account1.identity_number, limit: '5'}

            parsed_response = JSON.parse(response.body)
            expect(parsed_response['status']).to eql('success')
            expect(parsed_response['history']).to include_json(
              [
                {
                  amount: '-1000.0',
                  message: 'withdrawal',
                },
                {
                  amount: '1000.0',
                  message: 'emission',
                },
                {
                  amount: '1000.0',
                  message: 'emission',
                },
                {
                  amount: '1000.0',
                  message: 'emission',
                },
                {
                  amount: '1000.0',
                  message: 'emission',
                }
              ]
            )
            expect(Document.count).to eql(10)
          end
        end

        context 'when limit is 10' do
          it 'it returns account history with limit 10' do
            get :history, params: { account_id: account1.identity_number, limit: '10' }

            parsed_response = JSON.parse(response.body)
            expect(parsed_response['status']).to               eql('success')
            expect(parsed_response['history'].count).to        eql(9)
            expect(parsed_response['history']).to include_json(
              [
                {
                  amount: '-1000.0',
                  message: 'withdrawal'
                },
                {
                  amount: '1000.0',
                  message: 'emission'
                },
                {
                  amount: '1000.0',
                  message: 'emission'
                },
                {
                  amount: '1000.0',
                  message: 'emission'
                },
                {
                  amount: '1000.0',
                  message: 'emission'
                },
                {
                  amount: '1000.0',
                  message: 'emission'
                },
                {
                  amount: '-1000.0',
                  message: 'transfer from your wallet',
                },
                {
                  amount: '-1000.0',
                  message: 'transfer from your wallet',
                },
                {
                  amount: '-1000.0',
                  message: 'transfer from your wallet',
                }
              ]
            )
          end
        end

        context "another account's history with limit 5" do
          it "returns another account's history with limit 5" do
            get :history, params: { account_id: account2.identity_number, limit: '5' }

            parsed_response = JSON.parse(response.body)
            expect(parsed_response['status']).to             eql('success')
            expect(parsed_response['history'].count).to      eql(3)
            expect(parsed_response['history']).to include_json(
              [
                {
                  amount: '1000.0',
                  message: 'transfer to your wallet',
                },
                {
                  amount: '1000.0',
                  message: 'transfer to your wallet',
                },
                {
                  amount: '1000.0',
                  message: 'transfer to your wallet',
                }
              ]
            )
          end
        end

        context 'WLT008-5' do
          it 'Возвращает ошибку когда СЭД не найден' do
            get :history, params: { account_id: 99999, page: '1', per_page: '5' }

            expect(response.body).to include_json({
              status: 'error',
              message: "Couldn't find Account"
            })
          end
        end

        context 'WLT008-6' do
          it 'Возвращает ошибку когда СЭД закрыт' do
            get :history, params: { account_id: closed_account.identity_number, page: '1', per_page: '5' }

            expect(response.body).to include_json({
              status: 'error',
              message: 'Exceptions::AccountClosed'
            })
          end
        end
      end
    end

    context 'account history request when given a period in parameters' do
      before do
        3.times {create(:document, target_account_id: account1.id, created_at: '2016-12-01'.to_datetime, amount: '100.0')}
        3.times {create(:document, target_account_id: account1.id, created_at: '2016-12-03'.to_datetime, amount: '100.0')}
        4.times {create(:document, target_account_id: account1.id, created_at: '2016-12-05'.to_datetime, amount: '100.0')}
      end

      context 'when given period with start_date and end_date with limit 5' do
        it 'returns account history with given period and limit' do
          get :history, params: { account_id: account1.identity_number, limit: '5', start_date: '2016-12-01'.to_datetime.beginning_of_day, end_date: '2016-12-03'.to_datetime.end_of_day }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['history'].count).to eql(5)
          expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-03'.to_datetime}.count).to eql(3)
          expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-01'.to_datetime}.count).to eql(2)
        end
      end

      context 'when given period with start_date and end_date with limit 10' do
        it 'returns account history with given period and limit' do
          get :history, params: { account_id: account1.identity_number, limit: '10', start_date: '2016-12-01'.to_datetime.beginning_of_day, end_date: '2016-12-05'.to_datetime.end_of_day }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['history'].count).to eql(10)
          expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-01'.to_datetime}.count).to eql(3)
          expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-03'.to_datetime}.count).to eql(3)
          expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-05'.to_datetime}.count).to eql(4)
        end
      end

      context 'when account has no history' do
        it 'returns an empty array' do
          get :history, params: { account_id: account2.identity_number, limit: '5' }

          parsed_response = JSON.parse(response.body)
          expect(parsed_response['history'].count).to eql(0)
        end
      end
    end

  end

  describe '#history_dates' do
    context 'account history dates request' do
      before do
        create(:document, target_account_id: account1.id, created_at: '2015-12-01'.to_datetime, amount: '100.0')
        create(:document, target_account_id: account1.id, created_at: '2016-12-02'.to_datetime, amount: '100.0')
        create(:document, target_account_id: account1.id, created_at: '2016-12-02'.to_datetime, amount: '100.0')
        create(:document, target_account_id: account1.id, created_at: '2016-12-02'.to_datetime, amount: '100.0')
        create(:document, target_account_id: account1.id, created_at: '2016-12-03'.to_datetime, amount: '100.0')
      end

      context 'when account operations exist' do
        it 'returns an array of dates for a given year' do
          get :history_dates, params: { account_id: account1.identity_number, year: '2016' }

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['status']).to eql('success')
          expect(parsed_response['dates']).to match_array(['2016-12-02', '2016-12-03'])
        end
      end

      context 'when account operations exist' do
        it 'returns an array of dates for a given year' do
          get :history_dates, params: { account_id: account1.identity_number, year: '2015' }

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['status']).to eql('success')
          expect(parsed_response['dates']).to match_array(['2015-12-01'])
        end
      end

      context 'when no operations' do
        it 'returns an empty array' do
          get :history_dates, params: { account_id: account1.identity_number, year: '2011' }

          parsed_response = JSON.parse(response.body)

          expect(parsed_response['status']).to eql('success')
          expect(parsed_response['dates'].count).to eql(0)
        end
      end
    end
  end
end
