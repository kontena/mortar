RSpec.describe Mortar::Config do
  describe '#self.load' do
    it 'raises on empty config' do
      expect {
        described_class.load(fixture_path('config/config_empty.yaml'))
      }.to raise_error(Mortar::Config::ConfigError, 'Failed to load config, check config file syntax')
    end

    it 'loads vars from file' do
      cfg = described_class.load(fixture_path('config/config.yaml'))
      vars = cfg.variables
      expect(vars.foo).to eq('bar')
      expect(vars.some.deeper).to eq('variable')
      expect(cfg.overlays).to eq([])
      expect(cfg.labels.to_h).to eq({})
    end

    it 'loads overlays from file' do
      cfg = described_class.load(fixture_path('config/config_overlays.yaml'))
      expect(cfg.overlays).to eq(['foo', 'bar'])
    end

    it 'loads labels from file' do
      cfg = described_class.load(fixture_path('config/config_labels.yaml'))
      expect(cfg.labels.foo).to eq('bar')
    end

    it 'raises on non array overlays' do
      expect {
        described_class.load(fixture_path('config/config_overlays_error.yaml'))
      }.to raise_error(Mortar::Config::ConfigError, 'Failed to load config, overlays needs to be an array')
    end

    it 'raises on non hash labels' do
      expect {
        described_class.load(fixture_path('config/config_labels_error.yaml'))
      }.to raise_error(Mortar::Config::ConfigError, 'Failed to load config, labels needs to be a hash')
    end
  end
end
