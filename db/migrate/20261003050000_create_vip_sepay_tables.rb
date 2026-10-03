# frozen_string_literal: true

class CreateVipSepayTables < ActiveRecord::Migration[7.0]
  def up
    create_table :vip_sepay_plans do |t|
      t.string :name, null: false
      t.text :description
      t.bigint :price_vnd, null: false
      t.integer :duration_days, null: false
      t.bigint :group_id, null: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :vip_sepay_plans, :group_id
    add_index :vip_sepay_plans, [:active, :position]

    create_table :vip_sepay_orders do |t|
      t.string :order_code, null: false
      t.bigint :user_id, null: false
      t.bigint :plan_id, null: false
      t.bigint :amount_vnd, null: false
      t.string :status, null: false, default: "pending"
      t.string :sepay_transaction_id
      t.string :reference_code
      t.datetime :paid_at
      t.datetime :expires_at
      t.datetime :cancelled_at
      t.text :raw_payload
      t.timestamps
    end

    add_index :vip_sepay_orders, :order_code, unique: true
    add_index :vip_sepay_orders, [:user_id, :status]
    add_index :vip_sepay_orders,
              :sepay_transaction_id,
              unique: true,
              where: "sepay_transaction_id IS NOT NULL"
    add_index :vip_sepay_orders, :expires_at

    create_table :vip_sepay_subscriptions do |t|
      t.bigint :user_id, null: false
      t.bigint :plan_id, null: false
      t.bigint :group_id, null: false
      t.datetime :starts_at, null: false
      t.datetime :expires_at, null: false
      t.string :status, null: false, default: "active"
      t.bigint :order_id
      t.boolean :membership_added_by_plugin, null: false, default: false
      t.datetime :cancelled_at
      t.timestamps
    end

    add_index :vip_sepay_subscriptions, [:user_id, :status]
    add_index :vip_sepay_subscriptions, :expires_at
    add_index :vip_sepay_subscriptions, :order_id

    # Custom short name because PostgreSQL index names are limited to 63 characters.
    add_index :vip_sepay_subscriptions,
              [:user_id, :group_id, :status],
              name: "idx_vip_sepay_sub_user_group_status"

    create_table :vip_sepay_transactions do |t|
      t.string :sepay_transaction_id, null: false
      t.string :order_code
      t.bigint :order_id
      t.bigint :user_id
      t.bigint :amount_vnd
      t.string :transfer_type
      t.string :gateway
      t.string :reference_code
      t.datetime :transaction_at
      t.text :content
      t.text :raw_payload
      t.string :status, null: false, default: "received"
      t.timestamps
    end

    add_index :vip_sepay_transactions, :sepay_transaction_id, unique: true
    add_index :vip_sepay_transactions, :order_id
    add_index :vip_sepay_transactions, :order_code

    create_table :vip_sepay_audit_logs do |t|
      t.bigint :user_id
      t.string :action, null: false
      t.string :resource_type
      t.bigint :resource_id
      t.text :details
      t.timestamps
    end

    add_index :vip_sepay_audit_logs, :created_at
    add_index :vip_sepay_audit_logs, [:resource_type, :resource_id]
  end

  def down
    drop_table :vip_sepay_audit_logs if table_exists?(:vip_sepay_audit_logs)
    drop_table :vip_sepay_transactions if table_exists?(:vip_sepay_transactions)
    drop_table :vip_sepay_subscriptions if table_exists?(:vip_sepay_subscriptions)
    drop_table :vip_sepay_orders if table_exists?(:vip_sepay_orders)
    drop_table :vip_sepay_plans if table_exists?(:vip_sepay_plans)
  end
end
