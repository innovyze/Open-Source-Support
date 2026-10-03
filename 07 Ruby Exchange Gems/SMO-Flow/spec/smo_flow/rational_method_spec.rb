# frozen_string_literal: true

require "spec_helper"

RSpec.describe SmoFlow::RationalMethod do
  let(:calc) { described_class.new(coefficient: 0.9, area: 1.0) }

  describe "#initialize" do
    it "stores the coefficient and area" do
      expect(calc.coefficient).to eq(0.9)
      expect(calc.area).to eq(1.0)
    end

    it "raises when coefficient is greater than 1" do
      expect { described_class.new(coefficient: 1.5, area: 1.0) }
        .to raise_error(SmoFlow::InvalidInput, "Coefficient must be between 0 and 1")
    end

    it "raises when coefficient is negative" do
      expect { described_class.new(coefficient: -0.1, area: 1.0) }
        .to raise_error(SmoFlow::InvalidInput, "Coefficient must be between 0 and 1")
    end

    it "raises when area is zero or negative" do
      expect { described_class.new(coefficient: 0.9, area: 0) }
        .to raise_error(SmoFlow::InvalidInput, "Area must be positive")
    end
  end

  describe "#flow_from_intensity" do
    it "calculates flow in m³/s" do
      # Q = 0.9 × 50 × 1.0 / 360 = 0.125
      expect(calc.flow_from_intensity(50.0)).to be_within(0.0001).of(0.125)
    end

    it "raises when intensity is zero or negative" do
      expect { calc.flow_from_intensity(0) }
        .to raise_error(SmoFlow::InvalidInput, "Intensity must be positive")
    end
  end

  describe "#flow_from_depth" do
    it "calculates flow in m³/s" do
      # Q = 10 × 0.9 × 1.0 × 5.0 / 3600 = 0.0125
      expect(calc.flow_from_depth(depth: 5.0, timestep: 3600.0)).to be_within(0.00001).of(0.0125)
    end

    it "raises when depth is zero or negative" do
      expect { calc.flow_from_depth(depth: 0, timestep: 3600) }
        .to raise_error(SmoFlow::InvalidInput, "Depth must be positive")
    end

    it "raises when timestep is zero or negative" do
      expect { calc.flow_from_depth(depth: 5.0, timestep: 0) }
        .to raise_error(SmoFlow::InvalidInput, "Timestep must be positive")
    end
  end

  describe "#depth_to_intensity" do
    it "converts depth and timestep to intensity in mm/hr" do
      # 5mm over 3600s = 5mm/hr
      expect(calc.depth_to_intensity(depth: 5.0, timestep: 3600.0)).to be_within(0.0001).of(5.0)
    end
  end

  describe "#volume" do
    it "calculates runoff volume in m³" do
      # V = 10 × 0.9 × 1.0 × 5.0 = 45.0
      expect(calc.volume(depth: 5.0)).to be_within(0.0001).of(45.0)
    end
  end

  describe "#flow_ls_from_intensity" do
    it "returns flow in L/s" do
      # 0.125 m³/s × 1000 = 125 L/s
      expect(calc.flow_ls_from_intensity(50.0)).to be_within(0.01).of(125.0)
    end
  end
end
