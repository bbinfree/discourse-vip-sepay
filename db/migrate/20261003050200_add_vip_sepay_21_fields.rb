# frozen_string_literal: true

class AddVipSepay21Fields < ActiveRecord::Migration[7.0]
  def change
    add_column :vip_sepay_plans, :highlight, :boolean, null: false, default: false unless column_exists?(:vip_sepay_plans, :highlight)
    add_column :vip_sepay_plans, :sort_label, :string unless column_exists?(:vip_sepay_plans, :sort_label)
    add_column :vip_sepay_transactions, :account_number, :string unless column_exists?(:vip_sepay_transactions, :account_number)
    add_column :vip_sepay_transactions, :counterparty_account, :string unless column_exists?(:vip_sepay_transactions, :counterparty_account)
    add_column :vip_sepay_transactions, :verification_error, :string unless column_exists?(:vip_sepay_transactions, :verification_error)
    add_index :vip_sepay_subscriptions, [:status, :expires_at], name: "idx_vip_sepay_subscriptions_status_expires" unless index_exists?(:vip_sepay_subscriptions, [:status, :expires_at], name: "idx_vip_sepay_subscriptions_status_expires")
    add_index :vip_sepay_orders, [:status, :created_at], name: "idx_vip_sepay_orders_status_created" unless index_exists?(:vip_sepay_orders, [:status, :created_at], name: "idx_vip_sepay_orders_status_created")
  end
end
