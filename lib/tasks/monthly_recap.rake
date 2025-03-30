namespace :monthly_recap do
  desc "Send monthly recap emails to all users"
  task send_emails: :environment do
    User.find_each do |user|
      RecapMailer.monthly_recap(user).deliver_later
    end
  end
end 