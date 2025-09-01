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
            StatusMachine.check_transition!(from, to, appointment_count: 1)
          end
          assert_equal "cannot move a job from #{from} to #{to}", error.message
        end
      end
    end

    test "invoiced is never reachable through the transition path" do
      assert_raises InvalidTransition do
        StatusMachine.check_transition!("completed", "invoiced", appointment_count: 3)
      end
    end

    test "legal moves pass the guard" do
      StatusMachine.check_transition!("requested", "scheduled", appointment_count: 1)
      StatusMachine.check_transition!("scheduled", "in_progress", appointment_count: 1)
      StatusMachine.check_transition!("in_progress", "completed", appointment_count: 0)
      StatusMachine.check_transition!("in_progress", "cancelled", appointment_count: 0)
    end

    test "scheduling requires an appointment" do
      error = assert_raises ValidationFailed do
        StatusMachine.check_transition!("requested", "scheduled", appointment_count: 0)
      end
      assert_equal "a job needs an appointment before it can be scheduled", error.message
    end

    test "appointments attach only while work is open" do
      %w[requested scheduled in_progress].each do |status|
        StatusMachine.check_accepts_appointments!(status)
      end
      %w[completed invoiced cancelled].each do |status|
        error = assert_raises(ValidationFailed) { StatusMachine.check_accepts_appointments!(status) }
        assert_equal "appointments cannot be added to a job that is #{status}", error.message
      end
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
