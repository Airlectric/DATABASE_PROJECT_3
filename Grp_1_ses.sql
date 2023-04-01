
CREATE TABLE ADMIN (
    id VARCHAR(10) PRIMARY KEY,
    firstname VARCHAR(200) NOT NULL,
    middlename VARCHAR(200),
    lastname VARCHAR(250),
    email VARCHAR(258),
    telephone_number VARCHAR(20)
);


--auto id generator for any new admin
CREATE SEQUENCE admin_id_seq
  START 20000
  INCREMENT 1;

CREATE OR REPLACE FUNCTION set_admin_id()
  RETURNS TRIGGER AS
$$
BEGIN
  NEW.id := 'admin' || lpad(nextval('lecturer_id_seq')::text, 5, '0');
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER set_admin_id_trigger
  BEFORE INSERT OR UPDATE ON ADMIN
  FOR EACH ROW
  EXECUTE PROCEDURE set_admin_id();

--generating email for each admin
CREATE OR REPLACE FUNCTION set_admin_email()
  RETURNS TRIGGER AS
$$
BEGIN
  NEW.email := lower(substr(NEW.firstname, 1, 3) || substr(NEW.lastname, 1, 3) || '@st.ug.edu.gh');
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER set_admin_email_trigger
  BEFORE INSERT OR UPDATE OF firstname, lastname ON ADMIN
  FOR EACH ROW
  EXECUTE PROCEDURE set_admin_email();


CREATE TABLE admin_audit (
    audit_id SERIAL PRIMARY KEY,
    audit_action CHAR(1) NOT NULL,
    audit_timestamp TIMESTAMP NOT NULL,
    id VARCHAR(10),
    firstname VARCHAR(200),
    middlename VARCHAR(200),
    lastname VARCHAR(250),
    email VARCHAR(255),
    telephone_number VARCHAR(20)
);


CREATE OR REPLACE FUNCTION admin_audit_function() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO admin_audit (audit_action, audit_timestamp, id, firstname,middlename,lastname, email, telephone_number)
        VALUES ('D', NOW(), OLD.id,OLD.firstname,OLD.middlename,OLD.lastname,OLD.email, OLD.telephone_number);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO admin_audit (audit_action, audit_timestamp, id,firstname,middlename,lastname,email, telephone_number)
        VALUES ('U', NOW(), NEW.id,NEW.firstname,NEW.middlename,NEW.lastname,NEW.email, NEW.telephone_number);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO admin_audit (audit_action, audit_timestamp, id,firstname,middlename,lastname,email, telephone_number)
        VALUES ('I', NOW(), NEW.id,NEW.firstname,NEW.middlename,NEW.lastname,NEW.email, NEW.telephone_number);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER admin_audit_trigger
AFTER INSERT OR UPDATE OR DELETE
ON ADMIN
FOR EACH ROW
EXECUTE PROCEDURE admin_audit_function();


CREATE TABLE STUDENT (
    id VARCHAR(10) PRIMARY KEY,
    firstname VARCHAR(200) NOT NULL,
    middlename VARCHAR(200),
    lastname VARCHAR(200) NOT NULL,
    date_of_birth DATE,
    email VARCHAR(200),
    telephone_number VARCHAR(20),
    department_id INTEGER,
    level_of_study INTEGER
);

CREATE SEQUENCE student_id_seq START 1000000000;

CREATE OR REPLACE FUNCTION set_student_id()
  RETURNS TRIGGER AS
$$
BEGIN
  NEW.id := lpad(nextval('student_id_seq')::text, 10, '0');
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER set_student_id_trigger
  BEFORE INSERT ON STUDENT
  FOR EACH ROW
  EXECUTE PROCEDURE set_student_id();

CREATE OR REPLACE FUNCTION set_student_email()
  RETURNS TRIGGER AS
$$
BEGIN
  NEW.email := lower(substr(NEW.firstname, 1, 3) || substr(NEW.lastname, 1, 3) || '@st.ug.edu.gh');
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER set_student_email_trigger
  BEFORE INSERT OR UPDATE OF firstname, lastname ON STUDENT
  FOR EACH ROW
  EXECUTE PROCEDURE set_student_email();


CREATE TABLE STUDENT_AUDIT (
    id SERIAL,
    student_id VARCHAR(10) REFERENCES STUDENT(id),
    changed_by VARCHAR(255),
    changed_at TIMESTAMP,
    operation VARCHAR(10),
    firstname VARCHAR(200),
    middlename VARCHAR(200),
    lastname VARCHAR(200),
    date_of_birth DATE,
    email VARCHAR(200),
    telephone_number VARCHAR(20),
    department_id INTEGER,
    level_of_study INTEGER
);

CREATE OR REPLACE FUNCTION student_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO STUDENT_AUDIT (student_id, changed_by, changed_at,operation, firstname,middlename,lastname, date_of_birth, email, telephone_number, department_id,level_of_study)
        VALUES (OLD.id, USER, NOW(), 'D',OLD.firstname,OLD.middlename,OLD.lastname,OLD.date_of_birth, OLD.email, OLD.telephone_number, OLD.department_id,OLD.level_of_study);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO STUDENT_AUDIT (student_id, changed_by, changed_at, operation, firstname,middlename,lastname, date_of_birth, email, telephone_number,OLD.department_id,level_of_study)
        VALUES (NEW.id, USER, NOW(), 'U',NEW.firstname,NEW.middlename,NEW.lastname,NEW.date_of_birth, NEW.email, NEW.telephone_number, NEW.department_id,NEW.level_of_study);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO STUDENT_AUDIT (student_id, changed_by, changed_at, operation, firstname,middlename,lastname,date_of_birth, email, telephone_number, department_id,level_of_study)
        VALUES (NEW.id, USER, NOW(), 'I', NEW.firstname,NEW.middlename,NEW.lastname,NEW.date_of_birth, NEW.email, NEW.telephone_number,NEW.department_id ,NEW.level_of_study);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER student_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON STUDENT
FOR EACH ROW
EXECUTE PROCEDURE student_audit();


