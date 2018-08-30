RSpec.describe Mortar::Command do

    describe '#variables_struct' do
      it 'has each' do
        subject = described_class.new('')
        subject.parse(["test-shot", "/foobar", "--var", "foo=bar", "--var", "bar=baz"])

        vars = subject.variables_struct
        keys = []
        vars.each do |k,v|
          keys << k
        end
        expect(keys).to eq(["foo", "bar"])
      end

      it 'has each for nested vars' do
        subject = described_class.new('')
        subject.parse(["test-shot", "/foobar", "--var", "port.foo=80", "--var", "port.bar=8080"])

        vars = subject.variables_struct
        ports = []
        vars.port.each do |k,v|
          ports << { k => v}
        end
        expect(ports).to eq([{'foo' => '80'}, { 'bar' => '8080'}])
      end
    end
  end
