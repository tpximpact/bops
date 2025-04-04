# frozen_string_literal: true

class AddDeviseTwoFactorToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :encrypted_otp_secret, :string
    add_column :users, :encrypted_otp_secret_iv, :string
    add_column :users, :encrypted_otp_secret_salt, :string
    add_column :users, :consumed_timestep, :integer
    add_column :users, :otp_required_for_login, :boolean

    add_index :users, :encrypted_otp_secret, unique: true

    User.all.find_each do |user|
      user.update(
        otp_required_for_login: true,
        otp_secret: User.generate_otp_secret
      )
    end
  end
end
