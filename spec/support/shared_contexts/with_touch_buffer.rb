RSpec.shared_context 'with touch buffer' do
  let(:touch_buffer) { Fusuma::Plugin::Buffers::TouchBuffer.new }
  let(:t) { Time.now }

  before do
    allow(touch_buffer).to receive(:movement_threshold).and_return(0.5)
  end
end