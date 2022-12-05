module Bitrix24
  module Manager
    def manager_id(member)
      return member.bitrix24_id if member.bitrix24_id.present?

      users = Bitrix24CloudApi::COMMON_METHODS::User.get(client)['result']
      current_user = users.find { |user| user['EMAIL'] == member.email }

      member.update_column :bitrix24_id, current_user['ID']
      member.bitrix24_id
    end
  end
end
