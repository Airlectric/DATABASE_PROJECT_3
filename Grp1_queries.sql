 --STUDENT REGISTRATION FOR COURSES TAKES PLACE AUTOMATICALLY
-- ONCE STUDENT HAS REGISTERED FOR A PARTICULAR DEPARTMENT
SELECT * FROM COURSE_ENROLLMENT


--STUDENT REGISTERING FOR EXAMINATION
SELECT register_for_exam('1000000000', 'CPEN 201');
SELECT register_for_exam('1000000000', 'CPEN 203');
SELECT register_for_exam('1000000000', 'SENG 207');

--CHECK TO CONFIRM IF REGISTRATION WAS SUCCESSFULL
SELECT * FROM EXAMINATION_ENROLLMENT

--AS SOON AS STUDENT REGISTERS FOR THE EXAMS, STUDENT ID AND COURSE 
--CODE ARE INPUTED INTO THE EXAMS TABLE AUTOMATICALLY
SELECT * FROM EXAM_RESULT


--UPLOADING OF STUDENT RESULTS
UPDATE exam_result 
SET exam_type = 'First semester',
    exam_date = '2023-03-15',
    ia_marks_obtained = 25,
    exams_marks_obtained = 65.8
WHERE student_id = '1000000000' AND course_code = 'CPEN 201';

UPDATE exam_result 
SET exam_type = 'First semester',
    exam_date = '2023-03-15',
    ia_marks_obtained = 23,
    exams_marks_obtained = 55.8
WHERE student_id = '1000000000' AND course_code = 'CPEN 203';

UPDATE exam_result 
SET exam_type = 'First semester',
    exam_date = '2023-03-15',
    ia_marks_obtained = 20,
    exams_marks_obtained = 63.8
WHERE student_id = '1000000000' AND course_code = 'SENG 207';


--CHECK RESULTS
SELECT * FROM EXAM_RESULT

 --JOIN QUERIES
 
 /* SQL query to retrieve information on the students, their level,
department they belong to and their email*/
SELECT CONCAT(firstname,' ',lastname) as fullname,name,level_of_study,email
FROM student
JOIN department ON student.department_id =  department.id

 /* SQL query to retrieve information on the courses,level,
semester and lectures teaching the course */
SELECT CONCAT(firstname,' ',lastname) as fullname,name,course_code,level,semester
FROM course
JOIN lecturer ON lecturer.department_id =  course.department_id

 /* SQL query to retrieve informantion on student login, failed login attempts,
email,level of study and department  */
SELECT CONCAT(firstname,' ',lastname) as fullname, name,level_of_study,email,failed_login_attempts
FROM Student
JOIN login ON login.user_id =  student.id
JOIN department on department.id=student.department_id

/*SQL query to retrieve informantion on the course timetable,
location and the lecturer teaching the course*/
SELECT CONCAT(firstname,' ',lastname) as fullname,course_id,start_time,end_time,location
FROM lecturer
JOIN timetable_course ON lecturer.department_id = timetable_course.department_id

/*SQL query to retrieve information on the course,course code,
the deparment that offer the course and the level*/
SELECT course.name,course_code,level,department.name
FROM course
JOIN department ON department.id = course.department_id

/*SQL query to retrieve information on lecturers, their ids,
the course they teach and their deparment*/
SELECT Concat(firstname,' ',middlename,' ',lastname)as fullname,
lecturer.id,course.name,department.name
FROM lecturer
JOIN department on lecturer.department_id=department.id
JOIN course ON course.department_id=lecturer.department_id