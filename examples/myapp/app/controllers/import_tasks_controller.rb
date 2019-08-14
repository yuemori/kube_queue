require 'csv'

class ImportTasksController < ApplicationController
  rescue_from(StandardError) do |e|
    logger.error e

    redirect_to({ controller: :tasks, action: :index }, alert: 'Task import was failure')
  end

  def create
    file = params[:upload_file]

    csv = CSV.parse(file.read)

    ImportTaskJob.perform_later(csv)

    respond_to do |format|
      format.html { redirect_to({ controller: :tasks, action: :index }, notice: 'Task import was successfully started.') }
    end
  end
end
