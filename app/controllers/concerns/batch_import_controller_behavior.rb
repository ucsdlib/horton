module BatchImportControllerBehavior
  extend ActiveSupport::Concern
  include Hydra::Controller::ControllerBehavior
  include Hyrax::WorksControllerBehavior

  included do
    self.work_form_service = BatchImportFormService
    self.curation_concern_type = work_form_service.form_class.model_class
  end

  def create
    authenticate_user!
    create_update_job
    flash[:notice] = t('hyrax.works.new.after_create_html', application_name: view_context.application_name)
    redirect_after_update
  end

  # Gives the class of the form.
  class BatchImportFormService < Hyrax::WorkFormService
    def self.form_class(_ = nil)
      ::BatchImportForm
    end
  end

  protected

    def redirect_after_update
      if uploading_on_behalf_of?
        redirect_to hyrax.dashboard_shares_path
      else
        redirect_to hyrax.dashboard_works_path
      end
    end

    def create_update_job
      log = Hyrax::BatchCreateOperation.create!(user: current_user, operation_type: "Batch Imports")

      uploaded_files = params.fetch(:uploaded_files, [])
      selected_files = params.fetch(:selected_files, {}).values
      create_job uploaded_files, selected_files, log
    end

    def create_job(uploaded_files, selected_files, log)
      browse_everything_urls = uploaded_files & selected_files.map { |f| f[:url] }

      # we need the hash of files with url and file_name
      browse_everything_files = selected_files.select { |v| uploaded_files.include?(v[:url]) }

      # clean up the parameters for file upload
      form_attributes = sanitize_file_upload_parms attributes_for_actor

      source_file = write_source_file(params[:source_metadata], params[:source_metadata].original_filename)
      import_template = Rails.root.join("imports", "object_import_template.xlsx").to_s

      BatchImportJob.perform_later(current_user, source_file,
                                   uploaded_files - browse_everything_urls,
                                   browse_everything_files,
                                   form_attributes.to_h,
                                   import_template,
                                   log)
    end

    # clean up the parameters for file upload
    def sanitize_file_upload_parms(attributes)
      attributes.delete :uploaded_files if attributes.key? :uploaded_files
      attributes.delete :remote_files if attributes.key? :remote_files
      attributes
    end

    def uploading_on_behalf_of?
      params.fetch(hash_key_for_curation_concern).key?(:on_behalf_of)
    end

    def write_source_file(file_upload, file_name)
      tmp_file = "#{Tempfile.new('source').path}.#{file_name}"
      FileUtils.mv file_upload.tempfile, tmp_file
      tmp_file
    end
end
