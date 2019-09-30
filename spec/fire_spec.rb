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

    describe "#extra_labels" do
      let(:subject) { described_class.new('') }

      it 'returns empty hash by default' do
        expect(subject.extra_labels).to eq({})
      end

      it 'returns label has if label options are given' do
        subject.parse(["--label", "foo=bar", "--label", "bar=baz", "foobar", "foobar"])
        expect(subject.extra_labels).to eq({
          "foo" => "bar", "bar" => "baz"
        })
      end
    end

    describe "#inject_extra_labels" do
      let(:subject) { described_class.new('') }
      let(:resources) do
        [
          K8s::Resource.new({
            metadata: {
              labels: {
                userlabel: 'test'
              }
            }
          }),
          K8s::Resource.new({
            metadata: {
              name: 'foo'
            }
          })
        ]
      end

      it 'injects labels to resources' do
        extra_labels = { "foo" => "bar", "bar" => "baz" }
        result = subject.inject_extra_labels(resources, extra_labels)
        expect(result.first.metadata.labels.to_h).to eq({
          bar: "baz",
          foo: "bar",
          userlabel: "test"
        })
      end
    end
  end
