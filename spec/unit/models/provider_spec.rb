# frozen_string_literal: true

RSpec.describe Provider do
  fixtures :providers, :procedures, :teams

  it "can belong to a team" do
    provider = providers(:alex)
    team = teams(:op_good)

    team.providers << provider
    expect(team.reload.providers).to include(provider)
    expect(provider.reload.teams).to include(team)
  end

  it "can have many procedures" do
    provider = providers(:alex)
    procedure1 = procedures(:fernando_left_hip_transplant)
    procedure2 = procedures(:silvia_right_foot_correction)

    expect(provider.procedures).to be_empty

    procedure1.providers << provider
    procedure2.providers << provider

    expect(procedure1.reload.providers).to include(provider)
    expect(procedure2.reload.providers).to include(provider)
    expect(provider.reload.procedures).to match([procedure1, procedure2])
  end
end
