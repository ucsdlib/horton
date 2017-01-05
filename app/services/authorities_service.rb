module AuthoritiesService
  class << self

    # Returns all edm:Agent
    def find_all_agents
      cols = []
      records = ActiveFedora::Base.where('has_model_ssim:Agent')
      records.each do |rec|
        cols << [rec.label.first, RDF::URI(ActiveFedora::Base.id_to_uri(rec.id))]
      end
      cols 
    end

    def find_agents (label)
      recs = []
      q = "has_model_ssim:Agent AND label_tesim:\"#{label}\""
      records = ActiveFedora::Base.where(q)
      records.each do |rec|
        recs << [rec.label.first, RDF::URI(ActiveFedora::Base.id_to_uri(rec.id))]
      end
      recs 
    end

    # Returns all skos:Concept
    def find_all_subjects
      cols = []
      records = ActiveFedora::Base.where('has_model_ssim:Concept')
      records.each do |rec|
        cols << [rec.label.first, RDF::URI(ActiveFedora::Base.id_to_uri(rec.id))]
      end
      cols 
    end

    # Returns all edm:Place
    def find_all_places
      cols = []
      records = ActiveFedora::Base.where('has_model_ssim:Place')
      records.each do |rec|
        cols << [rec.label.first, RDF::URI(ActiveFedora::Base.id_to_uri(rec.id))]
      end
      cols 
    end

    # find or create authority records
    def find_or_create (model, label)
      mod = Object.const_get(model)
      records = ActiveFedora::Base.where("has_model_ssim:#{model}").select { |rec| rec[:label].first == label }
      records = [mod.create({label: [label]})] if records.first.nil?
      ActiveFedora::Base.id_to_uri(records.first.id)
    end
  end

end
