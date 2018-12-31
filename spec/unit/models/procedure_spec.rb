# frozen_string_literal: true

RSpec.describe Procedure do
  fixtures :cases

  def valid_attributes
    {
      case: cases(:fernando_left_hip),
      date: Date.today.to_s,
      type: :total_knee_replacement,
      title: "A great operation",
      version: :v1,
      providers: { "provider_id_1" => { role: :primary } },
      sites: [{ body_part: "knee", side: "L" }]
    }
  end

  def valid_attributes_without(key)
    valid_attributes.reject { |k, _| k == key }
  end

  describe "validates" do
    it "is valid with valid_attributes" do
      expect { Procedure.create(valid_attributes) }.to change(Procedure, :count)
    end

    it "case is required" do
      expect {
        Procedure.create(valid_attributes_without(:case))
      }.to_not change(Procedure, :count)
    end

    it "type is required" do
      expect {
        Procedure.create(valid_attributes_without(:type))
      }.to_not change(Procedure, :count)
    end

    it "version is required" do
      expect {
        Procedure.create(valid_attributes_without(:version))
      }.to_not change(Procedure, :count)
    end

    it "at least one provider is required" do
      expect {
        Procedure.create(valid_attributes_without(:providers))
      }.to_not change(Procedure, :count)

      attrs = valid_attributes.merge(providers: [])
      expect { Procedure.create(attrs) }.to_not change(Procedure, :count)
    end

    it "providers are well-formed" do
      attrs = valid_attributes.merge(providers: "junk")
      expect { Procedure.create(attrs) }.to_not change(Procedure, :count)

      attrs = valid_attributes.merge(providers: %w[junk stuff])
      expect { Procedure.create(attrs) }.to_not change(Procedure, :count)

      # punting on this one for now...
      # attrs = valid_attributes.merge(providers: {{this: :is} => "more junk" })
      # expect { Procedure.create(attrs) }.to_not change(Procedure, :count)
    end

    context "conformance to type definition" do
      # TODO
      # these tests are coupled to the total_knee_replacement definition for now
      # improve them by writing a new config file and asserting on that

      it "is not valid without required inputs" do
        skip("failing for now due to possible bug in json-schema gem?")
        expect {
          Procedure.create(valid_attributes_without(:sites))
        }.to_not change(Procedure, :count)
      end

      it "is not valid if nested requirements are absent" do
        attrs = valid_attributes.merge(sites: [])
        expect {
          Procedure.create(attrs)
        }.to_not change(Procedure, :count)
      end

      it "is not valid if nested requirements are invalid data type" do
        attrs = valid_attributes.merge(sites: "junk")
        expect {
          Procedure.create(attrs)
        }.to_not change(Procedure, :count)
      end
    end
  end

  it "serializes metadata about the procedure" do
    skip("this is disabled for now since the serializer doesn't use Hashie anymore; need to figure out the correct design for this")
    procedure = Procedure.create!(valid_attributes)

    expect(procedure.title).to eq("A great operation")
    expect(procedure.sites.first.body_part).to eq("knee")
    expect(procedure.sites.first.side).to eq("L")
    expect(procedure.providers.provider_id_1.role).to eq("primary")
  end
end
