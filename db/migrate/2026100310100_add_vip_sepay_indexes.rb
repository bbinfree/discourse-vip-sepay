# frozen_string_literal: true

class AddVipSepayIndexes < ActiveRecord::Migration[7.0]
  def up
    add_index :vip_sepay_orders, [:user_id, :plan_id, :status], name: "idx_vip_sepay_orders_user_plan_status" unless index_exists?(:vip_sepay_orders, [:user_id, :plan_id, :status], name: "idx_vip_sepay_orders_user_plan_status")
  end

  def down
    remove_index :vip_sepay_orders, name: "idx_vip_sepay_orders_user_plan_status" if index_exists?(:vip_sepay_orders, name: "idx_vip_sepay_orders_user_plan_status")
  end
end
