RSpec.shared_examples 'real sample' do |detector_class:, sample_path:, expected_gesture_class:, expected_gesture_attributes:|
  let(:parser) { Fusuma::Plugin::Parsers::TouchParser.new }
  let(:buffer) { Fusuma::Plugin::Buffers::TouchBuffer.new }
  let(:detector) { detector_class.new }
  let(:lines) { File.readlines(sample_path).map(&:strip).reject(&:empty?) }

  it 'detects the expected gesture' do
    t = Time.now

    gesture = nil
    lines.find do |line|
      record = parser.parse_record(line)
      next unless record

      event = Fusuma::Plugin::Events::Event.new(tag: 'libinput_touch_parser', record: record, time: t + record.time_offset)
      buffer.buffer(event)
      gesture = detector.detect(buffer)
      break if gesture
    end

    expect(gesture).to be_a(expected_gesture_class)
    expected_gesture_attributes.each do |key, value|
      expect(gesture.send(key)).to eq(value)
    end
  end
end
