# frozen_string_literal: true

class UpgradeVipSepay22 < ActiveRecord::Migration[7.0]
  def up
    add_column :vip_sepay_transactions, :source, :string, null: false, default: "webhook" unless column_exists?(:vip_sepay_transactions, :source)
    add_column :vip_sepay_transactions, :verification_error, :string unless column_exists?(:vip_sepay_transactions, :verification_error)
    add_column :vip_sepay_transactions, :bank_account_id, :string unless column_exists?(:vip_sepay_transactions, :bank_account_id)
    add_column :vip_sepay_transactions, :va_id, :string unless column_exists?(:vip_sepay_transactions, :va_id)
    add_column :vip_sepay_orders, :payment_attempts, :integer, null: false, default: 0 unless column_exists?(:vip_sepay_orders, :payment_attempts)
    add_column :vip_sepay_orders, :last_payment_at, :datetime unless column_exists?(:vip_sepay_orders, :last_payment_at)
    add_index :vip_sepay_transactions, :reference_code unless index_exists?(:vip_sepay_transactions, :reference_code)
    add_index :vip_sepay_transactions, :transaction_at unless index_exists?(:vip_sepay_transactions, :transaction_at)
    unless index_exists?(:vip_sepay_orders, name: "uniq_vip_sepay_pending_user")
      duplicate_user_ids = execute(<<~SQL).to_a.map { |row| row["user_id"] }
        SELECT user_id
        FROM vip_sepay_orders
        WHERE status = 'pending'
        GROUP BY user_id
        HAVING COUNT(*) > 1
      SQL

      duplicate_user_ids.each do |user_id|
        ids = select_values(<<~SQL)
          SELECT id
          FROM vip_sepay_orders
          WHERE user_id = #{connection.quote(user_id)} AND status = 'pending'
          ORDER BY created_at DESC, id DESC
        SQL
        ids.drop(1).each do |id|
          execute("UPDATE vip_sepay_orders SET status = 'expired', updated_at = CURRENT_TIMESTAMP WHERE id = #{connection.quote(id)}")
        end
      end

      add_index :vip_sepay_orders, [:user_id, :status], unique: true, where: "status = 'pending'", name: "uniq_vip_sepay_pending_user"
    end
  end

  def down
    remove_index :vip_sepay_orders, name: "uniq_vip_sepay_pending_user" if index_exists?(:vip_sepay_orders, name: "uniq_vip_sepay_pending_user")
    remove_index :vip_sepay_transactions, :transaction_at if index_exists?(:vip_sepay_transactions, :transaction_at)
    remove_index :vip_sepay_transactions, :reference_code if index_exists?(:vip_sepay_transactions, :reference_code)
    remove_column :vip_sepay_orders, :last_payment_at if column_exists?(:vip_sepay_orders, :last_payment_at)
    remove_column :vip_sepay_orders, :payment_attempts if column_exists?(:vip_sepay_orders, :payment_attempts)
    remove_column :vip_sepay_transactions, :va_id if column_exists?(:vip_sepay_transactions, :va_id)
    remove_column :vip_sepay_transactions, :bank_account_id if column_exists?(:vip_sepay_transactions, :bank_account_id)
    remove_column :vip_sepay_transactions, :verification_error if column_exists?(:vip_sepay_transactions, :verification_error)
    remove_column :vip_sepay_transactions, :source if column_exists?(:vip_sepay_transactions, :source)
  end
end
