(0..5).each do |n|
  login = "tlogin#{n}"
  u = User.find_by_login(login)
  u.portal_student.learners.each do |learner|
    learner.bucket_logger.bucket_log_items.destroy_all
    learner.bucket_logger.bucket_contents.destroy_all
    learner.open_responses.destroy_all
    learner.multiple_choices.destroy_all
    learner.learner_activities.destroy_all
    learner.report_learner.destroy
  end
end
