require 'active_record'

class Activity < ActiveRecord::Base
  RESULTS = %w[succeed failed denied].freeze

  validates :user_ip, presence: true, allow_blank: false
  validates :topic, :user_agent, presence: true
  validates :result, presence: true, inclusion: { in: RESULTS }

  private

  def readonly?
    !new_record?
  end
end
