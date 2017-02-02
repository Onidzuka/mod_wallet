module Exceptions
  class InvalidDocumentType        < StandardError; end
  class AccountNotFound            < StandardError; end
  class AccountClosed              < StandardError; end
  class AccountNotBlocked          < StandardError; end
  class InvalidRequest             < StandardError; end
  class InvalidAccountType         < StandardError; end
  class AccountBlocked             < StandardError; end
  class AccountTypeIsNotAgent      < StandardError; end
  class InvalidDocument            < StandardError; end
  class DocumentNotFound           < StandardError; end
  class SourceAccountNotFound      < StandardError; end
  class TargetAccountNotFound      < StandardError; end
  class SourceAccountBlocked       < StandardError; end
  class TargetAccountBlocked       < StandardError; end
  class SourceAccountClosed        < StandardError; end
  class TargetAccountClosed        < StandardError; end
  class SelfSelectionTransfer      < StandardError; end
  class ForbiddenTransfer          < StandardError; end
  class InvalidTransfer            < StandardError; end
  class InsufficientBalance        < StandardError; end
  class TransferLimitExceeded      < StandardError; end
end
