RSpec.describe Mortar::FireCommand do

    describe '#variables_struct' do
      let(:subject) do
        subject = described_class.new('')
        subject.load_config # Load the empty config
        subject
      end

      it 'has each' do
        subject.parse(["test-shot", "/foobar", "--var", "foo=bar", "--var", "bar=baz"])

        vars = subject.variables_struct
        keys = []
        vars.each do |k,v|
          keys << k
        end
        expect(keys).to eq(["foo", "bar"])
      end

      it 'has each for nested vars' do
        subject.parse(["test-shot", "/foobar", "--var", "port.foo=80", "--var", "port.bar=8080"])

        vars = subject.variables_struct
        ports = []
        vars.port.each do |k,v|
          ports << { k => v}
        end
        expect(ports).to eq([{'foo' => '80'}, { 'bar' => '8080'}])
      end

      it 'produces proper struct even without any vars' do
        subject.parse(["test-shot", "/foobar", "--var", "port.foo=80", "--var", "port.bar=8080"])

        vars = subject.variables_struct
        ports = []
        vars.port.each do |k,v|
          ports << { k => v}
        end
        expect(ports).to eq([{'foo' => '80'}, { 'bar' => '8080'}])
      end

      it 'overrides only given config file variable' do
        subject.parse(["test-shot", "/foobar", "-c", fixture_path('config/config.yaml'), "--var", "some.deeper=deep"])
        subject.load_config

        vars = subject.variables_struct
        keys = []
        vars.some.each do |k,v|
          keys << { k => v}
        end
        expect(keys).to eq([{'deeper' => 'deep'}, {'deepest' => 'variable'}])
      end

      it 'appends config file variable' do
        subject.parse(["test-shot", "/foobar", "-c", fixture_path('config/config.yaml'), "--var", "some.deep=variable"])
        subject.load_config

        vars = subject.variables_struct
        keys = []
        vars.some.each do |k,v|
          keys << { k => v}
        end
        expect(keys).to eq([{'deeper' => 'variable'}, { 'deepest' => 'variable'}, { 'deep' => 'variable' }])
      end
    end

    describe "#build_kubeconfig_from_env" do
      let(:subject) { described_class.new('') }
      it 'shows error in token not base64 encoded' do
        ENV['KUBE_TOKEN'] = 'foobar'
        expect(subject).to receive(:signal_usage_error).with("KUBE_TOKEN env doesn't seem to be base64 encoded!")
        subject.build_kubeconfig_from_env
      end

      it 'returns valid config with decoded token' do
        ENV['KUBE_TOKEN'] = Base64.strict_encode64('foobar')
        expect(subject).not_to receive(:puts)
        cfg = subject.build_kubeconfig_from_env
        expect(cfg.user.token).to eq('foobar')
      end

    end

    describe "#variables_hash" do
      it 'return empty hash with no vars' do
        subject = described_class.new('')
        subject.parse(["test-shot", "/foobar"])
        expect(subject.variables_hash).to eq({})
      end
    end
  end
