# == Schema Information
#
# Table name: elections
#
#  id               :integer          not null, primary key
#  person_id        :integer          not null
#  position         :string(255)
#  sid              :integer
#  keycard          :integer
#  midnight_meeting :boolean          default(TRUE)
#  txt              :boolean          default(FALSE)
#  semester         :string(255)      not null
#  elected_time     :datetime         not null
#  created_at       :datetime
#  updated_at       :datetime
#  elected          :boolean          default(FALSE), not null
#  non_hkn_email    :string(255)
#  desired_username :string(255)
#

require 'rails_helper'

describe Election do
  before(:each) do
    ppl_data = [
      {
        person:   { first_name: 'Da Rock', last_name: 'Obama', username: 'bigpimpin' },
        election: { desired_username: 'bossman08', position: 'pres' },
      },
      {
        person:   { first_name: 'Hellory', last_name: 'Clinton', username: 'mzklinton' },
        election: { desired_username: 'billypleaser', position: 'pres' }
      }
    ]

    ppl = ppl_data.collect do |stuff|
      person = Person.where(stuff[:person]).first_or_initialize
      stuff[:person].update({
                             password: 'asdfjkl1111',
                             password_confirmation: 'asdfjkl1111',
                             email: "#{stuff[:person][:username]}@whitehouse.com"
                           })
      person.update_attributes stuff[:person]

      assert person.save

      election = Election.new stuff[:election]
      election.person = person

      [person, election]
    end

    @obama,  @obama_election  = ppl[0]
    @hilary, @hilary_election = ppl[1]
  end

  after(:each) do
    @obama_election.destroy if @obama_election
    @hilary_election.destroy if @hilary_election
    `rm -f ./elections_hknmod` # If this file isn't deleted, then autotest goes crazy
  end

  it "should prioritize requested username over existing one" do
    assert_equal @obama_election.final_username, @obama_election.desired_username
  end

  it "should disregard blank requested username" do
    @hilary_election.desired_username = nil
    assert_equal @hilary_election.final_username, @hilary.username

    @hilary_election.desired_username = ""
    assert_equal @hilary_election.final_username, @hilary.username
  end

  it "should set its own time properties on create" do
    assert_nil @obama_election.elected_time
    assert_nil @obama_election.semester

    @obama_election.save

    assert_in_delta Time.now, @obama_election.elected_time, 2.seconds
    assert_equal @obama_election.semester, Property.next_semester
  end

  context "during commit" do
    before(:each) do
      @obama_election.elected = true
      assert @obama_election.save
    end

    context "for elected people" do
      it "should apply username changes, if any" do
        @obama_election.should be_valid
        assert @obama_election.commit
        @obama.username.should == @obama_election.desired_username
      end

      it "should create a new committeeship" do
        assert @obama_election.commit
        assert Committeeship.exists?(semester: @obama_election.semester, person_id: @obama.id, committee: @obama_election.position, title: 'officer')
      end

      it "should add person to respective groups" do
        assert @obama_election.commit
        Group.where(name: [@obama_election.position, 'officers', 'comms', 'candplus']).each do |g|
          @obama.groups.should include g
        end
      end # it
    end # elected

    context "for non-elected people" do
      before(:each) do
        assert !@hilary_election.elected
        assert !@hilary_election.commit
      end

      it "should not apply username changes" do
        @hilary.username.should_not == @hilary_election.desired_username
      end

      it "should not create a new committeeship" do
        expect(Committeeship.count).to eq(0)
      end
    end # non-elected

  end # during commit
end
