# == Schema Information
#
# Table name: friendships
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  friend_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  state      :string
#
# Indexes
#
#  index_friendships_on_state                  (state)
#  index_friendships_on_user_id_and_friend_id  (user_id,friend_id)
#

class Friendship < ActiveRecord::Base
  include AASM

  validates :state, presence: true
  validates :user, presence: { message: "that actually exists must be assigned!" }
  validates :friend, presence: { message: "that actually exists must be assigned!" }
  validates :state, inclusion: { in: %w(pending requested accepted blocked),
    message: "%{value} is not a valid state!" }

  belongs_to :user
  belongs_to :friend, class_name: 'User', foreign_key: 'friend_id'

  after_destroy :delete_mutual_friendship!

  aasm :column => 'state', :whiny_transitions => false do
    state :pending, :initial => true
    state :requested
    state :accepted
    state :blocked

    event :accept, :after => :accept_mutual_friendship! do
      transitions :from => :requested, :to => :accepted
    end

    event :block, :after => :block_mutual_friendship! do
      transitions :from => [:requested, :pending, :accepted], :to => :blocked
    end
  end

  validate :not_blocked

  def not_blocked
    if Friendship.exists?(user_id: user_id, friend_id: friend_id, state: "blocked") || Friendship.exists?(user_id: friend_id, friend_id: user_id, state: "blocked")
      errors.add(:base, "The friendship cannot be created.")
    end
  end

  def self.request(user1, user2)
    transaction do
      friendship1 = create(user: user1, friend: user2, state: 'pending')
      friendship2 = create(user: user2, friend: user1, state: 'requested')

      #friendship1.send_acceptance_email
      friendship1
    end
  end

  def send_request_email
    UserNotifier.friend_requested(id).deliver_now
  end

  def send_acceptance_email
    UserNotifier.friend_request_accepted(id).deliver_now
  end

  def mutual_friendship
    self.class.where({user_id: friend_id, friend_id: user_id}).first
  end

  def accept_mutual_friendship!
    #this accepts the mirrored friendship to let the original user know the friendhip was accepted
    mutual_friendship.update_attribute(:state, 'accepted')
  end

  def delete_mutual_friendship!
    mutual_friendship.delete
  end

  def block_mutual_friendship!
    mutual_friendship.update_attribute(:state, 'blocked') if mutual_friendship
  end
end
