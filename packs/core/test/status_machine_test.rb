require "test_helper"

module Dispatch
  class StatusMachineTest < ActiveSupport::TestCase
    LEGAL = [
      %w[requested scheduled],
      %w[requested cancelled],
      %w[scheduled in_progress],
      %w[scheduled cancelled],
      %w[in_progress completed],
      %w[in_progress cancelled],
      %w[completed invoiced]
    ]

    test "the machine knows exactly the legal edges" do
      StatusMachine::STATUSES.each do |from|
        StatusMachine::STATUSES.each do |to|
          expected = LEGAL.include?([ from, to ])
          assert_equal expected, StatusMachine.can_move?(from, to), "#{from} -> #{to}"
        end
      end
    end

    test "every illegal pair is refused with the from and to named" do
      StatusMachine::STATUSES.each do |from|
        StatusMachine::STATUSES.each do |to|
          next if LEGAL.include?([ from, to ]) && to != "invoiced"

          error = assert_raises(InvalidTransition, "#{from} -> #{to}") do
            StatusMachine.check_transition!(from, to)
          end
          assert_equal "cannot move a job from #{from} to #{to}", error.message
        end
      end
    end

    test "invoiced is never reachable through the transition path" do
      assert_raises InvalidTransition do
        StatusMachine.check_transition!("completed", "invoiced")
      end
    end

    test "legal moves pass the guard" do
      StatusMachine.check_transition!("requested", "scheduled")
      StatusMachine.check_transition!("scheduled", "in_progress")
      StatusMachine.check_transition!("in_progress", "completed")
      StatusMachine.check_transition!("in_progress", "cancelled")
    end

    test "terminal statuses" do
      assert StatusMachine.terminal?("invoiced")
      assert StatusMachine.terminal?("cancelled")
      (StatusMachine::STATUSES - %w[invoiced cancelled]).each do |status|
        assert_not StatusMachine.terminal?(status), status
      end
    end

    test "status? recognizes only the six wire values" do
      %w[requested scheduled in_progress completed invoiced cancelled].each do |status|
        assert StatusMachine.status?(status)
      end
      [ "REQUESTED", "in-progress", "done", "", nil ].each do |value|
        assert_not StatusMachine.status?(value), value.inspect
      end
    end
  end
end
