require 'csv'

class ImportTasksController < ApplicationController
  rescue_from(StandardError) do |e|
    logger.error e

    redirect_to({ controller: :tasks, action: :index }, alert: 'Task import was failure')
  end

  def create
    file = params[:upload_file]

    tasks = CSV.parse(file.read).map do |row|
      Task.new(name: row[0], state: row[1])
    end

    ImportTaskJob.perform_later(tasks)

    respond_to do |format|
      format.html { redirect_to({ controller: :tasks, action: :index }, notice: 'Task import was successfully started.') }
    end
  end
end
