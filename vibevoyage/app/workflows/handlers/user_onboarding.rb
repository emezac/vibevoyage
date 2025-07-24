class UserOnboarding
  def self.call(input_data, workflow_variables)
    user = User.find(input_data['user_id'])
    user.update!(onboarded: true)
    { success: true, user: user.attributes }
  end
end
