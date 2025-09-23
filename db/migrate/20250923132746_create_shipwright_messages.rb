class CreateShipwrightMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :shipwright_messages do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :shipwright_conversations }
      t.bigint :sender_id, null: false
      t.text :content, null: false
      t.string :message_type, default: 'text', null: false
      t.string :slack_timestamp
      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :shipwright_messages, :sender_id
    add_index :shipwright_messages, :slack_timestamp
    add_index :shipwright_messages, [:conversation_id, :sent_at]
    add_foreign_key :shipwright_messages, :users, column: :sender_id
  end
end
