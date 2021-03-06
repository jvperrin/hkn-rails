require 'rails_helper'

describe "events/show.html.haml" do
  before(:each) do
    start_time = Time.utc(2011, 1, 25, 11)
    event_type = stub_model(EventType, name: "Fun Event")
    good_opts = {
      start_time: start_time,
      end_time: start_time + 30.minutes,
      event_type: event_type,
    }
    @event = assign(:event, stub_model(Event, good_opts))
    @auth = assign(:auth, Hash.new)
  end

  it "renders attributes in <p>" do
    render
  end

  it "renders properly with rsvps" do
    expect(@event).to receive(:can_rsvp?) { true }
    stub_block = stub_model(Block)
    allow(stub_block).to receive(:rsvps) { [] }
    allow(@event).to receive(:blocks) { [stub_block] }
    @auth["candplus"] = true
    render
  end
end
