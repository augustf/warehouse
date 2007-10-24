class BrowserController < ApplicationController
  before_filter :find_node
  before_filter :repository_member_required
  
  caches_action_content :index
  
  helper_method :current_revision, :current_changeset, :previous_changeset, :next_changeset

  def index
    @bookmark   = Bookmark.new(:path => @node.path)
    @changesets = current_repository.changesets.find_all_by_path(@node.path, :limit => 5, :order => 'changesets.changed_at desc')
    render :action => @node.node_type.downcase
  end
  
  def blame
    @bookmark   = Bookmark.new(:path => @node.path)
    @changesets = current_repository.changesets.find_all_by_path(@node.path, :limit => 5, :order => 'changesets.changed_at desc')
  end
  
  def text
    if @node.dir?
      render :layout => false, :content_type => Mime::TEXT
    else
      render :text => @node.content, :content_type => Mime::TEXT
    end
  end

  def raw
    if @node.dir?
      render :layout => false, :content_type => Mime::TEXT
    elsif content = @node.content
      send_data content, :disposition => 'inline', :content_type => @node.mime_type
    else
      head :not_found
    end
  end

  protected
    def repository_member_required
      repository_member? || status_message(:error, "You must be a member of this repository to visit this page.", "browser/error")
    end

    def find_node
      @revision = params[:rev][1..-1].to_i if params[:rev]
      @node     = current_repository.node(params[:paths] * '/', @revision)
    end
    
    def current_changeset
      @current_changeset ||= current_repository.changesets.find_latest_changeset(@node.path, @revision)
    end

    def previous_changeset
      @previous_changeset ||= current_repository.changesets.find_by_path(@node.path, :conditions => ['changed_at < ?', current_changeset.changed_at], :order => 'changesets.changed_at desc')
    end
    
    def next_changeset
      @next_changeset ||= current_repository.changesets.find_by_path(@node.path, :conditions => ['changed_at > ?', current_changeset.changed_at], :order => 'changesets.changed_at')
    end
end
