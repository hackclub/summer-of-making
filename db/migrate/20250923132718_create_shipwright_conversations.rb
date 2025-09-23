class CreateShipwrightConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :shipwright_conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :shipwright_id, null: false
      t.string :subject, null: false
      t.string :slack_channel_id, null: false
      t.string :status, default: 'active', null: false
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :shipwright_conversations, :shipwright_id
    add_index :shipwright_conversations, :slack_channel_id, unique: true
    add_index :shipwright_conversations, :status
    add_foreign_key :shipwright_conversations, :users, column: :shipwright_id, validate: false
  end
end
