class Teachers::ClassroomManagerController < ApplicationController
  respond_to :json, :html
  layout 'classroom_manager'
  before_filter :teacher!
  before_filter :authorize!
  layout 'scorebook'
  include ScorebookHelper
  RESULTS_PER_PAGE = 12


  def invite_students
    @classrooms = current_user.classrooms
  end

  def scorebook
    @classrooms = current_user.classrooms - [@classroom]
    @unit = @classroom.units.find(params[:unit_id]) if params[:unit_id]
    #@units = @classroom.units - [@unit]
    @units = ClassroomActivity.includes(:unit).where(classroom: @classroom).map(&:unit).uniq
    @are_all_units_selected = (params[:all_units])

  end



  def lesson_planner

    raw_sql = "
      SELECT 
        a.id as activity_id, 
        a.name as activity_name,
        a.description as activity_description,
        ac.id as activity_classification_id, 
        ac.name as activity_classification_name,
        t.id as topic_id, 
        t.name as topic_name,
        s.id as section_id, 
        s.name as section_name

      FROM activities a
      LEFT JOIN topics t
        ON a.topic_id = t.id
      
      LEFT JOIN activity_classifications ac
        ON a.activity_classification_id = ac.id
      LEFT JOIN sections s
        ON t.section_id = s.id

      WHERE 'production' = ANY(a.flags)

    "

    search_results raw_sql

  end

  def retrieve_classrooms_for_assigning_activities # in response to ajax request
    @activities = Activity.find params[:activities]
    get_classrooms_and_students_for_assigning_activities
    render partial: 'assign', layout: false
  end


  def get_classrooms_and_students_for_assigning_activities
    current_user.classrooms.each do |classroom|
      obj = {
        classroom: classroom,
        students: classroom.students
      }
      ( @classrooms_and_their_students ||= [] ).push obj
    end
  end



  def search_activities


    filters = params['filters']
    filter_string = ""
    if filters['activity_classification'].length > 0
      filter_string << " AND ac.id = #{filters['activity_classification']} "
    end
    if filters['section'].length > 0
      filter_string << " AND s.id = #{filters['section']} "
    end
    if filters['topic'].length > 0
      filter_string << " AND t.id = #{filters['topic']} "
    end

    sort = params['sort']
    sort_string = ""
    
    if sort['field'].length > 0
      field = sort['field']
      asc_or_desc = sort['asc_or_desc']
      # map field to table abbreviation
      # add to sql string
      if field == 'activity_classification'
        field2 = 'ac.name'
      elsif field == 'section'
        field2 = 's.name'
      elsif field == 'topic'
        field2 = 't.name'
      elsif field == 'activity'
        field2 = 'a.name'
      end


      sort_string = " ORDER BY #{field2} #{asc_or_desc}"

    end


    raw_sql = "
      SELECT
        a.id as activity_id, a.name as activity_name,
        a.description as activity_description,
        ac.id as activity_classification_id, ac.name as activity_classification_name,
        t.id as topic_id, t.name as topic_name,
        s.id as section_id, s.name as section_name

      FROM activities a
      LEFT JOIN topics t
        ON a.topic_id = t.id

      LEFT JOIN activity_classifications ac
        ON a.activity_classification_id = ac.id

      LEFT JOIN sections s
        ON t.section_id = s.id

      WHERE
           (a.name ILIKE '%#{params[:search_query]}%'
        OR t.name ILIKE '%#{params[:search_query]}%')
        AND 'production' = ANY(a.flags)
        #{filter_string}
        #{sort_string}

    "
    search_results raw_sql

    render json: {
      activities: @activities,
      activity_classifications: @activity_classifications,
      topics: @topics,
      sections: @sections,
      number_of_pages: @number_of_pages,
      active_page: @active_page,
    }

  end



  private

  def transform_app_name ele
    case ele['activity_classification_name']
    when 'Practice Questions'
      new_name = 'Quill Grammar'
    when 'Story'
      new_name = 'Quill Proofreader'
    end
    ele['activity_classification_name'] =  new_name
    ele
  end



  def search_results raw_sql
    db_result = ActiveRecord::Base.connection.execute(raw_sql)
    
    db_result = db_result.map{|ele| transform_app_name(ele)}

    @activity_classifications = db_result.map{|ele| {activity_classification_id: ele['activity_classification_id'], activity_classification_name: ele['activity_classification_name']}}.reject{|ele| ele[:activity_classification_name].nil?}.uniq
    @topics = db_result.map{|ele| {topic_id: ele['topic_id'], topic_name: ele['topic_name']}}.reject{|ele| ele[:topic_name].nil?}.uniq
    @sections = db_result.map{|ele| {section_id: ele['section_id'], section_name: ele['section_name']}}.reject{|ele| ele[:section_name].nil?}.uniq

    db_result = db_result.map{|ele| ele.merge({image_path: view_context.image_path(image_for_activity_classification_by_id(ele['activity_classification_id'].to_i))})}
    @activities = db_result.sort{|x,y| x[:activity_name] <=> y[:activity_name]}

    @number_of_pages = @activities.count/RESULTS_PER_PAGE
    @active_page = 1
    @results_per_page = RESULTS_PER_PAGE
   
  end



  def authorize!
    if !params[:classroom_id].nil?
      @classroom = Classroom.find(params[:classroom_id])
    end
    @classroom ||= current_user.classrooms.first
    auth_failed unless @classroom.teacher == current_user
  end



end




