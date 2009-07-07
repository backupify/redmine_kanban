class KanbansController < ApplicationController
  unloadable
  helper :kanbans
  include KanbansHelper
  
  def show
    @settings = Setting.plugin_redmine_kanban
    @kanban = Kanban.find
    @incoming_issues = @kanban.incoming_issues
    @quick_issues = @kanban.quick_issues
    @backlog_issues = @kanban.backlog_issues
    @selected_issues = @kanban.selected_issues
  end

  def update
    @settings = Setting.plugin_redmine_kanban
    @from = params[:from]
    @to = params[:to]
    @user_id = params[:user_id] != 'null' ? params[:user_id] : nil # Javascript nulls
    @user = User.find_by_id(@user_id) # only needed for user specific views
    Kanban.update_sorted_issues(@to, params[:to_issue], @user_id) if Kanban.kanban_issues_panes.include?(@to)

    saved = Kanban.update_issue_attributes(params[:issue_id], params[:from], params[:to], User.current)

    @kanban = Kanban.find
    @incoming_issues = @kanban.incoming_issues
    @quick_issues = @kanban.quick_issues
    @backlog_issues = @kanban.backlog_issues
    @selected_issues = @kanban.selected_issues
    respond_to do |format|

      if saved
        format.html {
          flash[:notice] = l(:kanban_text_saved)
          redirect_to kanban_path
        }
        format.js {
          render :text => ActiveSupport::JSON.encode({
                                                       'from' => render_pane_to_js(@from),
                                                       'to' => render_pane_to_js(@to)
                                                     })
        }
      else
        format.html {
          flash[:error] = l(:kanban_text_error_saving)
          redirect_to kanban_path
        }
        format.js { 
          render({:text => ({}.to_json), :status => :bad_request})
        }
      end
    end
  end
end
