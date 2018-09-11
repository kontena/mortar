require 'openssl'

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

    describe "--kube-token" do
      let(:subject) { described_class.new('') }

      it 'shows an error if token not base64 encoded' do
        expect {
          subject.run(%w(--kube-token &foofoo --kube-server localhost --kube-ca foo name examples/basic))
        }.to raise_error(Clamp::UsageError, "kube token doesn't seem to be base64 encoded!")
      end

      it 'does not show an error in token is base64 encoded' do
        expect(K8s::Config).to receive(:new).with(
          hash_including(
            clusters: array_including(
              hash_including(cluster: { server: 'localhost', certificate_authority_data: 'foo' })
            ),
            users: array_including(
              hash_including(user: { token: 'foofoo' })
            )
          )
        ).and_call_original

        expect {
          subject.run(%w(--kube-server localhost --kube-ca foo --kube-token) + [Base64.strict_encode64('foofoo')] + %w(name examples/basic))
        }.to raise_error(OpenSSL::X509::CertificateError)
      end
    end
  end
