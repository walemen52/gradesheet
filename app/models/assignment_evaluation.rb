# This model contains the evaluations for each assignment, by student.  It is
# the students "grade" for an assignment, if you will.
class AssignmentEvaluation < ActiveRecord::Base
  before_validation :massage_points_earned
  after_save :invalidate_cache

	belongs_to :student
	belongs_to :assignment

	validates_existence_of :student
	validates_existence_of :assignment

  # TODO: make sure there can only be one grade per student/assignment
  #	validates_uniqueness_of :student_id, :scope => [:assignment_id]
  #	validates_uniqueness_of :assignment_id, :scope => [:student_id]

	validates_numericality_of	:points_earned, :allow_nil => :true, 
    :greater_than_or_equal_to => 0.0, :unless => :valid_points?

  # Calculate the points earned based on the presence of 'magic' characters
  def points_earned_as_number
    case self[:points_earned]
    when 'E'  # Excused assignment (grade is ignored)
      points = nil
    when 'M'  # Missing assignment (student gets no credit)
      points = 0.0
    else
      points = self[:points_earned]
    end
  
    return points
  end

  def points_desc
    case self[:points_earned]
    when 'E'
      description = 'Excused'
    when 'M'
      description = 'Missing'
    else
      description = ''
    end
    
    return description
  end
  
  private
  
	# There are certain 'magic' characters that can be substituted for a number
	# grade.  This method makes sure that the user only enters valid ones.
	#
	# * 'E' = Excused assignment (assignment is not counted)
	# * 'M' = Missing assignment (student gets no credit)
	def valid_points?
	  ['E', 'M'].include?(self.points_earned) ||
      (points_earned.is_a?(Numeric) && (points_earned.to_f == points_earned.to_f.abs))
	end

  def massage_points_earned
    self.points_earned = self.points_earned.to_f.abs  if points_earned.is_a?(Numeric)
    self.points_earned = self.points_earned.upcase    if points_earned.is_a?(String)
  end

  # The course-term model caches its final score, so when we change/update an
  # assignments grade then we have to remove the cache so that it will be regenerated
  # the next time its needed.
  def invalidate_cache
    Rails.cache.delete("#{self.assignment.course_term.id}|#{self.student.id}")
  end
end
