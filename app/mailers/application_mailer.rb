class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_FROM_EMAIL', 'noreply@raype.com')
  layout "mailer"
end