CREATE TABLE DEPARTMENT (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE DEPARTMENT_AUDIT (
    id SERIAL PRIMARY KEY,
    department_id INTEGER NOT NULL REFERENCES DEPARTMENT(id),
    action VARCHAR(20) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    old_name VARCHAR(255),
    new_name VARCHAR(255)
);


CREATE OR REPLACE FUNCTION department_audit() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO DEPARTMENT_AUDIT (department_id, action, timestamp, new_name)
        VALUES (NEW.id, 'INSERT', NOW(),NEW.name);
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO DEPARTMENT_AUDIT (department_id, action, timestamp,old_name, new_name)
        VALUES (OLD.id, 'UPDATE', NOW(), OLD.name, NEW.name);
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO DEPARTMENT_AUDIT (department_id, action, timestamp,old_name)
        VALUES (OLD.id, 'DELETE', NOW(),OLD.name);
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER department_audit_insert
AFTER INSERT OR UPDATE OR DELETE ON DEPARTMENT
FOR EACH ROW
EXECUTE PROCEDURE department_audit();


CREATE TABLE COURSE (
id SERIAL primary key,
level int not null, 
course_code varchar(300),
name VARCHAR(255) NOT NULL,
semester int NOT NULL,
credit_hours int not null, 
department_id INTEGER REFERENCES DEPARTMENT(id) 
); 



CREATE TABLE COURSE_AUDIT (
    id SERIAL ,
    course_id INTEGER NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    level int,
    course_code varchar(300),
    name VARCHAR(255),
    semester int,
    credit_hours int,
    department_id INTEGER
);


CREATE OR REPLACE FUNCTION audit_course_changes()
 RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO COURSE_AUDIT (course_id, event_type, event_timestamp, level, course_code, name, semester, credit_hours, department_id)
        VALUES (OLD.id, TG_OP, NOW(), OLD.level, OLD.course_code, OLD.name, OLD.semester, OLD.credit_hours, OLD.department_id);
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO COURSE_AUDIT (course_id, event_type, event_timestamp, level, course_code, name, semester, credit_hours, department_id)
        VALUES (NEW.id, TG_OP, NOW(), NEW.level, NEW.course_code, NEW.name, NEW.semester, NEW.credit_hours, NEW.department_id);
    ELSE
        INSERT INTO COURSE_AUDIT (course_id, event_type, event_timestamp, level, course_code, name, semester, credit_hours, department_id)
        VALUES (NEW.id, TG_OP, NOW(), NEW.level, NEW.course_code, NEW.name, NEW.semester, NEW.credit_hours, NEW.department_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER course_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON COURSE
FOR EACH ROW EXECUTE PROCEDURE audit_course_changes();




CREATE TABLE LECTURER (
    id VARCHAR(10) PRIMARY KEY,
    firstname VARCHAR(255) NOT NULL,
    middlename VARCHAR(255),
    lastname VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    department_id INTEGER REFERENCES DEPARTMENT(id)
);


CREATE SEQUENCE lecturer_id_seq
  START 10000
  INCREMENT 1;

CREATE OR REPLACE FUNCTION set_lecturer_id()
  RETURNS TRIGGER AS
$$
BEGIN
  NEW.id := 'staff' || lpad(nextval('lecturer_id_seq')::text, 5, '0');
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER set_lecturer_id_trigger
  BEFORE INSERT OR UPDATE ON LECTURER
  FOR EACH ROW
  EXECUTE PROCEDURE set_lecturer_id();

--generating email for each lecturer
CREATE OR REPLACE FUNCTION set_lecturer_email()
  RETURNS TRIGGER AS
$$
BEGIN
  NEW.email := lower(substr(NEW.firstname, 1, 3) || substr(NEW.lastname, 1, 3) || '@st.ug.edu.gh');
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER set_lecturer_email_trigger
  BEFORE INSERT OR UPDATE OF firstname, lastname ON LECTURER
  FOR EACH ROW
  EXECUTE PROCEDURE set_lecturer_email();



CREATE TABLE LECTURER_AUDIT (
    id VARCHAR(10),
    lecturer_id VARCHAR(10) ,
    firstname VARCHAR(255) ,
    middlename VARCHAR(255),
    lastname VARCHAR(255) ,
    email VARCHAR(255),
    department_id INTEGER REFERENCES DEPARTMENT(id),
    event_type VARCHAR(10) NOT NULL,
    event_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION lecturer_audit()
RETURNS TRIGGER
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO LECTURER_AUDIT (lecturer_id, firstname, middlename, lastname, email,department_id, event_type)
        VALUES (NEW.id, NEW.firstname, NEW.middlename, NEW.lastname, NEW.email,NEW.department_id, 'INSERT');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO LECTURER_AUDIT (lecturer_id, firstname, middlename, lastname, email,department_id, event_type)
        VALUES (OLD.id, OLD.firstname, OLD.middlename, OLD.lastname, OLD.email, OLD.department_id, 'DELETE');
        INSERT INTO LECTURER_AUDIT (lecturer_id, firstname, middlename, lastname, email,department_id, event_type)
        VALUES (NEW.id, NEW.firstname, NEW.middlename, NEW.lastname, NEW.email,NEW.department_id, 'INSERT');
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO LECTURER_AUDIT (lecturer_id, firstname, middlename, lastname, email,department_id, event_type)
        VALUES (OLD.id, OLD.firstname, OLD.middlename, OLD.lastname, OLD.email,OLD.department_id, 'DELETE');
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER lecturer_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON LECTURER
FOR EACH ROW
EXECUTE PROCEDURE lecturer_audit();

CREATE TABLE TIMETABLE (
    id SERIAL PRIMARY KEY,
    department_id INTEGER REFERENCES DEPARTMENT(id),
    semester VARCHAR(20),
    year INTEGER,
    start_date DATE,
    end_date DATE
);


CREATE TABLE TIMETABLE_AUDIT (
    id SERIAL PRIMARY KEY,
    operation TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_name TEXT NOT NULL DEFAULT current_user,
    department_id INTEGER,
    semester VARCHAR(20),
    year INTEGER,
    start_date DATE,
    end_date DATE
);


CREATE OR REPLACE FUNCTION timetable_audit() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO TIMETABLE_AUDIT (operation, department_id, semester, year, start_date, end_date)
        VALUES ('DELETE', OLD.department_id, OLD.semester, OLD.year, OLD.start_date, OLD.end_date);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO TIMETABLE_AUDIT (operation, department_id, semester, year, start_date, end_date)
        VALUES ('UPDATE', NEW.department_id, NEW.semester, NEW.year, NEW.start_date, NEW.end_date);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO TIMETABLE_AUDIT (operation, department_id, semester, year, start_date, end_date)
        VALUES ('INSERT', NEW.department_id, NEW.semester, NEW.year, NEW.start_date, NEW.end_date);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER timetable_audit_trigger AFTER INSERT OR UPDATE OR DELETE
ON TIMETABLE FOR EACH ROW
EXECUTE PROCEDURE timetable_audit();


CREATE TABLE LECTURER_COURSE(
    id SERIAL PRIMARY KEY,
    lecturer_id VARCHAR(10) REFERENCES LECTURER(id),
    course_id VARCHAR(10)
);

CREATE TABLE LECTURER_COURSE_AUDIT (
    id SERIAL PRIMARY KEY,
    lecturer_course_id INTEGER,
    lecturer_id VARCHAR(10),
    course_id VARCHAR(10),
    event_type VARCHAR(10),
    event_timestamp TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION lecturer_course_audit()
RETURNS TRIGGER AS
$$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO LECTURER_COURSE_AUDIT (lecturer_course_id, lecturer_id, course_id, event_type)
        VALUES (NEW.id, NEW.lecturer_id, NEW.course_id, 'INSERT');
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO LECTURER_COURSE_AUDIT (lecturer_course_id, lecturer_id, course_id, event_type)
        VALUES (NEW.id, NEW.lecturer_id, NEW.course_id, 'UPDATE');
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO LECTURER_COURSE_AUDIT (lecturer_course_id, lecturer_id, course_id, event_type)
        VALUES (OLD.id, OLD.lecturer_id, OLD.course_id, 'DELETE');
    END IF;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER lecturer_course_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON LECTURER_COURSE
FOR EACH ROW
EXECUTE PROCEDURE lecturer_course_audit();

 create TABLE exam_timetable (
    id SERIAL,
    course_code VARCHAR(300),
    semester VARCHAR(20),
    year INTEGER,
    date DATE,
    location VARCHAR(5),
    start_time time,
    end_time time
    
);


CREATE TABLE exam_timetable_audit (
    id SERIAL PRIMARY KEY,
    operation TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_name TEXT NOT NULL DEFAULT current_user,
    course_code varchar(200),
    semester VARCHAR(20),
    year INTEGER,
    date DATE,
    location VARCHAR(5),
    start_time time,
    end_time time
);

	  
CREATE OR REPLACE FUNCTION exam_timetable_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO exam_timetable_audit (operation, course_code, semester, year,date, location,start_time,end_time)
        VALUES ('DELETE', OLD.course_code, OLD.semester, OLD.year, OLD.date, OLD.location,old.start_time,old.end_time);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO exam_timetable_audit (operation, course_code, semester, year,date,location,start_time,end_time )
        VALUES ('UPDATE', NEW.course_code, NEW.semester, NEW.year, NEW.date, NEW.location,new.start_time,new.end_time);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO exam_timetable_audit (operation, course_code, semester, year,date,location,start_time,end_time )
        VALUES ('INSERT', NEW.course_code, NEW.semester, NEW.year, NEW.date, NEW.location,new.start_time,new.end_time);
        RETURN NEW;
    END IF;
    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER exam_timetable_audit_trigger
AFTER INSERT OR UPDATE OR DELETE
ON exam_TIMETABLE FOR EACH ROW
EXECUTE PROCEDURE exam_timetable_audit();

CREATE TABLE COURSE_ENROLLMENT (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(10) REFERENCES STUDENT(id),
    course_id VARCHAR(255)
    
);

CREATE OR REPLACE FUNCTION enroll_student_into_courses()
RETURNS TRIGGER AS $$
BEGIN

    IF NEW.level_of_study IN (100, 200, 300, 400) AND NEW.department_id IN (1, 2, 3, 4, 5) THEN
      
        INSERT INTO COURSE_ENROLLMENT(student_id, course_id)
        SELECT NEW.id, course_code FROM COURSE
        WHERE level = NEW.level_of_study AND semester = 1 AND COURSE.department_id = NEW.department_id;
    END IF;

    INSERT INTO COURSE_ENROLLMENT (student_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enroll_student_trigger
AFTER INSERT OR UPDATE ON STUDENT
FOR EACH ROW
EXECUTE PROCEDURE enroll_student_into_courses();



CREATE TABLE COURSE_ENROLLMENT_AUDIT (
  audit_id SERIAL PRIMARY KEY,
  course_enrollment_id INTEGER,
  student_id VARCHAR(10),
  course_id VARCHAR(255),
  event_type VARCHAR(10),
  event_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  user_name VARCHAR(255)
);


CREATE OR REPLACE FUNCTION audit_course_enrollment() RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO COURSE_ENROLLMENT_AUDIT (course_enrollment_id, student_id, course_id, event_type, user_name)
    VALUES (NEW.id,NEW.student_id,NEW.course_id, 'INSERT', current_user);
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO COURSE_ENROLLMENT_AUDIT (course_enrollment_id, student_id, course_id, event_type, user_name)
    VALUES (NEW.id, NEW.student_id, NEW.course_id, 'UPDATE', current_user);
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO COURSE_ENROLLMENT_AUDIT (course_enrollment_id, student_id, course_id, event_type, user_name)
    VALUES (OLD.id,OLD.student_id, OLD.course_id, 'DELETE', current_user);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER course_enrollment_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON COURSE_ENROLLMENT
FOR EACH ROW EXECUTE PROCEDURE audit_course_enrollment();

CREATE TABLE EXAMINATION_ENROLLMENT (
    id SERIAL PRIMARY KEY,
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    student_id VARCHAR(10) REFERENCES STUDENT(id),
    course_code VARCHAR(300) 
);

CREATE OR REPLACE FUNCTION register_for_exam(
  student_id VARCHAR(10),
  course_code VARCHAR(300)
) RETURNS VOID AS $$
DECLARE
  course_id INTEGER;
BEGIN
  SELECT id INTO course_id FROM course WHERE course.course_code = register_for_exam.course_code;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Course not found: %', course_code;
  END IF;

  INSERT INTO examination_enrollment(student_id, course_code) VALUES($1, $2);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_examination_enrollment()
  RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO examination_enrollment_audit (
    action_type,
    action_timestamp,
    student_id,
    course_code,
    user_id
  )
  VALUES (
    'INSERT',
    CURRENT_TIMESTAMP,
    NEW.student_id,
    NEW.course_code,
    CURRENT_USER
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE examination_enrollment_audit (
    id SERIAL PRIMARY KEY,
    action_type VARCHAR(10) NOT NULL,
    action_timestamp TIMESTAMP NOT NULL,
    student_id VARCHAR(10) NOT NULL,
    course_code VARCHAR(300) NOT NULL,
    user_id VARCHAR(100) NOT NULL
);

CREATE TRIGGER examination_enrollment_audit_trigger
  AFTER INSERT ON EXAMINATION_ENROLLMENT
  FOR EACH ROW
  EXECUTE PROCEDURE audit_examination_enrollment();

-- to register for a course insert the student id and the course code, there will --be queries relating to this in the query file.
--SELECT register_for_exam('', '');

CREATE TABLE TIMETABLE_COURSE (
    id SERIAL PRIMARY KEY,
    timetable_id INTEGER,
    department_id INTEGER REFERENCES DEPARTMENT(id),
    course_id VARCHAR(10),
    start_time TIME,
    end_time TIME,
    day_of_week VARCHAR(20),
    location VARCHAR(255)
);

CREATE TABLE TIMETABLE_COURSE_AUDIT (
    id SERIAL PRIMARY KEY,
    changed_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255),
    action VARCHAR(20) NOT NULL,
    timetable_id INTEGER,
    department_id INTEGER,
    course_id VARCHAR(10),
    start_time TIME,
    end_time TIME,
    day_of_week VARCHAR(20),
    location VARCHAR(255)
);

CREATE OR REPLACE FUNCTION audit_timetable_course() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO TIMETABLE_COURSE_AUDIT (changed_by, action, timetable_id,department_id,course_id, start_time, end_time, day_of_week, location)
        VALUES (USER, 'DELETE', OLD.timetable_id,NEW.department_id ,OLD.course_id, OLD.start_time, OLD.end_time, OLD.day_of_week, OLD.location);
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO TIMETABLE_COURSE_AUDIT (changed_by, action, timetable_id,department_id, course_id, start_time, end_time, day_of_week, location)
        VALUES (USER, 'UPDATE', NEW.timetable_id,NEW.department_id ,NEW.course_id, NEW.start_time, NEW.end_time, NEW.day_of_week, NEW.location);
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO TIMETABLE_COURSE_AUDIT (changed_by, action, timetable_id,department_id,course_id, start_time, end_time, day_of_week, location)
        VALUES (USER, 'INSERT', NEW.timetable_id,NEW.department_id ,NEW.course_id, NEW.start_time, NEW.end_time, NEW.day_of_week, NEW.location);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_timetable_course_trigger
AFTER INSERT OR UPDATE OR DELETE ON TIMETABLE_COURSE
FOR EACH ROW EXECUTE PROCEDURE audit_timetable_course();

CREATE TABLE EXAM_RESULT (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(10),
    course_code VARCHAR(300),
    exam_type VARCHAR(50),
    exam_date DATE,
    ia_marks_obtained FLOAT,
    exams_marks_obtained FLOAT,
    total_marks FLOAT,
    grade CHAR(2),
    remarks VARCHAR(255)
);


CREATE OR REPLACE FUNCTION insert_exam_result()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO exam_result (
    student_id,
    course_code
  ) 
VALUES (
    NEW.student_id,
    NEW.course_code
  );
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_exam_result()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE exam_result
  SET
    student_id = NEW.student_id,
    course_code = NEW.course_code
  WHERE
    student_id = OLD.student_id AND
    course_code = OLD.course_code;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_exam_result_trigger
AFTER INSERT ON EXAMINATION_ENROLLMENT
FOR EACH ROW
EXECUTE PROCEDURE insert_exam_result();

CREATE TRIGGER update_exam_result_trigger
AFTER UPDATE ON EXAMINATION_ENROLLMENT
FOR EACH ROW
EXECUTE PROCEDURE update_exam_result();




CREATE OR REPLACE FUNCTION calculate_exam_result()
RETURNS TRIGGER AS $$
BEGIN
    NEW.total_marks = NEW.ia_marks_obtained + NEW.exams_marks_obtained;
    
    IF NEW.total_marks >= 80 THEN
        NEW.grade = 'A';
        NEW.remarks = 'Excellent performance, keep up the good work!';
    ELSIF NEW.total_marks >= 75 AND NEW.total_marks < 80 THEN
        NEW.grade = 'B+';
        NEW.remarks = 'Good performance, but some areas for improvement.';
    ELSIF NEW.total_marks >= 70 AND NEW.total_marks < 75 THEN
        NEW.grade = 'B';
        NEW.remarks = 'Solid performance, with room for improvement.';
    ELSIF NEW.total_marks >= 60 AND NEW.total_marks < 70 THEN
        NEW.grade = 'C';
        NEW.remarks = 'Average performance, please review the material.';
    ELSIF NEW.total_marks >= 50 AND NEW.total_marks < 60 THEN
        NEW.grade = 'D';
        NEW.remarks = 'Below average performance, please seek help if needed.';
    ELSE
        NEW.grade = 'F';
        NEW.remarks = 'Failed the exam, please review the material and retake the exam.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exam_result_trigger
BEFORE UPDATE ON EXAM_RESULT
FOR EACH ROW
EXECUTE PROCEDURE calculate_exam_result();


CREATE TABLE EXAM_RESULT_AUDIT (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(10),
    course_code VARCHAR(300),
    exam_type VARCHAR(50),
    exam_date DATE,
    ia_marks_obtained FLOAT,
    exams_marks_obtained FLOAT,
    total_marks FLOAT,
    grade CHAR(2),
    remarks VARCHAR(255),
    operation CHAR(1) NOT NULL,
    updated_by VARCHAR(50) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION exam_result_audit_func() RETURNS TRIGGER AS $$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO EXAM_RESULT_AUDIT (
                student_id, course_code, exam_type, exam_date,
                ia_marks_obtained, exams_marks_obtained, total_marks, grade, remarks,
                operation, updated_by
            ) VALUES (
                OLD.student_id, OLD.course_code, OLD.exam_type, OLD.exam_date,
                OLD.ia_marks_obtained, OLD.exams_marks_obtained, OLD.total_marks, OLD.grade, OLD.remarks,
                'D', USER
            );
        ELSE
            IF (TG_OP = 'UPDATE') THEN
                INSERT INTO EXAM_RESULT_AUDIT (
                    student_id, course_code, exam_type, exam_date,
                    ia_marks_obtained, exams_marks_obtained, total_marks, grade, remarks,
                    operation, updated_by
                ) VALUES (
                    OLD.student_id, OLD.course_code, OLD.exam_type, OLD.exam_date,
                    OLD.ia_marks_obtained, OLD.exams_marks_obtained, OLD.total_marks, OLD.grade, OLD.remarks,
                    'U', USER
                );
            END IF;
            INSERT INTO EXAM_RESULT_AUDIT (
                student_id, course_code, exam_type, exam_date,
                ia_marks_obtained, exams_marks_obtained, total_marks, grade, remarks,
                operation, updated_by
            ) VALUES (
                NEW.student_id, NEW.course_code, NEW.exam_type, NEW.exam_date,
                NEW.ia_marks_obtained, NEW.exams_marks_obtained, NEW.total_marks, NEW.grade, NEW.remarks,
                'I', USER
            );
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exam_result_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON EXAM_RESULT
FOR EACH ROW EXECUTE PROCEDURE exam_result_audit_func();




CREATE TABLE LOGIN (
    id SERIAL PRIMARY KEY,
    pin VARCHAR(5) NOT NULL,
    user_id VARCHAR(10),
    last_login TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    password_reset_token VARCHAR(255),
    password_reset_token_expiry TIMESTAMP
);

CREATE OR REPLACE FUNCTION insert_login_credentials()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $$

BEGIN
    INSERT INTO LOGIN (user_id)
    VALUES (NEW.id);
RETURN NEW;
END;
$$ ;

CREATE TRIGGER insert_student_credentials_trigger
AFTER INSERT OR UPDATE ON STUDENT
FOR EACH ROW
EXECUTE PROCEDURE insert_login_credentials();

CREATE TRIGGER insert_login_credentials_trigger
AFTER INSERT OR UPDATE ON LECTURER
FOR EACH ROW
EXECUTE PROCEDURE insert_login_credentials();

CREATE TRIGGER insert_student_credentials_trigger
AFTER INSERT OR UPDATE ON ADMIN
FOR EACH ROW
EXECUTE PROCEDURE insert_login_credentials();


CREATE SEQUENCE login_pin_seq START 10000;


CREATE OR REPLACE FUNCTION set_login_pin()
  RETURNS TRIGGER AS
$$
BEGIN
  NEW.pin := lpad(nextval('login_pin_seq')::text, 5, '0');
  RETURN NEW;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER set_login_pin_trigger
  BEFORE INSERT ON LOGIN
  FOR EACH ROW
  EXECUTE PROCEDURE set_login_pin();


CREATE TABLE LOGIN_audit (
    audittime TIMESTAMP,
    pin VARCHAR(5),
    user_id VARCHAR(10),
    last_login TIMESTAMP,
    failed_login_attempts INTEGER,
    locked_until TIMESTAMP,
    password_reset_token VARCHAR(255),
    password_reset_token_expiry TIMESTAMP,
    audit_action VARCHAR(20)
);

CREATE OR REPLACE FUNCTION login_audit() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO LOGIN_audit (audittime,pin, user_id, last_login, failed_login_attempts, locked_until, password_reset_token, password_reset_token_expiry, audit_action)
        VALUES (now(), OLD.pin,OLD.user_id, OLD.last_login, OLD.failed_login_attempts, OLD.locked_until, OLD.password_reset_token, OLD.password_reset_token_expiry, 'DELETE');
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO LOGIN_audit (audittime,pin, user_id, last_login, failed_login_attempts, locked_until, password_reset_token, password_reset_token_expiry, audit_action)
        VALUES (now(), NEW.pin, NEW.user_id, NEW.last_login, NEW.failed_login_attempts, NEW.locked_until, NEW.password_reset_token, NEW.password_reset_token_expiry, 'UPDATE');
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO LOGIN_audit (audittime, pin,user_id, last_login, failed_login_attempts, locked_until, password_reset_token, password_reset_token_expiry, audit_action)
        VALUES (now(), NEW.pin,NEW.user_id, NEW.last_login, NEW.failed_login_attempts, NEW.locked_until, NEW.password_reset_token, NEW.password_reset_token_expiry, 'INSERT');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER login_audit_trigger
AFTER INSERT OR UPDATE OR DELETE
ON LOGIN
FOR EACH ROW
EXECUTE PROCEDURE login_audit();



--VALUES FOR INSERTION

INSERT INTO DEPARTMENT(name)
VALUES('Agricultural Engineering'),
      ('Biomedical Engineering'),
      ('Computer Engineering'),
      ('Food Process Engineering'),
      ('Materials Science Engineering');

--AREN
INSERT INTO COURSE (level, course_code, name, semester, credit_hours, department_id)
VALUES 
    ( 100, 'SENG 101', 'Calculus I(Pre Maths): Single Variable',1, 4, 1),
    ( 100, 'SENG 103', 'Mechanics I: Statics', 1,3, 1),
    ( 100, 'SENG 105', 'Engineering Graphics',1, 3, 1),
    ( 100, 'SENG 107', 'Introduction to Engineering', 1,2, 1),
    ( 100, 'SENG 109', 'General Chemistry',1, 3,1),
    ( 100, 'SENG 111', 'General Physics',1, 3, 1),
    ( 100, 'UGRC 110', 'Academic Writing I',1, 3, 1),
    ( 100, 'SENG 102', 'CalculusII: Multivarable',2, 4, 1),
    ( 100, 'SENG 104', 'MechanicsII:Dynamics',2, 3, 1),
    ( 100, 'SENG 106', 'Applied Electricity',2, 3, 1),
    ( 100, 'SENG 108', 'Basic Electronics',2, 3,1),
    ( 100, 'SENG 112', 'Engineering Computational Tools',2, 3, 1),
    ( 100, 'AREN 114', 'Introduction to Biosystems Engineering',2, 3, 1),
    ( 100, 'UGRC 150', 'Critical Thinking and Practical Reasoning',2, 3, 1),
    ( 200, 'SENG 201', 'Linear Algebra',1, 4, 1),
    ( 200, 'SENG 203', 'Strength of Materials I',1, 3, 1),
    ( 200, 'SENG 205', 'Fundamentals of Thermodynamics',1, 3, 1),
    ( 200, 'SENG 207', 'Programming for Engineers', 3,1, 1),
    ( 200, 'AREN 211', 'Animal Production',1, 3, 1),
    ( 200, 'AREN 213', 'Engineering Surveying',1, 3, 1),
    ( 200, 'UGRC 221', 'Introduction to African Studies',1, 3, 1),
    ( 200, 'SENG 202', 'Differential Equations',2, 4, 1),
    ( 200, 'SENG 204', 'Fluid Mechanics I',2, 3, 1),
    ( 200, 'AREN 212', 'Introduction to Crop Production',2, 3, 1),
    ( 200, 'AREN 214', 'Heat Transfer',2, 3, 1),
    ( 200, 'AREN 216', 'Soil Mechanics I',2, 3, 1),
    ( 200, 'AREN 232', 'Energy and Power in Biosystems Engineering',2, 2, 1),
    ( 200, 'CBAS 210', 'Academic Writing II',2, 3, 1),
    ( 300, 'SENG 301', 'Numerical Methods',1, 3, 1),
    ( 300, 'AREN 321', 'Engineering Hydrology',1, 3, 1),
    ( 300, 'AREN 325', 'Surface Irrigation',1, 3, 1),
( 300, 'AREN 331', 'Soil & Crop Mechanics Application to Mechanization',1, 3, 1),
( 300, 'AREN 341', 'Agricultural Produce Processing Systems I: Durables',1, 3, 1),
( 300, 'AREN 343', 'Farm Structures I',1, 3, 1),
( 300, 'AREN 323', 'Soil Mechanics II',1, 3, 1),
	  
( 300, 'SENG 302', 'Statistics for Engineers',2, 3, 1),
( 300, 'SENG 304', 'Engineering Economics',2, 2, 1),
( 300, 'AREN 306', 'Mechanical Engineering Design I',2, 3, 1),
( 300, 'AREN 312', 'Rural Engineering',2, 3, 1),
( 300, 'AREN 314', 'Internship(Industrial Practice)',2, 3, 1),
( 300, 'AREN 322', 'Fluid Mechanics',2, 3, 1),
( 300, 'AREN 332', 'Mechanics of Tillage and Traction',2, 3, 1),
( 300, 'AREN 342', 'Agricultural Produce Processing Systems II (Persihables)',1, 3, 1),
	  
( 400, 'SENG 401', 'Law for Enginners',1, 3, 1),
( 400, 'AREN 421', 'Soil and Water Conservation Engineering',1, 3, 1),
( 400, 'AREN 433', 'Technology of Tractor and Implement',1, 3, 1),
( 400, 'AREN 441', 'Farm Structures II',1, 3, 1),
( 400, 'AREN 423', 'Engineering Hydraulics',1, 3, 1),
( 400, 'AREN 425', 'Drainage Engineering',1, 3, 1),
( 400, 'AREN 427', 'Groundwater Hydrology',1, 3, 1),
( 400, 'AREN 431', 'Renewable Energy Technology',2, 3, 1),
( 400, 'AREN 435', 'Maintenance if Agricultural Machines',2, 3, 1),
( 400, 'AREN 437', 'Climate Smart Mechanization',2, 3, 1),
( 400, 'AREN 443', 'Green Supply Chain Management',2, 3, 1),
( 400, 'AREN 445', 'Storage Systems',2, 3, 1),
( 400, 'AREN 447', 'Cold Chain Management',2, 3, 1),
( 400, 'SENG 402', 'Principles of Management and Entrepreneurship',2, 3, 1),
( 400, 'AREN 400', 'Project Work',2, 6, 1),
( 400, 'AREN 426', 'Agrometeoroly and Climatology',2, 3, 1),
( 400, 'AREN 436', 'Farm Machine Design',2, 3, 1),
( 400, 'AREN 422', 'Hydraulic Structures',2, 3, 1),
( 400, 'AREN 424', 'Water Resources Management',2, 3, 1),
( 400, 'AREN 428', 'Micro Irrigation',2, 3, 1),
( 400, 'AREN 432', 'Agricultural Machinery Management',2, 3, 1),
( 400, 'AREN 434', 'Precision Agriculture',2, 3, 1),
( 400, 'AREN 438', 'Livestock Mechanization',2, 3, 1),
( 400, 'AREN 442', 'Green Engineering',2, 3, 1),
( 400, 'AREN 444', 'Agricultural Materials Handling',2, 3, 1),
( 400, 'AREN 448', 'Introduction to Mechatronics',2, 3, 1);


--BMEN
INSERT INTO COURSE(level,course_code,name,semester,credit_hours,department_id)
VALUES
    (100, 'SENG 101', 'CALCULUS I', 1, 4,2),
    (100, 'SENG 103', 'Mechanics1 Statics', 1, 3,2),
    (100, 'SENG 105', 'Engineering Graphics', 1, 3,2),
    (100, 'SENG 107', 'Introduction to Engineering', 1, 3,2),
    (100, 'SENG 109', 'General Chemistry', 1, 3,2),
    (100, 'SENG 111', 'General Physics', 1, 3,2),
    (100, 'UGRC 110', 'Academic Writing I', 1, 3,2),
    (100, 'SENG 102', 'CalculusII:Multivarable', 2, 4,2),
    (100, 'SENG 104', 'MechanicsII:Dynamics', 2, 3,2),
    (100, 'SENG 106', 'Applied Electricity', 2, 3,2),
    (100, 'SENG 108', 'Basic Electronics', 2, 3,2),
    (100, 'SENG 112', 'Engineering Computational Tools', 2, 3,2),
    (100, 'BMEN 102', 'General Biology', 2, 3,2),
    (100, 'UGRC 150', 'Critical thinking & practical reasoning', 2, 3,2),
    (200, 'SENG 201', 'Linear Algebra', 1, 3,2),
    (200, 'SENG 203', 'Strength of Materials I', 1, 3,2),
    (200, 'SENG 205', 'Fundamentals of Thermodynamics', 1, 3,2),
    (200, 'SENG 207', 'Programming for Engineers', 1, 3,2),
    (200, 'BMEN 201', 'Anatomy and Physiology', 1, 3,2),
    (200, 'BMEN 203', 'Introduction to Structure and Properties of Materials', 1, 3,2),
    (200, 'UGRC 220-238', 'Intro to African Studies', 1, 3,2),
    (200, 'SENG 202', 'Differential Equations', 2, 3,2),
    (200, 'SENG 104', 'Fluid Mechanics I', 2, 3,2),
    (200, 'BMEN 202', 'Introduction to Biomedical Engineering', 2, 3,2),
    (200, 'BMEN 204', 'Eng. Principles of Human Physiology and Anatomy', 2, 3,2),
    (200, 'BMEN 208', 'Transport Process in Living Systems', 2, 3,2),
    (200, 'BMEN 208', 'Medical Imaging', 2, 3,2),
    (200, 'CBAS 210', 'Academic Writing II', 2, 3,2),
    (300, 'SENG 301', 'Numerical Methods', 1, 3,2),
 (300, 'BMEN 303', 'Bioinstrumentation', 1, 3,2),
 (300, 'BMEN 305', 'Biomaterials', 1, 3,2),
 (300, 'BMEN 307', 'Biomechanics', 1, 3,2),
 (300, 'BMEN 309', 'Cell, Molecular Biology and Biotechnology', 1,3,2),
 (300, 'BMEN 315', 'Research Methodology', 1, 3,2),
 (300, 'SENG 302', 'Statistics for Engineers', 1, 3,2),
 (300, 'SENG 304', 'Engineering Economics', 2, 3,2),
 (300, 'BMEN 302', 'Tissue Engineering', 2, 3,2),
 (300, 'BMEN 304', 'Local Issues in Biomedical Engineering', 2, 3,2),
 (100, 'BMEN 306', 'Design & Selection of Biomaterials', 2, 3,2),
 (300, 'SENG 308', 'Design of Mechanical Systems', 2, 3,2),
 (300, 'BMEN 314', 'Biomedical Engineering Systems', 2, 3,2),
 (300, 'BMEN 316', 'BMEN 316 Internship (Industrial Practice)', 2, 3,2),
 (400, 'SENG 401', 'laws for Enginners', 2, 3,2),
 (400, 'BMEN 405', 'Cardiovascular and Respiratory Systems Mechanics', 2, 3,2),
 (400, 'BMEN 407', 'Medical Signal and Image Processing', 2, 3,2),
 (400, 'BMEN 403', 'Hiophysics', 2, 3,2),
 (400, 'BMEN 411', 'Medical Physics', 2, 3,2),
 (400, 'BMEN 413', 'Bioelectronics', 2, 3,2),
 (400, 'SENG 417', 'Nanotechnology', 2, 3,2),
 (400, 'BMEN 419', 'Health Technology Assessment', 2, 3,2),
 (400, 'BMEN 421', 'Bioinformatics', 2, 3,2),
 (400, 'BMEN 400', 'Project', 2, 6,2),
 (400, 'SENG 402', 'Principles of Management and Entrepreneurship', 2, 3,2),
 (400, 'BMEN 404', 'Telemetry and Telemedicine', 2, 3,2),
 (400, 'BMEN 406', 'Rehabilitation Engineering', 2, 3,2),
 (400, 'BMEN 408', 'Orthotics and Prosthesis', 2, 3,2),
 (400, 'BMEN 412', 'Healthcare Facility Planning & Design', 2, 3,2),
 (400, 'BMEN 414', 'Biophotonics', 2, 3,2);



--CPEN
INSERT INTO COURSE (level, course_code, name, semester, credit_hours, department_id)
VALUES
  (100, 'SENG 101', 'CALCULUS I', 1, 3, 3),
  (100, 'SENG 103', 'Mechanics1 Statics', 1, 3, 3),
  (100, 'SENG 105', 'Engineering Graphics', 1, 3, 3),
  (100, 'SENG 107', 'Introduction to Engineering', 1, 3, 3),
  (100, 'CPEN 103', 'Computer Engineering Innovations', 1, 3, 3),
  (100, 'SENG 111', 'General Physics', 1, 3, 3),
  (100, 'UGRC 110', 'Academic Writing I', 1, 3, 3),
  (100, 'SENG 102', 'CalculusII:Multivariable', 2, 3, 3),
  (100, 'SENG 104', 'MechanicsII:Dynamics', 2, 3, 3),
  (100, 'SENG 106', 'Applied Electricity', 2, 3, 3),
  (100, 'SENG 108', 'Basic Electronics', 2, 3, 3),
  (100, 'SENG 112', 'Engineering Computational Tools', 2, 3, 3),
  (100, 'CPEN 104', 'Engineering Design', 2, 3, 3),
  (100, 'UGRC 150', 'Critical thinking & practical reasoning', 2, 3, 3),
  (200, 'SENG 201', 'Linear Algebra', 1, 3, 3),
  (200, 'CPEN 203', 'Digital Circuits', 1, 3, 3),
  (200, 'CPEN 213', 'Discrete Mathematics', 1, 3, 3),
  (200, 'SENG 207', 'Programming for Engineers', 1, 3, 3),
  (200, 'SENG 209', 'Database System Design', 1, 3, 3),
  (200, 'CPEN 201', 'C++ Programming', 1, 3, 3),
  (200, 'UGRC 220 - 238', 'Introduction to African Studies', 1, 3, 3),
  (200, 'SENG 202', 'Differential Equations', 2, 3, 3),
  (200, 'CPEN 204', 'Data Structure and Algorithms', 2, 3, 3),
  (200, 'CPEN 206', 'Linear Circuits', 2, 3, 3),
  (200, 'CPEN 208', 'Software Engineering', 2, 3, 3),
  (200, 'CPEN 212', 'Data Communications', 2, 3, 3),
  (200, 'CPEN 214', 'Digital System Design', 2, 3, 3),
  (200, 'CBAS 210', 'Academic Writing II', 2,3,3),
  (300,'SENG 301','Numerical Methods',1,3,3),
(300,'CPEN 301','Signals and Systems',1,3,3),
(300,'CPEN 307','Operating Systems',1,3,3),
(300,'CPEN 305','Computer Networks',1,3,3),
(300,'CPEN 311','Object-Oriented Programming',1,3,3),
(300,'CPEN 313','Microelectronics Circuit Analysis and Design',1,3,3),
(300,'CPEN 315','Computer Organization and Architecture',1,3,3),

(300,'SENG 302','Statistics for Engineers',2,3,3),
(300,'SENG 304','Engineering Economics',2,3,3),
(300,'CPEN 304','Digital Signal Processing',2,3,3),
(300,'CPEN 314','Industrial Practice',2,3,3),
(300,'CPEN 316','Artificial Intelligence and Applications',2,3,3),
(300,'SENG 318','Software for Distributed Systems',2,3,3),
(300,'CPEN 322','Microprocessor Programming and Interfacing',2,3,3),
(300,'SENG 324','Research Methods',2,3,3),

(400,'SENG 401','Law for Engineers',1,3,3),
(400,'CPEN 400','Independent Project I',1,3,3),
(400,'CPEN 401','Control Systems Analysis and Design',1,3,3),
(400,'CPEN 403','Embedded Systems',1,3,3),
(400,'CPEN 419','Computer Vision',1,3,3),
(400,'CPEN 429','Engineering Trends in Computer Engineering',1,3,3),

(400,'SENG 409','Computer Graphics',2,3,3),
(400,'CPEN 411','VLSI Systems Design',2,3,3),
(400,'CPEN 415','Distributed Computing',2,3,3),
(400,'CPEN 421','Mobile and Web Software Design and Architecture',2,3,3),
(400,'CPEN 423','Digital Forensics',2,3,3),
(400,'CPEN 425','Real-Time Systems',2,3,3),
(400,'CPEN 427','Cryptography',2,3,3),

(400,'SENG 402','Principles of Management and Entrepreneurship',1,3,3),
(400,'CPEN 400','Independent Project II',2,6,3),
(400,'CPEN 406','Wireless Communication Systems',1,3,3),
(400,'CPEN 424','Robotics',1,3,3),
(400,'CPEN 426','Computer and Network Security',2,3,3),
(400,'CPEN 444','Professional Development',1,3,3),

(400,'CPEN 408','Human-Computer Interface',2,3,3),
(400,'CPEN 422','Multimedia Systems',2,3,3),
(400,'CPEN 434','Digital Image Processing',2,3,3),
(400,'CPEN 432','Wireless Sensor Networks',1,3,3),
(400,'CPEN 438','Advanced Computer Architecture Systems and Design',1,3,3), 
(400,'CPEN 442','Introduction to Machine Learning',2,3,3);


--FPEN
INSERT INTO COURSE(level,course_code,name,semester,credit_hours,department_id)
VALUES (100,'SENG 101','CALCULUS I',1,4,4),
          (100,'SENG 103','Mechanics1 Statics',1,3,4),
          (100,'SENG 105','Engineering Graphics',1,3,4),
          (100,'SENG 107','Introduction to Engineering',1,4,4),
	  (100,'SENG 109','General Chemistry',1,3,4),
	  (100,'SENG 111','General Physics',1,3,4),
	  (100,'UGRC 110','Academic Writing I',1,3,4),
	  (100,'SENG 104','CalculusII:Multivarable',2,4,4),
	  (100,'SENG 104','MechanicsII:Dynamics',2,3,4),
	  (100,'SENG 106','Applied Electricity',2,3,4),
	  (100,'SENG 108','Basic Electronics',2,3,4),
	  (100,'SENG 114','Engineering Computational Tools',2,3,4),
	  (100,'UGRC 150','Critical thinkg & pratical reasoning',2,3,4),
	  (200,'SENG 401','Linear Algebra',1,4,4),
          (200,'SENG 403','Strength of Materinals I',1,3,4),
          (200,'SENG 405','Fundamentals of Thermodynamics',1,3,4),
          (200,'SENG 407','Programming for Engineers',1,3,4),
	  (200,'FPEN 409','Basic Food Process Engineering CalculationsI',1,3,4),
	  (200,'UGRC 441','Introduction to African Studies',1,3,4),
	  (200,'SENG 404','Differential Equations',2,4,4),
	  (200,'FPEN 404','Basic Food Process Engineering Calculations II',2,3,4),
	  (200,'FPEN 404','Physical and Chemical Properties of Food',2,3,4),
	  (200,'FPEN 406','Chemical Equilibrium Thermodynamics',2,3,4),
	  (200,'FPEN 408','Transport Phenomena I(Momentum Transfer',2,3,4),
	  (200,'CHAS 410','Academic Writing II',2,3,4),
	  (300,'SENG 301','Numerical Methods',1,3,4),
          (300,'FPEN 301','Transport Phenomena II(Heat Transfer)',1,3,4),
          (300,'FPEN 303','Engineering & Design of Food Process I',1,3,4),
          (300,'FPEN 305','Introduction to Food Microbiology',1,3,4),
	  (300,'FPEN 307','Process/Product Development in Food Processing',1,3,4),
	  (300,'FPEN 309','Introduction to Biotechnolgy ',1,3,4),
	  (300,'FOSC 307','Beverages and Sugar Processing Technology',1,4,4),
	  (300,'FPEN 311','Introduction to Food Biochemistry',1,3,4),
	  (300,'SENG 304','Statistics for Engineers',2,3,4),
	  (300,'SENG 304','Engineering Economics',2,4,4),
	  (300,'FPEN 304','Separation Process',2,3,4),
	  (300,'FPEN 304','Enginerring & Design of Food Process II',2,4,4),
	  (300,'FPEN 308','Environmental Engineering in Food Processing',2,3,4),
	  (300,'FPEN 314','Transport Phenomena III(was Mass Transfer)',2,3,4),
	  (300,'FPEN 344','Internship',2,3,4),
	  (300,'FPEN 314','Rheological and Sensory Properties of Food',2,4,4), 
	  (400,'SENG 401','laws for Enginners',1,3,4),
	  (400,'FPEN 401','Food Plant Design and Economics',1,3,4),
	  (400,'FPEN 403','Chemical and Biochemical Reaction Engineering ',1,3,4),
	  (400,'FPEN 405','Engineering and Design of Food Process III(Plant Production)',1,3,4),
	  (400,'FPEN 407','Satistical Quality Control in Food Processing',1,3,4),
	  (400,'FPEN 409','Safety in Food Plants',1,3,4),
	  (400,'FPEN 411','Professional Development Seminar',1,3,4),
	  (400,'FPEN 413','Engineering Design',1,4,4),
	  (400,'SENG 404','Principles of Management and Entrepreneurship',2,3,4),
	  (400,'FPEN 400','Independent Enginnering Study(Capstone Engineering Design)',2,6,4),
	  (400,'FPEN 404','Engineering and Design of Food Process IV(Animal Products)',2,3,4),
	  (400,'FOSC 404','Food Processing Plant Operations and Sanitation',2,4,4),
	  (400,'FPEN 404','Process Control',2,4,4),
	  (400,'FPEN 406','Food Packaging',2,4,4),
	  (400,'FPEN 416','Microbiological Applications in Food Processing',2,3,4);


--MTEN
INSERT INTO COURSE(level,course_code,name,semester,credit_hours,department_id)
VALUES(100,'SENG 101','CALCULUS I',1,4,5),
          (100,'SENG 103','Mechanics1 Statics',1,3,5),
          (100,'SENG 105','Engineering Graphics',1,3,5),
          (100,'SENG 107','Introduction to Engineering',1,4,5),
	  (100,'SENG 109','General Chemistry',1,3,5),
	  (100,'SENG 111','General Physics',1,3,5),
	  (100,'UGRC 110','Academic Writing I',1,3,5),
	  (100,'SENG 104','CalculusII:Multivarable',2,4,5),
	  (100,'SENG 104','MechanicsII:Dynamics',2,3,5),
	  (100,'SENG 106','Applied Electricity',2,3,5),
	  (100,'SENG 108','Basic Electronics',2,3,5),
	  (100,'SENG 114','Engineering Computational Tools',2,3,5),
	  (100,'MTEN 104','Computer Aided Design and Manufacturing(CAD/CAM)',2,3,5),
	  (100,'UGRC 150','Critical thinkg & pratical reasoning',2,3,5),
	  (200,'SENG 401','Linear Algebra',1,4,5),
          (200,'SENG 403','Strength of Materinals I',1,3,5),
          (200,'SENG 405','Fundamentals of Thermodynamics',1,3,5),
          (200,'SENG 407','Programming for Engineers',1,3,5),
	  (200,'SENG 409','Fundamentals of Materials Science& Engineering',1,3,5),
	  (200,'SENG 403','Materials in our World',1,3,5),
	  (200,'UGRC 441','Introduction to African Studies',1,3,5),
	  (200,'SENG 404','Differential Equations',2,4,5),
	  (200,'SENG 104','Fluid MechanicsI',2,3,5),
	  (200,'MTEN 404','Kinectics Processes and Surface Phenomenon',2,4,5),
	  (200,'MTEN 404','Thermodynamics of Materials',2,3,5),
	  (200,'MTEN 408','Electrical, Magnetic& Optical Properties',2,3,5),
	  (200,'MTEN 414','Materials Properties Laboratory',2,3,5),
	  (200,'CHAS 410','Academic Writing II',2,3,5),
	  (300,'SENG 301','Numerical Methods',1,3,5),
          (300,'MTEN 301','Materials Processing Laboratory',1,4,5),
          (300,'MTEN 303','Introducting to Materials Processing',1,3,5),
          (300,'MTEN 305','Mechanical Behaviour of Materials',1,3,5),
	  (300,'MTEN 307','Phase Equilibrium of Materials',1,3,5),
	  (300,'MTEN 309','Materials Analyses Techniques',1,3,5),
	  (300,'MTEN 311','Solid State Technology',1,4,5),
	  (300,'MTEN 315','Nanomaterials and Nanotechnology',1,4,5),
	  (300,'SENG 304','Statistics for Engineers',2,3,5),
	  (300,'SENG 304','Engineering Economics',2,4,5),
	  (300,'MTEN 304','Internship',2,1,5),
	  (300,'MTEN 304','Computational Materials Science',2,4,5),
	  (300,'MTEN 306','Materials Characterization Laboratory',2,3,5),
	  (300,'SENG 308','Heat and Mass Transfer',2,3,5),
	  (300,'MTEN 314','Crystal Chemistry of Ceramics',2,4,5),
	  (300,'MTEN 314','Ceramic Processing Principle',2,3,5),
	  (300,'MTEN 316','Enginnering Ceramics I',2,4,5),
	  (300,'MTEN 318','Principles of Extractive Metallurgy',2,4,5),
	  (300,'MTEN 344','Physical Metallurgy',2,4,5),
	  (300,'SENG 344','Metal Joining Technology(Welding)',2,3,5),
	  (300,'MTEN 346','Organic Chemistryof Polymers',2,3,5),
	  (300,'MTEN 348','Polymer Processing Tech I',2,4,5),
	  (400,'SENG 401','laws for Enginners',1,3,5),
	  (400,'MTEN 400','Project Work',1,3,5),
	  (400,'MTEN 401','Composite Design and Fabrication',1,3,5),
	  (400,'MTEN 403','Refractories',1,3,5),
	  (400,'MTEN 405','Process & Quality Control',1,3,5),
	  (400,'MTEN 407','Engineering Ceramics II',1,3,5),
	  (400,'SENG 409','Glasses,Cements and Concretes',1,3,5),
	  (400,'MTEN 411','Physical Metallurgy II',1,3,5),
	  (400,'MTEN 413','Foundry Technology',1,3,5),
	  (400,'MTEN 415','Biodegradable Polymer & Fibrous Materials',1,3,5),
	  (400,'MTEN 417','Polymer Processing & Technology',1,3,5),
	  (400,'SENG 404','Principles of Management and Entrepreneurship',2,3,5),
	  (400,'MTEN 400','Project Work',2,3,5),
	  (400,'MTEN 404','Non Destructive Evaluation and Failure',2,3,5),
	  (400,'MTEN 404','Project Management',2,4,5),
	  (400,'MTEN 408','Professional Development- Seminar',2,1,5),
	  (400,'MTEN 414','Materials Selection & Design',2,3,5),
	  (400,'MTEN 414','Environmental Engineering &Waste Management',2,3,5),
	  (400,'MTEN 416','Corrosion & Corrosion control',2,3,5);


--STUDENTS
INSERT INTO STUDENT
  (firstname, middlename, lastname, date_of_birth,telephone_number,department_id ,level_of_study)
VALUES
  ( 'Kwame', 'Boadi', 'Adom', '2003-02-16','+233548567890', 4,100),
  ( 'Abena', 'Serwaa', 'Owusu', '2002-06-21', '+233545678901',3, 100),
  ( 'Yawo', 'Kwadwo', 'Adu', '2004-01-15', '+233548789012', 5,100),
  ( 'Akua', 'Abigail', 'Mensah', '2001-08-09', '+233542345678', 2,100),
  ( 'Kofi', 'Yayra', 'Asante', '2003-12-04','+233548901234',4 ,100),
  ( 'Ama', 'Agnes', 'Kwakye', '2002-04-19', '+233542345678',5 ,100),
  ( 'Yaw', 'Kelvin', 'Ofori', '2004-09-27', '+233548901234',3 ,100),
  ( 'Adwoa', 'John', 'Darko', '2001-03-13', '+233545678901', 2,100),
  ( 'Kwesi', 'King', 'Osei', '2003-07-18', '+233548789012',1 ,100),
  ( 'Akosua', 'Gabby', 'Addo', '2002-11-23', '+233542345678',1, 100),
  ( 'Kwabena', 'Lincoln', 'Boateng', '2004-05-08','+233548901234',3 ,100),
  ( 'Ama', 'Ofosu', 'Nkrumah', '2001-09-02',  '+233545678901', 1,100),
  ( 'Kofi', 'Wick', 'Tetteh', '2003-11-12', '+233548789012',4 ,100),

  
  ('Emma', 'Rose', 'Smith', '2001-01-01','+233241234567', 5,200),
  ('Sophia', 'Elizabeth', 'Jones', '2002-02-02', '+233242345678',4 ,200),
  ('Olivia', 'Marie', 'Davis', '2003-03-03', '+233243456789',3,200),
  ('Ava', 'Grace', 'Taylor', '2004-04-04','+233244567890', 1,200),
  ('Isabella', 'Faith', 'Anderson', '2005-05-05', '+233245678901',5, 200),
  ('Mia', 'Hope', 'Wilson', '2006-06-06','+233246789012',4 ,200),
  ('Charlotte', 'Joy', 'Johnson', '2007-07-07', '+233247890123', 2,200),
  ('Amelia', 'May', 'Brown', '2008-08-08','+233248901234',3 ,200),
  ('Harper', 'Ella', 'Miller', '2009-09-09', '+233249012345',2 ,200),
  ('Evelyn', 'Rose', 'Garcia', '2010-10-10','+233240123456', 5,200),
  ('Abigail', 'Marie', 'Lopez', '2011-11-11','+233241234567',2 ,200),
  ('Emily', 'Hope', 'Hernandez', '2012-12-12', '+233242345678', 4,200),
  ('Elizabeth', 'Faith', 'Martinez', '2013-01-13','+233243456789', 1,200),

 
  ('Kofi', 'John', 'Asamoah', '1998-05-28','+233546789012',5 ,300),
  ('Kwesi', 'Brown', 'Osei', '1998-06-11','+233546789012',3 ,300),
  ('Akua', 'Manso', 'Addo', '1999-11-06', '+233541234567', 4,300),
  ('Amma', 'Baidoo', 'Owusu', '2001-01-05', '+233548765432', 2,300),
  ('Kwadwo', 'Lesley', 'Mensah', '1999-04-21','+233548678910', 2,300),
  ('Afia', 'Wurapa', 'Appiah', '2000-11-30','+233542345678',1 ,300),
  ('Kofi', 'Baffour', 'Agyapong', '1998-06-14', '+233545678901',1 ,300),
  ('Ama', 'Arhin', 'Nti', '1999-08-22','+233542345678', 5,300),
  ('Yaw', 'Acquah', 'Boamah', '2000-02-13','+233548678910', 2,300),
  ('Kwabena', 'Ofori', 'Agyeman', '1998-09-17', '+233545678901',1 ,300),
  ('Akosua', 'OSei', 'Asiedu', '1999-07-25','+233542345678', 3,300),
  ('Kwame', 'Nancy', 'Owusu', '2000-04-08','+233548678910', 2,300),
  ('Ama', 'Adofo', 'Boakye', '1998-10-09','+233545678901',3 ,300),

   
   
  ('Kwaku', 'Kivlin', 'Owusu', '1999-03-11','+233540733379',2 ,400),
  ('Ama', 'Aggie', 'Osei', '1998-06-02','+233541234567', 4,400),
  ('Yaw', 'Quaidoo', 'Asamoah', '2000-07-15','+233543210987',5 ,400),
  ('Kwame', 'Gideon', 'Osei', '1998-12-16','+233546789576',3 ,400),
  ('Yaw', 'Gad', 'Gyamfi', '1999-07-01','+233541234567',2 ,400),
  ('Akua', 'Mary', 'Kwakye', '2000-09-13','+233543210987', 1,400),
  ('Kwame', 'Johnson', 'Addo', '1998-02-15','+233546789012',4 ,400),
  ('Akosua', 'Quainoo', 'Asante', '1998-09-23','+233546789012',3,400),
  ('Ama', 'Doe', 'Asante', '1999-03-29','+233541234567',2 ,400),
  ('Yaw', 'Black', 'Osei', '2000-05-02', '+233543210987',5 ,400),
  ('Kwesi', 'Nimoh', 'Boateng', '1998-08-06','+233546789012',4 ,400),
  ('Akosua', 'Offei', 'Asamoah', '1999-12-09','+233541234567', 4,400),
  ('Kofi', 'Manso', 'Yeboah', '2000-06-26','+233543210987', 3,400);



Insert into LECTURER(firstname, middlename, lastname, department_id)
values ('Isaac', '', 'Aboagye',3),
( 'Kenneth', '', 'Broni',3),
( 'John', '', 'Assiamah',3),
( 'Margaret', 'Ansah', 'Richardson',3),
( 'Percy', '', 'Okae',3),
( 'Agyare', '', 'Debra',3),
( 'Emmanuel', '', 'Djabang',3),

('Gifty', '', 'Osei',3),
('George', '', 'Anni',3),
('Nii', 'Longdon', 'Sowah',3),

('Prosper', '', 'Afriyie',3),
('Godfrey', '', 'Mills',3),


-- AGRIC FIRST SEM, L200
('Emmanuel', '', 'Djabang',1),
('Eric', 'Oppong', 'Danso',1),
( 'P', 'K', 'Amoatey',1),
( 'E', '', 'Essien',1),
( 'Vitus', 'Atanga', 'Apalangya',1),
('Emmmanuel', '', 'Nyankson',1),


--BMEN- 1ST SEM, L200
('Elvis', 'K', 'Tiburu',2),
('Bernard', 'Owusu', 'Asimeng',2),



-- FPEN LECTURERS 
('Vitus', 'Atanga', 'Apalangya',4),
('Frank', '', 'Nsaful',4),
('John', 'K', 'Bediako',4),
('Bismark', '', 'Mensah',4),

('Nii', '', 'Darko',4),
('Jessica', '', 'Ibrahim',4),
('Parry-Hanson', '', 'Kunadu',4),
('Frank', '', 'Nsaful',4),

('Firibu', 'Kwesi', 'Saalia',4),
('N', 'Sharon', 'Affrifah',4),
('John', '', 'Appiah',4),
('Richard', '', 'Padi',4),
('Gladys', '', 'Kontoh',4),
('Tsatsu', '', 'Nukunya',4);


INSERT INTO  LECTURER_COURSE(lecturer_id, course_id)
VALUES
('staff10000','CPEN 103'),
('staff10000','CPEN 305'),	
('staff10001','SENG 207'),	
('staff10002','CPEN211'),	
('staff10003','CPEN 201'),
('staff10003','CPEN 303'),	
('staff10004','CPEN 213'),	
('staff10005','CPEN 203'),	
('staff10006','SENG 201'),	
('staff10007','CPEN 307'),	
('staff10008','CPEN 309'),	
('staff10009','FAEN 301'),	
('staff10010','CPEN 413'),	
('staff10011','CPEN 301'),
('staff10011','CPEN 401'),
('staff10011','CPEN 403'),	
('staff10013','AREN 213'),				
('staff10016','SENG 203'),
('staff10016','FPEN 303'),	
('staff10017','SENG 205'),	
('staff10018','BMEN 201'),	
('staff10019','BMEN 203'),		
('staff10021','FPEN 201'),
('staff10021','FPEN 305'),	
('staff10022','FPEN 203'),
('staff10022','FPEN 311'),	
('staff10023','SENG 203'),	
('staff10024','FPEN 301'),	
('staff10025','FPEN 309'),	
('staff10026','FPEN 307'),		
('staff10028','FPEN 405'),	
('staff10029','FPEN 407'),	
('staff10030','FPEN 409'),	
('staff10031','FPEN 411'),	
('staff10032','FPEN 405'),	
('staff10033','FPEN 403');


INSERT INTO TIMETABLE_COURSE (timetable_id,department_id,course_id, start_time, end_time, day_of_week, location)
VALUES 
    (1, 1,'SENG 207', '07:30:00', '09:30:00', 'Tuesday', 'E9'),
    (1, 1,'AREN 213', '09:00:00', '11:30:00','Tuesday', 'WW-S2'),
    (1, 1,'SENG 205', '09:30:00', '12:30:00', 'Wednesday','SF-F2'),
    (1, 1,'AREN 211', '09:00:00', '11:30:00', 'Tuesday', 'WW-S3'),
    (1, 1,'SENG 201', '05:00:00', '07:30:00', 'Wednesday','NNB3'),
    (1, 1,'AREN 211', '8:30:00', '11:30:00', 'Thursday', 'WW-S3'),
    (1, 1,'SENG 207', '09:00:00', '10:30:00', 'Friday', 'SES Computer Lab'),
    (1, 1,'SENG 201', '01:30:00', '03:30:00', 'Thursday','CC'),

    (1, 2,'SENG 207', '07:30:00', '09:30:00', 'Tuesday', 'E9'),
    (1, 2,'BMEN 201', '02:30:00', '4:30:00','Wednesday', 'WW-S1'),
    (1, 2,'SENG 205', '09:30:00', '12:30:00', 'Wednesday','SF-F2'),
    (1, 2,'SENG 203', '05:30:00', '7:30:00', 'Friday', 'JQB09'),
    (1, 2,'SENG 201', '05:00:00', '07:30:00', 'Wednesday','NNB3'),
    (1, 2,'SENG 201', '01:30:00', '03:30:00', 'Thursday','CC'),
    (1, 2,'SENG 207', '09:00:00', '10:30:00', 'Friday', 'SES Computer Lab'),

    (1, 4,'SENG 109',  '07:30:00', '09:30:00', 'Tuesday', 'JQB09'),
    (1, 4,'SENG 107', '1:30:00', '3:30:00',   'Monday', 'JQB09 (JI)'),
    (1, 4,'SENG 103', '03:00:00', '4:30:00',  'Tuesday', 'NNB1'),
    (1, 4,'SENG 101', '5:30:00', '7:30:00',   'Tuesday', 'N1'),
    (1, 4,'SENG 105', '07:30:00', '15:30:00', 'Friday', 'UGCS'),
    (1, 4,'SENG 207', '09:00:00', '9:30:00',  'Tuesday', 'E9'),
    (1, 4,'SENG 205 ','10:30:00', '01:30:00', 'Tuesday', 'SF-F2'),
    (1, 4,'FPEN 203', '14:00:00', '15:30:00', 'Tuesday', 'WW-S1 (lab)'),
    (1, 4,'SENG 201 ', '05:30:00', '07:30:00', 'Wednesday', 'NNB3'),
    (1, 4,'FPEN 201 ', '10:00:00', '12:30:00', 'Wednesday', 'SF-F1'),
    (1, 4,'FPEN 201 ', '7:30:00', '9:30:00', 'Wednesday', 'FOOD PROCESS LAB'),
    (1, 4,'FPEN 203 ', '07:30:00', '09:30:00', 'Thursday', 'EW-S2 '),
    (1, 4,'SENG 201', '01:30:00', '03:30:00', 'Thursday', ' CC'),
    (1, 4,'SENG 207', '12:30:00', '03:30:00', 'Friday', 'SES COMPUTER LAB'),
    (1, 4,'FPEN 305 ', '08:30:00', '10:30:00', 'Monday', 'EW-S2'),
    (1, 4,'FPEN 309 ', '10:30:00', '12:30:00', 'Monday', 'EW-S2'),

    (1, 4,'FPEN 307 ', '07:30:00', '12:30:00', 'Tuesday', '(Lab) (APK)'),
    (1, 4,'FPEN 309 ', '02:00:00', '4:30:00','Tuesday', 'EW-S2'),
    (1, 4,'FAEN 301 ', '02:30:00', '4:30:00', 'Wednesday','SF-F2'),
    (1, 4,'FPEN 301 ', '11:30:00', '01:30:00', 'wednesday', ' EW-S2'),
    (1, 4,'FPEN 311 ', '09:30:00', '12:30:00', 'Thursday','EW-S2'),
    (1, 4,'FPEN 303 ', '12:00:00', '2:30:00', 'Thursday', 'EW-S2'),
    (1, 4,'FAEN 301 ', '03:00:00', '05:30:00', 'Thursday', 'CC'),
    (1, 4,'FPEN 301 ',  '09:30:00', '12:30:00', 'Friday', 'EW-S2 '),
    (1, 4,'FPEN 401 ', '11:30:00', '01:30:00',   'Monday', 'EW-S3'),
    (1, 4,'FAEN 401', '01:00:00', '3:30:00',  'Monday', 'NNB1'),
    (1, 4, 'FPEN 405' , '08:30:00', '11:30:00',   'Tuesday', 'EW-S1'),
    (1, 4,'FPEN 403', '11:30:00', '01:30:00', 'Tuesday', 'EW–S1'),
    (1, 4,'FPEN 407', '09:00:00', '9:30:00',  'Wednesday', 'EW-S3'),
    (1, 4,'FPEN 411','12:30:00', '01:30:00', 'Wednesday', 'EW-S3'),
    (1, 4,'FPEN 409 ', '10:30:00', '12:30:00', 'Thursday', 'EW-S1'),
    (1, 4,'FPEN 405  ', '01:30:00', '03:30:00', 'Thursday', 'EW-S1'),
    (1, 4,'FPEN 400 ', '7:00:00', '4:30:00', 'Friday', 'SF-F1'),

    (1, 3,'SENG 107  ', '1:00:00', '2:30:00', 'Monday', 'JQB09'),
    (1, 3,'CPEN 103 ', '03:30:00', '05:30:00', 'Monday', 'EW-S2 '),
    (1, 3,'SENG 103 ', '03:30:00', '05:30:00', 'Tuesday', ' NNB1'),
    (1, 3,'SENG 101',  '05:30:00', '07:30:00', 'Tuesday', 'SES COMPUTER LAB'),
    (1, 3,'SENG 101', '09:30:00', '11:30:00','wednesday','JQB22'),
    (1, 3,'CPEN 103 ', '11:30:00', '2:30:00', 'Wednesday', 'ELECTRONICS LAB'),
    (1, 3,'SENG 103  ', '05:00:00', '7:30:00', 'Wednesday', 'JQB22'),
    (1, 3, 'SENG 105  ', '07:30:00', '10:30:00', 'Friday', 'UGCS '),
    (1, 3,'SENG 111 ', '01:30:00', '03:30:00', 'Friday', ' N2'),

    (1, 3,'CPEN 203 ',  '08:30:00', '10:30:00', 'Monday', 'EW-S1'),
    (1, 3, 'CPEN 213', '12:30:00', '2:30:00','Monday','SF-F2'),
    (1, 3, 'CPEN 211 ', '2:30:00', '4:30:00', 'Monday', 'SF-F2'),

    (1, 3,'SENG 207',  '07:30:00', '10:30:00', 'Tuesday', 'SES COMPUTER LAB'),
    (1, 3,'CPEN 211', '08:30:00', '11:30:00','wednesday','HUAWEI LAB'),
    (1, 3,'CPEN 201', '12:30:00', '2:30:00', 'Wednesday', 'SF-F2'),
    (1, 3,'SENG 201', '05:00:00', '7:30:00', 'Wednesday', 'NNB3'),
    (1, 3,'CPEN 213',  '07:30:00', '10:30:00', 'Thursday', 'HUAWEI LAB'),
    (1, 3,'CPEN 201 ', '10:30:00', '01:30:00', 'Thursday',  'HUAWEI LAB'),

    (1, 3,'SENG 201',  '08:30:00', '10:30:00', 'Friday', 'CC'),
    (1, 3,'CPEN 203',  '08:30:00', '11:30:00','Friday','ELECTRONICS LAB'),
    (1, 3,'SENG 207 ', '11:30:00', '01:30:00', 'Friday', 'JQB09');	



INSERT INTO exam_timetable (id, course_code, semester, year, date, location, start_time, end_time)
VALUES 
       (1,'UGRC 110', 1, 2023, '2023-01-09', 'CC', '07:30:00', '08:30:00'),
       (1,'SENG 101', 1, 2023, '2023-05-15', 'SES', '07:30:00', '10:30:00'),
       (1,'SENG 103', 1, 2023, '2023-09-01', 'SES', '11:30:00', '13:30:00'),
       (1,'SENG 105', 1, 2023, '2023-01-10', 'SES', '09:30:00', '11:30:00'),
       (1,'SENG 107', 1, 2023, '2023-05-10', 'SES', '07:30:00', '09:30:00'),
       (1,'SENG 109', 1, 2023, '2023-09-01', 'SES', '17:30:00', '19:30:00'),
       (1,'SENG 111', 1, 2023, '2023-01-09', 'SES', '07:30:00', '11:30:00'),
       (1,'CPEN 103', 1, 2023, '2023-05-15', 'SES', '07:30:00', '11:30:00'),
	   
       (1,'UGRC 220-238', 1, 2023, '2023-09-01', 'UGCS', '07:30:00', '08:30:00'),
       (1,'SENG 201', 1, 2023, '2023-09-01', 'SES', '09:30:00', '11:30:00'),
       (1,'SENG 203', 1, 2023, '2023-01-10', 'SES', '07:30:00', '10:30:00'),
       (1,'SENG 205', 1, 2023, '2023-05-16', 'SES', '07:30:00', '09:30:00'),
       (1,'SENG 207', 1, 2023, '2023-09-01', 'SES', '11:30:00', '13:30:00'),
       (1,'AREN 211', 1, 2023, '2023-01-09', 'SES', '07:30:00', '10:00:00'),
       (1,'AREN 213', 1, 2023, '2023-05-15', 'SES', '08:30:00', '10:30:00'),
       (1,'BMEN 201', 1, 2023, '2023-09-01', 'SES', '09:30:00', '11:30:00'),
       (1,'BMEN 203', 1, 2023, '2023-01-10', 'SES', '11:30:00', '13:30:00'),
       (1,'CPEN 201', 1, 2023, '2023-05-16', 'SES', '10:30:00', '12:30:00'),
       (1,'CPEN 203', 1, 2023, '2023-09-01', 'SES', '07:30:00', '09:30:00'),
       (1,'CPEN 213', 1, 2023, '2023-01-09', 'SES', '09:30:00', '11:30:00'),
       (1,'FPEN 209 ',1, 2023, '2023-05-15', 'SES', '09:30:00', '11:30:00'),
	   
       (1,'SENG 301', 1, 2023, '2023-09-01', 'SES', '07:30:00', '09:30:00'),
       (1,'AREN 325', 1, 2023, '2023-09-01', 'SES', '15:30:00', '17:30:00'),
       (1,'AREN 321', 1, 2023, '2023-01-10', 'SES', '09:30:00', '11:30:00'),
       (1,'AREN 331', 1, 2023, '2023-05-16', 'SES', '13:30:00', '15:30:00'),
       (1,'AREN 341', 1, 2023, '2023-09-01', 'SES', '07:30:00', '11:30:00'),
       (1,'AREN 343', 1, 2023, '2023-01-09', 'SES', '09:30:00', '11:30:00'),
       (1,'AREN 323', 1, 2023, '2023-05-15', 'SES', '09:30:00', '11:30:00'),
       (1,'BMEN 303', 1, 2023, '2023-09-01', 'SES', '07:30:00', '09:30:00'),
       (1,'BMEN 305', 1, 2023, '2023-09-01', 'SES', '11:30:00', '13:30:00'),
       (1,'BMEN 307', 1, 2023, '2023-01-10', 'SES', '13:30:00', '15:30:00'),
       (1,'BMEN 309', 1, 2023, '2023-05-16', 'SES', '16:30:00', '18:30:00'),
       (1,'BMEN 315', 1, 2023, '2023-09-01', 'SES', '07:30:00', '09:30:00'),
       (1,'FPEN 301', 1, 2023, '2023-01-09', 'SES', '08:30:00', '11:30:00'),
       (1,'FPEN 303', 1, 2023, '2023-05-15', 'SES', '11:30:00', '13:30:00'),
       (1,'FPEN 305', 1, 2023, '2023-09-01', 'SES', '09:30:00', '11:30:00'),
       (1,'FPEN 307', 1, 2023, '2023-09-01', 'SES', '07:30:00', '09:30:00'),
       (1,'FPEN 309', 1, 2023, '2023-01-10', 'SES', '07:30:00', '09:30:00'),
       (1,'FPEN 311', 1, 2023, '2023-05-16', 'SES', '09:30:00', '11:30:00'),
       (1,'FOSC 307', 1, 2023, '2023-09-01', 'SES', '10:30:00', '12:30:00'),
       (1,'MTEN 301', 1, 2023, '2023-01-09', 'SES', '13:30:00', '15:30:00'),
       (1,'MTEN 303', 1, 2023, '2023-05-15', 'SES', '07:30:00', '10:30:00'),
       (1,'MTEN 305', 1, 2023, '2023-09-01', 'SES', '17:30:00', '19:30:00'),
       (1,'MTEN 307', 1, 2023, '2023-09-01', 'SES', '07:30:00', '09:30:00'),
       (1,'MTEN 309', 1, 2023, '2023-01-10', 'SES', '07:30:00', '09:30:00'),
       (1,'MTEN 311', 1, 2023, '2023-05-13', 'SES', '11:30:00', '13:30:00'),
       (1,'MTEN 315', 1, 2023, '2023-09-01', 'SES', '13:30:00', '15:30:00'),
       (1,'CPEN 301', 1, 2023, '2023-01-09', 'SES', '13:30:00', '15:30:00'),
       (1,'CPEN 305', 1, 2023, '2023-05-15', 'SES', '15:30:00', '17:30:00'),
       (1,'CPEN 307', 1, 2023, '2023-09-01', 'SES', '07:30:00', '09:30:00'),
       (1,'CPEN 311', 1, 2023, '2023-09-01', 'SES', '17:30:00', '19:30:00'),
       (1,'CPEN 313', 1, 2023, '2023-01-10', 'SES', '11:30:00', '13:30:00'),
       (1,'CPEN 315', 1, 2023, '2023-05-16', 'SES', '07:30:00', '10:30:00'),

       (1,'SENG 401', 1, 2023, '2023-04-10', 'SES', '07:30:00', '10:30:00'),
       (1,'AREN 421', 1, 2023, '2023-04-14', 'SES', '08:30:00', '11:00:00'),
       (1,'AREN 433', 1, 2023, '2023-04-15', 'SES', '09:30:00', '11:30:00'),
       (1,'AREN 441', 1, 2023, '2023-04-18', 'SES', '13:30:00', '16:00:00'),
       (1,'AREN 423', 1, 2023, '2023-04-22', 'SES', '11:30:00', '13:30:00'),
       (1,'AREN 425', 1, 2023, '2023-04-24', 'SES', '07:30:00', '11:30:00'),
       (1,'AREN 427', 1, 2023, '2023-04-26', 'SES', '17:30:00', '19:30:00'),

       (1,'BMEN 405', 1, 2023, '2023-04-12', 'SES', '07:30:00', '10:30:00'),
       (1,'BMEN 407', 1, 2023, '2023-04-14', 'SES', '12:30:00', '14:30:00'),
       (1,'BMEN 403', 1, 2023, '2023-04-18', 'SES', '09:30:00', '11:30:00'),
       (1,'BMEN 411', 1, 2023, '2023-04-21', 'SES', '07:30:00', '10:30:00'),
       (1,'BMEN 413', 1, 2023, '2023-04-22', 'SES', '08:30:00', '11:00:00'),
       (1,'SENG 417', 1, 2023, '2023-04-24', 'SES', '11:30:00', '13:30:00' ),
       (1,'BMEN 419', 1, 2023, '2023-04-26', 'SES', '15:30:00', '17:30:00'),
       (1,'SENG 421', 1, 2023, '2023-04-27', 'SES', '07:30:00', '09:30:00'),

       (1,'FPEN 401', 1, 2023, '2023-04-11', 'SES', '11:30:00', '14:30:00'),
       (1,'FPEN 403', 1, 2023, '2023-04-15', 'SES', '09:30:00', '12:30:00'),
       (1,'FPEN 405', 1, 2023, '2023-04-18', 'SES', '10:30:00', '12:30:00'),
       (1,'FPEN 407', 1, 2023, '2023-04-12', 'SES', '07:30:00', '10:30:00'),
       (1,'FPEN 409', 1, 2023, '2023-04-22', 'SES', '09:30:00', '12:30:00'),
       (1,'FPEN 411', 1, 2023, '2023-04-23', 'SES', '11:30:00', '14:30:00'),
       (1,'FPEN 413', 1, 2023, '2023-04-25', 'SES', '15:30:00', '17:30:00'),

       (1,'CPEN 400', 1, 2023, '2023-04-10', 'SES', '12:30:00', '14:30:00'),
       (1,'CPEN 401', 1, 2023, '2023-04-12', 'SES', '10:30:00', '12:30:00'),
       (1,'CPEN 403', 1, 2023, '2023-04-15', 'SES', '11:30:00', '14:30:00'),
       (1,'CPEN 419', 1, 2023, '2023-04-17', 'SES', '09:30:00', '12:30:00'),
       (1,'CPEN 429', 1, 2023, '2023-04-19', 'SES', '09:30:00', '11:30:00'),
       (1,'CPEN 409', 1, 2023, '2023-04-21', 'SES', '09:30:00', '11:30:00'),
       (1,'CPEN 411', 1, 2023, '2023-04-23', 'SES', '07:30:00', '11:00:00'),
       (1,'CPEN 415', 1, 2023, '2023-04-17', 'SES', '11:30:00', '14:30:00'),
       (1,'CPEN 421', 1, 2023, '2023-04-15', 'SES', '11:30:00', '13:30:00'),
       (1,'CPEN 423', 1, 2023, '2023-04-24', 'SES', '09:30:00', '13:30:00'),
       (1,'CPEN 425', 1, 2023, '2023-04-25', 'SES', '07:30:00', '09:30:00'),
       (1,'CPEN 427', 1, 2023, '2023-04-27', 'SES', '07:30:00', '10:30:00');
        
       


          

	  
         
	  


