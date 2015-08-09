RSpec::Matchers.define :each do |check|
  match do |actual|
    actual.each_with_index do |index, o|
      @object = o
      expect(index).to check
    end
  end

  failure_message do |actual|
    "at[#{@object}] #{check.failure_message_for_should}"
  end
end
