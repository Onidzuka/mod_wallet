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

  describe '#create' do
    context 'create emission document command' do
      it 'creates document with type emission' do
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

      context 'when document type is invalid' do
        it 'returns an error' do
          params = {id: '1', folder_id: '1', type: 'invalid_type', params: {target_account_id: agent.identity_number, amount: '100.0'}}

          post :create, params: params

          expect(Document.count).to eql(0)
          expect(response.body).to include_json({
            status: 'error',
            message: 'Exceptions::InvalidDocumentType'
          })
        end
      end

      context 'when withdrawal amount is invalid' do
        it 'returns an error' do
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

      context 'when document id invalid' do
        it 'returns an error' do
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

      context 'when document id invalid' do
        it 'returns an error' do
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

      context 'when account not found' do
        it 'returns an error' do
          params = {id: '1', folder_id: '1', type: 'emission', params: {target_account_id: '99999', amount: '100.0'}}

          post :create, params: params

          expect(Folder.count).to                 eql(1)
          expect(Document.count).to               eql(1)
          expect(Document.first.document_type).to eql('emission')
          expect(Document.first.status).to        eql('invalid')
          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountNotFound'}})
        end
      end

      context 'when target account closed' do
        it 'returns an error' do
          params = {id: '1', folder_id: '1', type: 'emission', params: {target_account_id: closed_agent.identity_number, amount: '100.0'}}

          post :create, params: params

          expect(Folder.count).to                 eql(1)
          expect(Document.count).to               eql(1)
          expect(Document.first.document_type).to eql('emission')
          expect(Document.first.status).to        eql('invalid')
          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountClosed'}})
        end
      end

      context 'when target account blocked' do
        it 'returns an error' do
          params = {id: '1', folder_id: '1', type: 'emission', params: {target_account_id: blocked_account.identity_number, amount: '1000.0'}}

          post :create, params: params

          expect(Folder.count).to                 eql(1)
          expect(Document.count).to               eql(1)
          expect(Document.first.document_type).to eql('emission')
          expect(Document.first.status).to        eql('invalid')
          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountBlocked'}})
        end
      end

      context 'when target account not agent' do
        it 'returns an error' do
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

    context 'create transfer document command' do
      context 'when transfer between individuals' do
        let(:transfer_document) do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '500.0'}}
          create_document(params)
        end

        before { put :execute, params: { id: transfer_document.document_number } }

        it 'creates document for transfer funds between individuals' do
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

      context 'when transfer from agent to individual' do
        it 'creates document for transfer from agent to individual' do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual2.identity_number, amount: '1000.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'success'})
          expect(Folder.count).to                        eql(2)
          expect(Document.count).to                      eql(2)
          expect(Document.last.status).to                eql('created')
          expect(Document.last.document_type).to         eql('transfer')
        end
      end

      context 'when transfer from individual to merchant' do
        let(:transfer_document) do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '500.0'}}
          create_document(params)
        end

        before { put :execute, params: { id: transfer_document.document_number } }

        it 'creates document for transfer from individual to merchant' do
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

      context 'when forbidden transfer' do
        let(:transfer_document) do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '500.0'}}
          create_document(params)
        end

        before do
          put :execute, params: { id: transfer_document.document_number.to_s }
        end

        it 'returns an error' do
          params = {id: '3', folder_id: '3', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: agent_with_balance.identity_number, amount: '400.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::ForbiddenTransfer'}})
          expect(Folder.count).to                        eql(3)
          expect(Document.count).to                      eql(3)
          expect(Document.last.status).to                eql('invalid')
          expect(Document.last.document_type).to         eql('transfer')
        end
      end

      context 'when source account not found' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: '99999', target_account_id: individual2.identity_number, amount: '100.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::SourceAccountNotFound'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to   eql(1)
        end
      end

      context 'when target account not found' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: '99999', amount: '100.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::TargetAccountNotFound'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to   eql(1)
        end
      end

      context 'when source account is blocked' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: blocked_account.identity_number, target_account_id: individual2.identity_number, amount: '100.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::SourceAccountBlocked'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to   eql(1)
        end
      end

      context 'when target account is blocked' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: blocked_account.identity_number, amount: '100.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::TargetAccountBlocked'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to   eql(1)
        end
      end

      context 'when source account is closed' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: closed_individual.identity_number, target_account_id: individual2.identity_number, amount: '100.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::SourceAccountClosed'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to   eql(1)
        end
      end

      context 'when target account closed' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: closed_individual.identity_number, amount: '100.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::TargetAccountClosed'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to   eql(1)
        end
      end

      context 'when self selection transfer' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: individual1.identity_number, amount: '100.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::SelfSelectionTransfer'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to   eql(1)
        end
      end

      context 'when source account has insufficient balance' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: individual1.identity_number, target_account_id: individual2.identity_number, amount: '100.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::InsufficientBalance'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to   eql(1)
        end
      end

      context 'when transfer limit between individuals is exceeded' do
        let(:transfer_document) do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '300000.0'}}
          create_document(params)
        end

        before { put :execute, params: { id: transfer_document.document_number } }

        it 'returns an error' do
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

      context 'when source account has 100.000$' do
        let(:transfer_document) do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '100000.0'}}
          create_document(params)
        end

        before { put :execute, params: { id: transfer_document.document_number } }

        it 'creates only 2 documents with transfer amount 40.000$ and a third one fails' do
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

    context 'create withdrawal document command' do
      it 'creates document with type withdrawal' do
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

      context 'when target account not found' do
        it 'returns an error' do
          params = {id: '1', folder_id: '1', type: 'withdrawal', params: {target_account_id: '99999', amount: '500'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountNotFound'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to eql(1)
        end
      end

      context 'when target account closed' do
        it 'returns an error' do
          params = {id: '1', folder_id: '1', type: 'withdrawal', params: {target_account_id: closed_agent.identity_number, amount: '500'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountClosed'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to eql(1)
        end
      end

      context 'when target account blocked' do
        it 'returns an error' do
          params = {id: '1', folder_id: '1', type: 'withdrawal', params: {target_account_id: blocked_account.identity_number, amount: '500'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::AccountBlocked'}})
          expect(Document.count).to eql(1)
          expect(Folder.count).to eql(1)
        end
      end

      context 'when insufficient balance' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '600000'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::InsufficientBalance'}})
          expect(Document.count).to eql(2)
          expect(Folder.count).to eql(2)
        end
      end

      context 'when withdrawal amount invalid' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '-2000'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::InvalidDocument'}})
          expect(Document.count).to eql(2)
          expect(Folder.count).to eql(2)
        end
      end

      context 'when withdrawal amount invalid' do
        it 'returns an error' do
          params = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '0.0'}}
          post :create, params: params

          expect(response.body).to include_json({status: 'error', message: {code: 'Exceptions::InvalidDocument'}})
          expect(Document.count).to eql(2)
          expect(Folder.count).to eql(2)
        end
      end
    end
  end

  describe '#execute' do
    before do
      CorrespondentAccount.create!(amount: 0.0) if CorrespondentAccount.all.empty?
    end

    context 'execute document command' do
      context 'when document is emission' do
        let(:emission_document) do
          params = {id: '1', folder_id: '2', type: 'emission', params: {target_account_id: agent.identity_number, amount: '10000.99'}}
          create_document(params)
        end

        it 'executes document' do
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

      context 'when document is transfer' do
        before do
          params = {id: '2', folder_id: '2', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '500.0'}}
          create_document(params)
        end

        it 'executes document' do
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

      context 'when document type is withdrawal' do
        before do
          params = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '500.0'}}
          create_document(params)
        end

        it 'executes document' do
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

      context "when document's status is created" do
        let(:emission_document) do
          params = {id: '1', folder_id: '2', type: 'emission', params: {target_account_id: agent.identity_number, amount: '10000.99'}}
          document = create_document(params)
          CancelDocument.call(folder_id: document.folder.folder_id)
          document
        end

        it 'returns an error' do
          put :execute, params: { id: emission_document.document_number }

          expect(response.body).to include_json(status: 'error', message: { code: 'Exceptions::InvalidRequest' } )
        end
      end

      context 'when document not found' do
        it 'returns an error' do
          put :execute, params: { id: '99999' }

          expect(response.body).to include_json({status: 'error', message: { code: 'Exceptions::DocumentNotFound' }})
        end
      end
    end
  end

  describe '#cancel' do
    context 'cancel document command' do
      context 'when folder with emission type documents' do
        before do
          params = {id: '1', folder_id: 2, type: 'emission', params: {target_account_id: agent.identity_number, amount: '10000.99'}}
          create_document(params)

          params = {id: '2', folder_id: 2, type: 'emission', params: {target_account_id: agent.identity_number, amount: '10000.99'}}
          create_document(params)
        end

        it 'cancels all document in the folder with type emission' do
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

      context 'when folder with transfer type documents' do
        before do
          params = {id: '2', folder_id: '4', type: 'transfer', params: {source_account_id: agent_with_balance.identity_number, target_account_id: individual1.identity_number, amount: '800.0'}}
          create_document(params)
        end

        it 'cancels documents all in the folder' do
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

      context 'when folder with withdrawal type documents' do
        before do
          params = {id: '2', folder_id: '10', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '800.0'}}
          create_document(params)
        end

        it 'cancels all documents in the folder' do
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

      context 'when two folders with documents' do
        before do
          params1 = {id: '2', folder_id: '2', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '800.0'}}
          params2 = {id: '3', folder_id: '3', type: 'withdrawal', params: {target_account_id: agent_with_balance.identity_number, amount: '800.0'}}
          create_document(params1)
          create_document(params2)
        end

        it 'cancels documents from one folder only' do
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

      context 'when document not found' do
        it 'returns an error' do
          put :cancel, params: { id: '99999' }

          expect(response.body).to include_json({status: 'error', message: {errors: "Couldn't find Folder"}})
        end
      end
    end
  end
end
