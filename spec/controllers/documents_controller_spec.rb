require 'rails_helper'

RSpec.describe DocumentsController do
  let(:agent)               { create(:agent) }
  let(:agent_with_balance)  { create(:agent_with_balance) }
  let(:merchant)            { create(:merchant) }
  let(:closed_agent)        { create(:agent, closed: true) }
  let(:closed_individual)   { create(:individual, closed: true) }
  let(:blocked_account)     { create(:blocked_account) }
  let(:individual1)         { create(:individual) }
  let(:individual2)         { create(:individual) }

  describe 'WLT005 Создание документа для эмиссии' do
    context 'WLT005-01' do
      it 'Успешное создание докумета для типа "Эмиссия"' do
        params = {id: '1', folder_id: '1', type: 'emission', target: {target_message: { ru: 'text', en: 'text' }}, params: {target_account_id: agent.identity_number, amount: '100.99'}}

        post :create, params: params
        document = Document.last

        expect(Folder.count).to                   eql(1)
        expect(Document.count).to                 eql(1)
        expect(document.status).to                eql('created')
        expect(document.amount.to_f).to           eql(100.99)
        expect(document.document_type).to         eql('emission')
        expect(document.document_number).to       eql(1)
        expect(document.target_account_id).to     eql(agent.id)
        expect(response.body).to include_json({
          status: 'success'
        })
        expect(document.params).to eql(JSON.parse(params.to_json))
      end
    end

    context 'WLT005-02' do
      it 'Возвращает ошибку когда тип документа не валидный' do
        params = {id: '1', folder_id: '1', type: 'invalid_type', params: {target_account_id: agent.identity_number, amount: '100.0'}}

        post :create, params: params

        expect(Document.count).to eql(0)
        expect(response.body).to include_json({
          status: 'error',
          message: 'Exceptions::InvalidDocumentType'
        })
      end
    end

    context 'WLT005-03' do
      it 'Возвращает ошибку когда в документе сумма не валидная' do
        params = {id: '1', folder_id: '1', type: 'emission', params: {target_account_id: agent.identity_number, amount: '-1'}}

        post :create, params: params

        expect(Folder.count).to          eql(1)
        expect(Document.count).to        eql(1)
        expect(Document.first.status).to eql('invalid')
        expect(response.body).to include_json({
          status:  'error',
          message: {code: 'Exceptions::InvalidDocument', errors: 'Amount must be greater than 0'}
        })
      end
    end

    context 'WLT005-04' do
      it 'Возвращает ошибку когда ИД документа на валидный' do
        params = {id: 'invalid_id', folder_id: '1', type: 'emission', params: {target_account_id: agent.identity_number, amount: '1000.0'}}

        post :create, params: params

        expect(Folder.count).to   eql(1)
        expect(Document.count).to eql(1)
        expect(response.body).to include_json({
          status: 'error',
          message: {code: 'Exceptions::InvalidDocument', errors: 'Document number is not a number'}
        })
      end
    end

    context 'WLT005-05' do
      it 'Возвращает ошибку когда ИД документа на валидный' do
        params = {id: '0', folder_id: '1', type: 'emission', params: {target_account_id: agent.identity_number, amount: '1000.0'}}

        post :create, params: params

        expect(Folder.count).to   eql(1)
        expect(Document.count).to eql(1)
        expect(response.body).to include_json({
          status: 'error',
          message: {code: 'Exceptions::InvalidDocument', errors: 'Document number must be greater than 0'}
        })
      end
    end

    context 'WLT005-06' do
      it 'Возвращает ошибку когда аккаунт для эмиссии не найден' do
        params = {id: '1', folder_id: '1', type: 'emission', params: {target_account_id: '99999', amount: '100.0'}}

        post :create, params: params

        expect(Folder.count).to                 eql(1)
        expect(Document.count).to               eql(1)
        expect(Document.first.document_type).to eql('emission')
        expect(Document.first.status).to        eql('invalid')
        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountNotFound'}})
      end
    end

    context 'WLT005-07' do
      it 'Возвращает ошибку когда аккаунт для эмиссии закрыт' do
        params = {id: '1', folder_id: '1', type: 'emission', params: {target_account_id: closed_agent.identity_number, amount: '100.0'}}

        post :create, params: params

        expect(Folder.count).to                 eql(1)
        expect(Document.count).to               eql(1)
        expect(Document.first.document_type).to eql('emission')
        expect(Document.first.status).to        eql('invalid')
        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountClosed'}})
      end
    end

    context 'WLT005-08' do
      it 'Возвращает ошибку когда аккаунт для эмисии заблокирован' do
        params = {id: '1', folder_id: '1', type: 'emission', params: {target_account_id: blocked_account.identity_number, amount: '1000.0'}}

        post :create, params: params

        expect(Folder.count).to                 eql(1)
        expect(Document.count).to               eql(1)
        expect(Document.first.document_type).to eql('emission')
        expect(Document.first.status).to        eql('invalid')
        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountBlocked'}})
      end
    end

    context 'WLT005-09' do
      it 'Возвращает ошибку когда аккаунт для эмисии не является агентом' do
        params = {id: '1', folder_id: '1', type: 'emission', params: {target_account_id: individual1.identity_number, amount: '1000.0'}}

        post :create, params: params

        expect(Folder.count).to                 eql(1)
        expect(Document.count).to               eql(1)
        expect(Document.first.document_type).to eql('emission')
        expect(Document.first.status).to        eql('invalid')
        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountTypeIsNotAgent'}})
      end
    end
  end

  describe 'WLT005 Создание документа для перевода' do
    context 'WLT005-10' do
      let(:transfer_document) do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '500.0'}}
        create_document(params)
      end

      before { put :execute, params: { id: transfer_document.document_number } }

      it 'Успешное создание докумета для перевода между физ. лицами' do
        params = {
          id: '3', folder_id: '3', type: 'transfer',
          params: {amount: '400.0', source_account_id: individual1.identity_number, target_account_id: individual2.identity_number},
          target: {source_message: { en: 'text', ru: 'text' }, target_message: { en: 'text', ru: 'text' }}
        }

        post :create, params: params

        document = Document.last
        expect(response.body).to include_json({status: 'success'})
        expect(individual1.current_balance_amount).to    eql(500.0)
        expect(individual1.available_balance_amount).to  eql(100.0)
        expect(Folder.count).to                          eql(3)
        expect(Document.count).to                        eql(3)
        expect(document.document_type).to                eql('transfer')
        expect(document.status).to                       eql('created')
        expect(document.params).to                       eql(JSON.parse(params.to_json))
      end
    end

    context 'WLT005-11' do
      it 'Успешное создание докумета для перевода со СЭД агента на СЭД физ. лица' do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual2.identity_number, amount: '1000.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'success'})
        expect(Folder.count).to                        eql(2)
        expect(Document.count).to                      eql(2)
        expect(Document.last.status).to                eql('created')
        expect(Document.last.document_type).to         eql('transfer')
      end
    end

    context 'WLT005-12' do
      let(:transfer_document) do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '500.0'}}
        create_document(params)
      end

      before { put :execute, params: { id: transfer_document.document_number } }

      it 'Успешное создание докумета для перевода со СЭД физ. лица на СЭД поставщика' do
        params = {id: '3', folder_id: '3', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: merchant.identity_number, amount: '400.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'success'})
        expect(individual1.current_balance_amount).to    eql(500.0)
        expect(individual1.available_balance_amount).to  eql(100.0)
        expect(Folder.count).to                          eql(3)
        expect(Document.count).to                        eql(3)
        expect(Document.last.status).to                  eql('created')
        expect(Document.last.document_type).to           eql('transfer')
      end
    end

    context 'WLT005-13' do
      let(:transfer_document) do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '500.0'}}
        create_document(params)
      end

      before do
        put :execute, params: { id: transfer_document.document_number.to_s }
      end

      it 'Возвращает ошибку при создании документа для запрещенного перевода' do
        params = {id: '3', folder_id: '3', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: agent_with_balance.identity_number, amount: '400.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::ForbiddenTransfer'}})
        expect(Folder.count).to                        eql(3)
        expect(Document.count).to                      eql(3)
        expect(Document.last.status).to                eql('invalid')
        expect(Document.last.document_type).to         eql('transfer')
      end
    end

    context 'WLT005-14' do
      it 'Возвращает ошибку когда аккаунт инициирующий перевод не найден' do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: '99999', target_account_id: individual2.identity_number, amount: '100.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::SourceAccountNotFound'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to   eql(1)
      end
    end

    context 'WLT005-15' do
      it 'Возвращает ошибку когда аккаунт на который переводятся деньги не найден' do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: '99999', amount: '100.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::TargetAccountNotFound'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to   eql(1)
      end
    end

    context 'WLT005-16' do
      it 'Возвращает ошибку когда аккаунт инициирующий перевод заблокирован' do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: blocked_account.identity_number, target_account_id: individual2.identity_number, amount: '100.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::SourceAccountBlocked'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to   eql(1)
      end
    end

    context 'WLT005-17' do
      it 'Возвращает ошибку когда аккаунт на который переводятся деньги заблокирован' do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: blocked_account.identity_number, amount: '100.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::TargetAccountBlocked'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to   eql(1)
      end
    end

    context 'WLT005-18' do
      it 'Возвращает ошибку когда аккаунт инициирующий перевод закрыт' do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: closed_individual.identity_number, target_account_id: individual2.identity_number, amount: '100.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::SourceAccountClosed'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to   eql(1)
      end
    end

    context 'WLT005-19' do
      it 'Возвращает ошибку когда аккаунт на который переводятся деньги закрыт' do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: closed_individual.identity_number, amount: '100.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::TargetAccountClosed'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to   eql(1)
      end
    end

    context 'WLT005-20' do
      it 'Возращает ошибку при переводе самому себе' do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: individual1.identity_number, amount: '100.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::SelfSelectionTransfer'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to   eql(1)
      end
    end

    context 'WLT005-21' do
      it 'Возращает ошибку когда у аккаунта недостаточно денежных средств' do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: individual2.identity_number, amount: '100.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::InsufficientBalance'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to   eql(1)
      end
    end

    context 'WLT005-22' do
      let(:transfer_document) do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '300000.0'}}
        create_document(params)
      end

      before { put :execute, params: { id: transfer_document.document_number } }

      it 'Возвращает ошибку когда превышен лимит для перевода межды физ. лицами' do
        params = {id: '3', folder_id: '3', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: individual2.identity_number, amount: '300000'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::TransferLimitExceeded'}})
        expect(individual1.available_balance_amount).to eql(300000.0)
        expect(individual2.available_balance_amount).to eql(0.0)
        expect(Document.count).to eql(3)
        expect(Folder.count).to eql(3)
        expect(Document.last.status).to eql('invalid')
        expect(Document.last.document_type).to eql('transfer')
        expect(Document.last.reason).to eql('Exceptions::TransferLimitExceeded')
      end
    end

    context 'WLT005-23' do
      let(:transfer_document) do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '100000.0'}}
        create_document(params)
      end

      before { put :execute, params: { id: transfer_document.document_number } }

      it 'Допустим у отправителя всего 100.000 денег. Если создать три документа для перевода по 40.000, тогда два документа создадуться, а третий не создасться по причине не хватки денежных средств' do
        params1 = {id: '3', folder_id: '3', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: individual2.identity_number, amount: '40000'}}
        params2 = {id: '4', folder_id: '4', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: individual2.identity_number, amount: '40000'}}
        params3 = {id: '5', folder_id: '5', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: individual2.identity_number, amount: '40000'}}

        post :create, params: params1
        post :create, params: params2
        post :create, params: params3

        expect(individual1.available_balance_amount).to eql(20000.0)
        expect(individual1.held_balance_amount).to      eql(80000.0)
        expect(Folder.count).to                  eql(5)
        expect(Document.count).to                eql(5)
        expect(Document.third.status).to         eql('created')
        expect(Document.fourth.status).to        eql('created')
        expect(Document.fifth.status).to         eql('invalid')
        expect(Document.fifth.reason).to         eql('Exceptions::InsufficientBalance')
      end
    end
  end

  context 'WLT005 Создание документа вывода денежных средств' do
    context 'WLT005-21' do
      it 'Успешное создание документа для типа "Вывод денежных средтв"' do
        params = {
          id: '2',
          folder_id: '2',
          type: 'withdrawal',
          params: {
            amount: '400.0',
            source_account_id: individual1.identity_number,
            target_account_id: agent_with_balance.identity_number
          },
          target: {
            source_message: { en: 'text', ru: 'text' },
            target_message: { en: 'text', ru: 'text' }
          }
        }

        expected_hash = params.tap do |p|
          p[:params].delete(:source_account_id)
          p[:target].delete(:source_message)
        end

        post :create, params: params

        document = Document.last
        expect(response.body).to include_json({status: 'success'})
        expect(Document.count).to                              eql(2)
        expect(Folder.count).to                                eql(2)
        expect(document.status).to                             eql('created')
        expect(document.document_type).to                      eql('withdrawal')
        expect(agent_with_balance.available_balance_amount).to eql(499600.0)
        expect(agent_with_balance.held_balance_amount).to      eql(400.0)
        expect(document.params).to                             eql(JSON.parse(expected_hash.to_json))
      end
    end

    context 'WLT005-22' do
      it 'Возвращает ошибку когда СЭД не найден' do
        params = {id: '1', folder_id: '1', type: 'withdrawal', params: {target_account_id: '99999', amount: '500'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountNotFound'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to eql(1)
      end
    end

    context 'WLT005-23' do
      it 'Возвращает ошибку когда СЭД закрыт' do
        params = {id: '1', folder_id: '1', type: 'withdrawal', params: {target_account_id: closed_agent.identity_number, amount: '500'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountClosed'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to eql(1)
      end
    end

    context 'WLT005-24' do
      it 'Возвращает ошибку когда СЭД заблокирован' do
        params = {id: '1', folder_id: '1', type: 'withdrawal', params: {target_account_id: blocked_account.identity_number, amount: '500'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountBlocked'}})
        expect(Document.count).to eql(1)
        expect(Folder.count).to eql(1)
      end
    end

    context 'WLT005-25' do
      it 'Возвращает ошибку когда у СЭД не иммется достаточно денеждных средств' do
        params = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '600000'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::InsufficientBalance'}})
        expect(Document.count).to eql(2)
        expect(Folder.count).to eql(2)
      end
    end

    context 'WLT005-26' do
      it 'Возвращает ошибку когда указана не валидная сумма' do
        params = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '-2000'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::InvalidDocument'}})
        expect(Document.count).to eql(2)
        expect(Folder.count).to eql(2)
      end
    end

    context 'WLT005-27' do
      it 'Возвращает ошибку когда указана не валидная сумма' do
        params = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '0.0'}}
        post :create, params: params

        expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::InvalidDocument'}})
        expect(Document.count).to eql(2)
        expect(Folder.count).to eql(2)
      end
    end
  end

  describe 'WLT006 Исполнение документа' do
    before do
      CorrespondentAccount.create!(amount: 0.0) if CorrespondentAccount.all.empty?
    end

    context 'WLT006-01' do
      let(:emission_document) do
        params = {id: '1', folder_id: '2', type: 'emission', params: {target_account_id: agent.identity_number, amount: '10000.99'}}
        create_document(params)
      end

      it 'Успешное исполнение документа для эмиссии' do
        put :execute, params: { id: emission_document.document_number.to_s }

        expect(Folder.count).to                        eql(1)
        expect(Document.count).to                      eql(1)
        expect(Document.first.status).to               eql('executed')
        expect(agent.current_balance_amount).to        eql(10000.99)
        expect(agent.available_balance_amount).to      eql(10000.99)
        expect(CorrespondentAccount.current_amount).to eql(-10000.99)
        expect(response.body).to include_json({status: 'success'})
      end
    end

    context 'WLT006-02' do
      before do
        params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '500.0'}}
        create_document(params)
      end

      it 'Успешное исполнение документа для перевода СЭД на СЭД' do
        put :execute, params: { id: '2' }

        expect(Folder.count).to                                     eql(2)
        expect(Document.count).to                                   eql(2)
        expect(Document.last.status).to                             eql('executed')
        expect(agent_with_balance.available_balance_amount).to      eql(499500.0)
        expect(agent_with_balance.current_balance_amount).to        eql(499500.0)
        expect(individual1.available_balance_amount).to             eql(500.0)
        expect(individual1.current_balance_amount).to               eql(500.0)
        expect(CorrespondentAccount.current_amount).to              eql(-500000.0)
        expect(response.body).to include_json({status: 'success'})
      end
    end

    context 'WLT006-03' do
      before do
        params = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '500.0'}}
        create_document(params)
      end

      it 'Успешное исполнение документа для вывода денежных средств' do
        put :execute, params: { id: '2' }

        expect(Folder.count).to                                     eql(2)
        expect(Document.count).to                                   eql(2)
        expect(Document.last.document_type).to                      eql('withdrawal')
        expect(Document.last.status).to                             eql('executed')
        expect(agent_with_balance.available_balance_amount).to      eql(499500.0)
        expect(agent_with_balance.current_balance_amount).to        eql(499500.0)
        expect(CorrespondentAccount.current_amount).to              eql(-499500.0)
        expect(response.body).to include_json({status: 'success'})
      end
    end

    context 'WLT006-04' do
      let(:emission_document) do
        params = {id: '1', folder_id: '2', type: 'emission', params: {target_account_id: agent.identity_number, amount: '10000.99'}}
        document = create_document(params)
        CancelDocument.call(folder_id: document.folder.folder_id)
        document
      end

      it "Возвращает ошибку если статус документа не является 'created'" do
        put :execute, params: { id: emission_document.document_number }

        expect(response.body).to include_json(status: 'error', message: { code: 'Exceptions::InvalidRequest' } )
      end
    end

    context 'WLT006-05' do
      it 'Возвращает ошибку если документ не найден' do
        put :execute, params: { id: '99999' }

        expect(response.body).to include_json({status: 'error', message: { code: 'Exceptions::DocumentNotFound' }})
      end
    end
  end

  describe 'WLT009 Отмена докумета' do
    context 'WLT009-01' do
      before do
        params = {id: '1', folder_id: 2, type: 'emission', params: {target_account_id: agent.identity_number, amount: '10000.99'}}
        create_document(params)

        params = {id: '2', folder_id: 2, type: 'emission', params: {target_account_id: agent.identity_number, amount: '10000.99'}}
        create_document(params)
      end

      it 'Успешная отмена папки документов дли эмиссии' do
        folder_id = Folder.first.folder_id
        put :cancel, params: { id: folder_id }

        expect(response.body).to include_json({status: 'success'})
        expect(Folder.count).to                       eql(1)
        expect(Folder.first.documents.count).to       eql(2)

        expect(Document.count).to                     eql(2)
        expect(Document.first.document_type).to       eql('emission')
        expect(Document.first.status).to              eql('canceled')
        expect(Document.first.held_balance.blank?).to be true

        expect(Document.count).to                      eql(2)
        expect(Document.second.document_type).to       eql('emission')
        expect(Document.second.status).to              eql('canceled')
        expect(Document.second.held_balance.blank?).to be true

        expect(agent.held_balances.count).to           eql(0)
      end
    end

    context 'WLT009-02' do
      before do
        params = {id: '2', folder_id: '4', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '800.0'}}
        create_document(params)
      end

      it 'Успешная отмена папки документов для перевода СЭД на СЭД' do
        folder = Folder.last
        put :cancel, params: { id: folder.folder_id }

        expect(response.body).to include_json({status: 'success'})
        expect(Folder.count).to                             eql(2)
        expect(folder.folder_id).to                         eql(4)
        expect(folder.documents.count).to                   eql(1)
        expect(Document.last.document_type).to              eql('transfer')
        expect(Document.last.status).to                     eql('canceled')
        expect(Document.last.held_balance.blank?).to        be true
        expect(agent_with_balance.held_balances.count).to   eql(0)
      end
    end

    context 'WLT009-03' do
      before do
        params = {id: '2', folder_id: '10', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '800.0'}}
        create_document(params)
      end

      it 'Успешная отмена папки документа для вывода денежных средств' do
        folder = Folder.last
        put :cancel, params: { id: folder.folder_id }

        expect(response.body).to include_json({status: 'success'})
        expect(Folder.count).to                            eql(2)
        expect(folder.documents.count).to                  eql(1)
        expect(Document.count).to                          eql(2)
        expect(Document.last.document_type).to             eql('withdrawal')
        expect(Document.last.status).to                    eql('canceled')
        expect(Document.last.held_balance.blank?).to       be true
        expect(agent_with_balance.held_balances.count).to  eql(0)
      end
    end

    context 'WLT009-03' do
      before do
        params1 = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '800.0'}}
        params2 = {id: '3', folder_id: '3', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '800.0'}}
        create_document(params1)
        create_document(params2)
      end

      it 'Успешная отмена одного из созданных документов' do
        folder = Folder.last
        put :cancel, params: { id: folder.folder_id }

        expect(response.body).to include_json({status: 'success'})
        expect(Folder.count).to                           eql(3)
        expect(Document.count).to                         eql(3)
        expect(folder.documents.count).to                 eql(1)
        expect(Document.second.held_balance.nil?).to      be false
        expect(Document.third.held_balance.nil?).to       be true
        expect(agent_with_balance.held_balances.count).to eql(1)
        expect(agent_with_balance.held_balance_amount).to eql(800.0)
      end
    end

    context 'WLT009-05' do
      it 'Возвращает ошибку когда документ не найден' do
        put :cancel, params: { id: '99999' }

        expect(response.body).to include_json({status: 'error', message: {errors: "Couldn't find Folder"}})
      end
    end
  end
end
