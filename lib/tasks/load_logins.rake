# namespace :db do

#   desc "load user data from csv"
#   task :load_csv_task  => :environment do

#       s = Student.new(
#         :admission_no => row[0],
#         :class_roll_no => row[1],     # class roll no.
#         :admission_date => row[2],

#         :first_name => row[3],
#         :middle_name => row[4],
#         :last_name => row[5],

#         :batch_id => row[6],
#         :date_of_birth => row[7],
#         :gender => row[8],
#         :blood_group => row[9],
#         :birth_place => row[10],
#         :nationality_id => row[11],
#         :language => row[12],
#         :religion => row[13],
#         :student_category_id => row[14],

#         :address_line1 => row[15],
#         :address_line2 => row[16],
#         :city => row[17],
#         :state => row[18],
#         :pin_code => row[19],
#         :country_id => row[20],

#         :phone1 => row[21],
#         :phone2 => row[22],
#         :email => row[23]

#       )

#     s.save
#     end
#   end
# end