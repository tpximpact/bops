# frozen_string_literal: true

class DropAgentsTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :agents
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
