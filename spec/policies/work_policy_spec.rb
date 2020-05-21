# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkPolicy, type: :policy do
  let(:user) { instance_double 'User' }
  let(:work) { instance_double 'Work' }

  describe '#show?' do
    it 'delegates to Work#read_access?' do
      allow(work).to receive(:discover_access?)
        .with(user).and_return(:whatever_discover_access_returns)

      expect(described_class.new(user, work).show?).to eq :whatever_discover_access_returns
    end
  end
end
