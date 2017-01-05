defmodule Membrane.PipelineTopologySpec do
  use ESpec, async: true

  describe "when creating new struct" do
    it "should have children field set to nil" do
      %Membrane.PipelineTopology{children: children} = struct(described_module)
      expect(children).to be_nil
    end

    it "should have links field set to nil" do
      %Membrane.PipelineTopology{links: links} = struct(described_module)
      expect(links).to be_nil
    end
  end


  pending ".start_children/1"
end
