# == Schema Information
#
# Table name: tutors
#
#  id         :integer          not null, primary key
#  person_id  :integer          not null
#  languages  :string(255)
#  created_at :datetime
#  updated_at :datetime
#  adjacency  :integer          default(0)
#

require 'rails_helper'

describe Tutor, "when created with blank parameters" do
  before(:each) do
    @tutor = Tutor.create
  end

  it "should require a person" do
    @tutor.should_not be_valid
    @tutor.errors[:person].should include("can't be blank")
  end
end

describe Tutor do
  before(:each) do
    @good_opts = {
      person: mock_model(Person),
      #availabilities: [mock_model(Availability)],
      languages: "C"
    }
  end

  it "should accept valid parameters" do
    tutor = Tutor.create(@good_opts)
    tutor.should be_valid
  end
end
