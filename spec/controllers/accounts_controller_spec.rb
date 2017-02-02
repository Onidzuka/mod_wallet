require 'rails_helper'

RSpec.describe AccountsController do
  let(:active_account) { create(:individual) }
  let(:blocked_account) { create(:blocked_account) }
  let(:closed_account) { create(:individual, closed: true) }
  let(:account_with_balance) { create(:agent_with_balance) }

  describe 'WLT001 Создание СЭД' do
    let(:iin)                     { 950740000130 }
    let(:encoded_iin)             { Base58.encode(iin) }

    context 'WLT001-01' do
      it 'Успешное создание аккаунта c физ. лица' do
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

    context 'WLT001-02' do
      it 'Успешное создание аккаунта для агента' do
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

    context 'WLT001-03' do
      it 'Успешное создание аккаунта для поставщика' do
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

    context 'WLT001-04' do
      it 'Успешное создание аккаунта с типом юр. лицо и поставщик' do
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

    context 'WLT001-05' do
      it 'Успешное создание аккаунта для юр. лица и поставщика' do
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

    context 'WLT001-06' do
      it 'Возвращает ошибку когда в параметрах указан неверный тип' do
        post :create, params: { account_type: ['invalid_type'] }

        expect(Account.count).to eql(0)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::InvalidAccountType'
        })
      end
    end

    context 'WLT001-07' do
      it 'Возвращает ошибку когда нет параметров' do
        post :create

        expect(Account.count).to eql(0)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::InvalidRequest'
        })
      end
    end

    context 'WLT001-08' do
      before { post :create, params: { account_id: iin, country_code: 'kz', account_type: ['individual'] } }

      it 'Возращает ошибку когда в параметрах указан повторный ИИН' do
        post :create, params: { account_id: iin, country_code: 'kz', account_type: ['individual'] }

        expect(Account.count).to eql(1)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Validation failed: Identity number has already been taken'
        })
      end
    end

    context 'WLT001-09' do
      it 'Возращает ошибку когда в параметрах пустые значения' do
        post :create, params: { account_id: '', country_code: '', account_type: ['individual'] }

        expect(Account.count).to eql(0)
        expect(response.body).to include_json({
            status: 'error',
            message: "Validation failed: Identity number can't be blank, Country code can't be blank"
        })
      end
    end
  end

  describe 'WLT002 Блокирование аккаунта' do
    context 'WLT002-01' do
      it 'Успешная блокировка аккаута на дебит и кредит' do
        post :block, params: { account_id: active_account.identity_number, operations: ['credit', 'debit'] }

        expect(BlockedOperation.count).to eql(2)
        expect(BlockedOperation.where(account_id: active_account.id, operation: 'credit').exists?).to be true
        expect(BlockedOperation.where(account_id: active_account.id, operation: 'debit').exists?).to be true
        expect(response.body).to include_json({
          status: 'success'
        })
      end
    end

    context 'WLT002-02' do
      it 'Успешная блокировка аккаута на кредит' do
        post :block, params: { account_id: active_account.identity_number, operations: ['credit'] }

        expect(BlockedOperation.count).to eql(1)
        expect(BlockedOperation.where(account_id: active_account.id, operation: 'credit').exists?).to be true
        expect(response.body).to include_json({
          status: 'success'
        })
      end
    end

    context 'WLT002-03' do
      it 'Успешная блокировка аккаута на дебит' do
        post :block, params: { account_id: active_account.identity_number, operations: ['debit'] }

        expect(BlockedOperation.count).to eql(1)
        expect(BlockedOperation.where(account_id: active_account.id, operation: 'debit').exists?).to be true
        expect(response.body).to include_json({
          status: 'success'
        })
      end
    end

    context 'WLT002-04' do
      it 'Возвращает ошибку если в параметрах указан не валидный тип операции' do
        post :block, params: { account_id: active_account.identity_number, operations: ['debit', 'invalid_operation'] }

        expect(BlockedOperation.count).to eql(0)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Validation failed: Operation invalid',
        })
      end
    end

    context 'WLT002-05' do
      it 'Проверяет не заблокирован ли аккунт, если пришла повторная команда' do
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

    context 'WLT002-06' do
      it 'Возвращает ошибку когда в параметрах указан неверный тип' do
        put :block, params: { account_id: blocked_account.identity_number }

        expect(BlockedOperation.count).to eql(2)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::InvalidRequest'
        })
      end
    end

    context 'WLT002-07' do
      it 'Возвращает ошибку когда аккаунт не найден' do
        post :block, params: { account_id: '99999', operations: ['credit', 'debit'] }

        expect(response.body).to include_json({
          status: 'error',
          message: "Couldn't find Account"
        })
      end
    end

    context 'WLT002-08' do
      it 'Возвращает ошибку когда аккаунт закрыт' do
        post :block, params: { account_id: closed_account.identity_number, operations: ['credit', 'debit'] }

        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::AccountClosed'
        })
      end
    end
  end

  describe 'WLT002 Разблокировка аккаунта' do
    context 'WLT002-08' do
      it 'Успешная разблокировка аккаунта на дебит и кредит' do
        put :unblock, params: { account_id: blocked_account.identity_number, operations: ['credit', 'debit'] }

        expect(BlockedOperation.count).to eql(0)
        expect(response.body).to include_json({
          status: 'success'
        })
      end
    end

    context 'WLT002-09' do
      it 'Успешная разблокировка аккаунта на кредит' do
        put :unblock, params: { account_id: blocked_account.identity_number, operations: ['credit'] }

        expect(BlockedOperation.count).to eql(1)
        expect(BlockedOperation.first.operation).to eql('debit')
        expect(response.body).to include_json({
          status: 'success'
        })
      end
    end

    context 'WLT002-10' do
      it 'Успешная разблокировка аккаунта на дебит' do
        put :unblock, params: { account_id: blocked_account.identity_number, operations: ['debit'] }

        expect(BlockedOperation.count).to eql(1)
        expect(BlockedOperation.first.operation).to eql('credit')
        expect(response.body).to include_json({
          status: 'success'
        })
      end
    end

    context 'WLT002-11' do
      it 'Возвращает ошибку когда аккаунт не заблокирован' do
        put :unblock, params: { account_id: active_account.identity_number, operations: ['debit', 'credit'] }

        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::AccountNotBlocked'
        })
      end
    end

    context 'WLT002-12' do
      it 'Возвращает ошибку когда в параметрах ничего не указано' do
        put :unblock, params: { account_id: blocked_account.identity_number }

        expect(BlockedOperation.count).to eql(2)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::InvalidRequest'
        })
      end
    end

    context 'WLT002-13' do
      it 'Возвращает ошибку когда аккаунт не найден' do
        put :unblock, params: { account_id: '99999', operations: ['credit', 'debit'] }

        expect(response.body).to include_json({
          status: 'error',
          message: "Couldn't find Account"
        })
      end
    end

    context 'WLT002-14' do
      it 'Возвращает ошибку когда аккаунт закрыт' do
        put :unblock, params: { account_id: closed_account.identity_number, operations: ['credit', 'debit'] }

        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::AccountClosed'
        })
      end
    end
  end

  describe 'WLT003 Закрытие СЭД' do
    context 'WLT003-01' do
      it 'Успешное закрытие СЭД' do
        put :close, params: { account_id: active_account.identity_number }

        expect(response).to have_http_status(:ok)
        expect(active_account.reload.closed?).to be true
        expect(response.body).to include_json({status: 'success'})
      end
    end

    context 'WLT003-02' do
      it 'Возвращает ошибку когда аккаунт не найден' do
        not_existing_account_id = 777
        put :close, params: { account_id: not_existing_account_id }

        expect(response.body).to include_json({
          status: 'error',
          message: "Couldn't find Account"
        })
      end
    end
  end

  describe 'WLT004 Получение остатка по СЭД' do
    context 'WLT004-01' do
      it 'Успешное получение остатка по СЭД, когда у аккаунта имеется баланс' do
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
    end

    context 'WLT004-02' do
      it 'Успешное получение остатка по СЭД, когда у аккаунта на балансе 0.0' do
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

    context 'WLT004-03' do
      before do
        params1 = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: account_with_balance.identity_number, target_account_id: active_account.identity_number, amount: '200.0'}}
        params2 = {id: '3', folder_id: '3', type: 'transfer', params: {source_account_id: account_with_balance.identity_number, target_account_id: active_account.identity_number, amount: '200.0'}}
        CreateDocument.call(params: params1)
        CreateDocument.call(params: params2)
      end

      it 'Успешное получение остатка по СЭД, когда у аккаунта имеется заблокированная сумма' do
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

    context 'WLT004-04' do
      it 'Возвращает ошибку когда аккаунт зактрыт' do
        get :balance, params: {account_id: closed_account.identity_number}

        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::AccountClosed'
        })
      end
    end

    context 'WLT004-05' do
      it 'Возвращает ошибку когда аккаунт не найден' do
        get :balance, params: {account_id: '55555'}

        expect(response.body).to include_json({
          status: 'error',
          message: "Couldn't find Account"
        })
      end
    end
  end

  describe 'WLT008 Получение истории по СЭД' do
    let(:account1) {create(:account)}
    let(:account2) {create(:account)}

    context 'WLT008-1' do
      before do
        emission_params = {type: 'emission', target: { target_message: 'эмиссия' }}
        withdrawal_params = {type: 'withdrawal', target: { target_message: 'вывод денежных средств' }}
        transfer_params = {
          type: 'transfer',
          target: {
            source_message: 'перевод с вашего кошелька',
            target_message: 'перевод на ваш кошелек'
          }
        }

        create(:document, params: emission_params, target_account_id: account1.id, status: 'created')
        3.times {create(:document, params: transfer_params, document_type: 'transfer', source_account_id: account1.id, target_account_id: account2.id)}
        5.times {create(:document, params: emission_params, target_account_id: account1.id)}
        create(:document, params: withdrawal_params, target_account_id: account1.id, document_type: 'withdrawal')
      end

      it 'Возвращает историю успешных операций по СЭД с лимитом 5' do
        get :history, params: { account_id: account1.identity_number, limit: '5'}

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['status']).to                  eql('success')
        expect(parsed_response['history']).to include_json(
          [
            {
              amount: '-1000.0',
              message: 'вывод денежных средств',
            },
            {
              amount: '1000.0',
              message: 'эмиссия',
            },
            {
              amount: '1000.0',
              message: 'эмиссия',
            },
            {
              amount: '1000.0',
              message: 'эмиссия',
            },
            {
              amount: '1000.0',
              message: 'эмиссия',
            }
          ]
        )
        expect(Document.count).to eql(10)
      end

      it 'Возвращает историю успешных операций по СЭД с лимитом 10' do
        get :history, params: { account_id: account1.identity_number, limit: '10' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['status']).to               eql('success')
        expect(parsed_response['history'].count).to        eql(9)
        expect(parsed_response['history']).to include_json(
          [
            {
              amount: '-1000.0',
              message: 'вывод денежных средств'
            },
            {
              amount: '1000.0',
              message: 'эмиссия'
            },
            {
              amount: '1000.0',
              message: 'эмиссия'
            },
            {
              amount: '1000.0',
              message: 'эмиссия'
            },
            {
              amount: '1000.0',
              message: 'эмиссия'
            },
            {
              amount: '1000.0',
              message: 'эмиссия'
            },
            {
              amount: '-1000.0',
              message: 'перевод с вашего кошелька',
            },
            {
              amount: '-1000.0',
              message: 'перевод с вашего кошелька',
            },
            {
              amount: '-1000.0',
              message: 'перевод с вашего кошелька',
            }
          ]
        )
      end

      it 'Возвращает историю успешных операций по СЭД с лимитом 5' do
        get :history, params: { account_id: account2.identity_number, limit: '5' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['status']).to             eql('success')
        expect(parsed_response['history'].count).to      eql(3)
        expect(parsed_response['history']).to include_json(
          [
            {
              amount: '1000.0',
              message: 'перевод на ваш кошелек',
            },
            {
              amount: '1000.0',
              message: 'перевод на ваш кошелек',
            },
            {
              amount: '1000.0',
              message: 'перевод на ваш кошелек',
            }
          ]
        )
      end
    end

    context 'WLT008-2' do
      before do
        3.times {create(:document, target_account_id: account1.id, created_at: '2016-12-01'.to_datetime, amount: '100.0')}
        3.times {create(:document, target_account_id: account1.id, created_at: '2016-12-03'.to_datetime, amount: '100.0')}
        4.times {create(:document, target_account_id: account1.id, created_at: '2016-12-05'.to_datetime, amount: '100.0')}
      end

      it 'Возвращает историю операций по СЭД когда в параметрах указаны даты начала и конца с лимитом 5' do
        get :history, params: { account_id: account1.identity_number, limit: '5', start_date: '2016-12-01'.to_datetime.beginning_of_day, end_date: '2016-12-03'.to_datetime.end_of_day }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['history'].count).to eql(5)
        expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-03'.to_datetime}.count).to eql(3)
        expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-01'.to_datetime}.count).to eql(2)
      end

      it 'Возвращает историю операций по СЭД когда в параметрах указаны даты начала и конца с лимитом 10' do
        get :history, params: { account_id: account1.identity_number, limit: '10', start_date: '2016-12-01'.to_datetime.beginning_of_day, end_date: '2016-12-05'.to_datetime.end_of_day }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['history'].count).to eql(10)
        expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-01'.to_datetime}.count).to eql(3)
        expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-03'.to_datetime}.count).to eql(3)
        expect(parsed_response['history'].select {|h| h['executed_at'].to_datetime == '2016-12-05'.to_datetime}.count).to eql(4)
      end

      it 'Возвращает пустой массив когда у СЭД не было операций' do
        get :history, params: { account_id: account2.identity_number, limit: '5' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['history'].count).to eql(0)
      end
    end

    context 'WLT008-3' do
      before do
        create(:document, target_account_id: account1.id, created_at: '2015-12-01'.to_datetime, amount: '100.0')
        create(:document, target_account_id: account1.id, created_at: '2016-12-02'.to_datetime, amount: '100.0')
        create(:document, target_account_id: account1.id, created_at: '2016-12-02'.to_datetime, amount: '100.0')
        create(:document, target_account_id: account1.id, created_at: '2016-12-02'.to_datetime, amount: '100.0')
        create(:document, target_account_id: account1.id, created_at: '2016-12-03'.to_datetime, amount: '100.0')
      end

      it 'Возращает даты когда были проведены операции по СЭД за год' do
        get :history_dates, params: { account_id: account1.identity_number, year: '2016' }

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['status']).to eql('success')
        expect(parsed_response['dates']).to match_array(['2016-12-02', '2016-12-03'])
      end

      it 'Возращает даты когда были проведены операции по СЭД за год' do
        get :history_dates, params: { account_id: account1.identity_number, year: '2015' }

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['status']).to eql('success')
        expect(parsed_response['dates']).to match_array(['2015-12-01'])
      end

      it 'Возращает пустой массив когда у СЭД не было операций' do
        get :history_dates, params: { account_id: account1.identity_number, year: '2011' }

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['status']).to eql('success')
        expect(parsed_response['dates'].count).to eql(0)
      end
    end

    context 'WLT008-4' do
      it 'Возвращает пустой массив когда СЭД не имеет истории операций' do
        get :history, params: { account_id: account1.identity_number, page: '1', per_page: '5' }

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['status']).to eql('success')
        expect(parsed_response['history'].count).to eql(0)
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
