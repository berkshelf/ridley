RSpec::Matchers.define :each do |check|
  match do |actual|
    actual.each_with_index do |index, o|
      @object = o
      index.should check
    end
  end

  failure_message_for_should do |actual|
    "at[#{@object}] #{check.failure_message_for_should}"
  end
end
