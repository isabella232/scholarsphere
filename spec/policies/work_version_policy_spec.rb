# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionPolicy, type: :policy do
  subject { described_class }

  let(:work) { instance_double 'Work' }
  let(:work_version) { instance_double 'WorkVersion', work: work }
  let(:user) { instance_double 'User' }
  let(:work_policy) { instance_double 'WorkPolicy' }

  permissions :show?, :diff? do
    before { allow(Pundit).to receive(:policy).with(user, work).and_return(work_policy) }

    context 'when the user has show access to the work' do
      before { allow(work_policy).to receive(:show?).and_return(true) }

      it { is_expected.to permit(user, work_version) }
    end

    context 'when the user has NO show access to the work' do
      before { allow(work_policy).to receive(:show?).and_return(false) }

      it { is_expected.not_to permit(user, work_version) }
    end
  end

  permissions :edit?, :update?, :destroy?, :publish? do
    before { allow(Pundit).to receive(:policy).with(user, work).and_return(work_policy) }

    context 'when the version is NOT published' do
      before { allow(work_version).to receive(:published?).and_return(false) }

      context 'when the user has the access to the work' do
        before { allow(work_policy).to receive(:edit?).and_return(true) }

        it { is_expected.to permit(user, work_version) }
      end

      context 'when the user does NOT have the access to the work' do
        before { allow(work_policy).to receive(:edit?).and_return(false) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end

    context 'when the version is published' do
      before { allow(work_version).to receive(:published?).and_return(true) }

      context 'when the user has the access to the work' do
        before { allow(work_policy).to receive(:edit?).and_return(true) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end
  end

  permissions :download? do
    let(:work_version) { work.latest_version }

    context 'with a public user' do
      let(:user) { User.guest }

      context 'with a published, publicly readable work' do
        let(:work) { create(:work, has_draft: false) }

        it { is_expected.to permit(user, work_version) }
      end

      context 'with a publicly discoverable work' do
        let(:work) { create(:work, :with_authorized_access, discover_groups: [Group.public_agent]) }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'with a Penn State work' do
        let(:work) { create(:work, :with_authorized_access, has_draft: false) }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'with an embargoed public work' do
        let(:work) { create(:work, embargoed_until: (Time.zone.now + 6.days), has_draft: false) }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'with a draft work' do
        let(:work) { create(:work, has_draft: true) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end

    context 'with an authenticated user' do
      let(:me) { build(:user) }
      let(:someone_else) { build(:user) }

      context 'with a published, publicly readable work' do
        let(:work) { create(:work, has_draft: false, depositor: someone_else.actor) }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with a Penn State work' do
        let(:work) { create(:work, :with_authorized_access, has_draft: false, depositor: someone_else.actor) }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with a draft version I deposited' do
        let(:work) { create(:work, depositor: me.actor) }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with a draft version I did NOT deposit' do
        let(:work) { build(:work, depositor: someone_else.actor) }

        it { is_expected.not_to permit(me, work_version) }
      end

      context 'with an embargoed public work' do
        let(:work) { create(:work, has_draft: false, depositor: someone_else.actor, embargoed_until: (Time.zone.now + 6.days)) }

        it { is_expected.not_to permit(me, work_version) }
      end

      context 'with an embargoed work I deposited' do
        let(:work) { create(:work, has_draft: false, depositor: me.actor, embargoed_until: (Time.zone.now + 6.days)) }

        it { is_expected.to permit(me, work_version) }
      end

      context 'with an embargoed work editable by me' do
        let(:work) do
          create :work,
                 has_draft: false,
                 depositor: someone_else.actor,
                 embargoed_until: (Time.zone.now + 6.days),
                 edit_users: [me]
        end

        it { is_expected.to permit(me, work_version) }
      end
    end
  end

  permissions :new? do
    before { allow(Pundit).to receive(:policy).with(user, work).and_return(work_policy) }

    context 'when the parent work is elligible to create a new version' do
      before { allow(work_policy).to receive(:create_version?).and_return(true) }

      context 'when the given work version is the latest published version' do
        before { allow(work).to receive(:latest_published_version).and_return(work_version) }

        it { is_expected.to permit(user, work_version) }
      end

      context 'when the given work version is NOT the latest published version' do
        before { allow(work).to receive(:latest_published_version).and_return(instance_double('WorkVersion')) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end

    context 'when the parent work cannot create a new version' do
      before { allow(work_policy).to receive(:create_version?).and_return(false) }

      context 'when the given work version is the latest published version' do
        before { allow(work).to receive(:latest_published_version).and_return(work_version) }

        it { is_expected.not_to permit(user, work_version) }
      end

      context 'when the given work version is NOT the latest published version' do
        before { allow(work).to receive(:latest_published_version).and_return(instance_double('WorkVersion')) }

        it { is_expected.not_to permit(user, work_version) }
      end
    end
  end
end
