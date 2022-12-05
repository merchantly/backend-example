module DescribedViewSupport
  extend ActiveSupport::Concern

  included do
    def described_file
      # {:execution_result=>#<RSpec::Core::Example::ExecutionResult:0x007f2505d4a248>,
      # :block=> ##<Proc:0x007f2505d4a720@/home/danil/code/merchantly/spec/views/operator/properties/_property.html.haml_spec.rb:3>,
      # :description_args=>["operator/properties/_property"],
      # :description=>"operator/properties/_property",
      # :full_description=>"operator/properties/_property",
      # :described_class=>nil,
      # :file_path=>"./spec/views/operator/properties/_property.html.haml_spec.rb",
      # :line_number=>3,
      # :location=>"./spec/views/operator/properties/_property.html.haml_spec.rb:3",
      # :type=>:view}

      metadata = self.class.metadata[:parent_example_group] || self.class.metadata
      metadata[:description]
    end

    def render_described(args = {})
      render args.merge template: described_file
    end
  end
end
