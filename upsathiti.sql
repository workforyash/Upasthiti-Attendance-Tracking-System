CREATE TABLE Faculties (
    FacultyID NUMBER(10) PRIMARY KEY,
    FacultyName VARCHAR2(100) NOT NULL CHECK (REGEXP_LIKE(FacultyName, '^[a-zA-Z ]+$')),
    PhoneNo VARCHAR2(20) NOT NULL UNIQUE CHECK (REGEXP_LIKE(PhoneNo, '^[0-9]{10}$')),
    Gmail VARCHAR2(255) NOT NULL UNIQUE CHECK (REGEXP_LIKE(Gmail, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')),
    Password VARCHAR2(64) NOT NULL CHECK (LENGTH(Password) >= 8 AND REGEXP_LIKE(Password, '^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).*$')),
    CONSTRAINT chk_valid_gmail_domain CHECK (REGEXP_LIKE(SUBSTR(Gmail, INSTR(Gmail, '@') + 1), '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'))
);

CREATE TABLE Parents(
    ParentID NUMBER(10) PRIMARY KEY,
    ParentName VARCHAR2(100) NOT NULL CHECK (REGEXP_LIKE(ParentName, '^[a-zA-Z ]+$')),
    PhoneNo VARCHAR2(20) NOT NULL UNIQUE CHECK (REGEXP_LIKE(PhoneNo, '^[0-9]{10}$')),
    Gmail VARCHAR2(255) NOT NULL UNIQUE CHECK (REGEXP_LIKE(Gmail, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')),
    CONSTRAINT chk_valid_gmail_parent CHECK (REGEXP_LIKE(SUBSTR(Gmail, INSTR(Gmail, '@') + 1), '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'))
);

CREATE TABLE Students(
    StudentID NUMBER(10) PRIMARY KEY,
    StudentName VARCHAR2(100) NOT NULL CHECK (REGEXP_LIKE(StudentName, '^[a-zA-Z ]+$')),
    PhoneNo VARCHAR2(20) NOT NULL UNIQUE CHECK (REGEXP_LIKE(PhoneNo, '^[0-9]{10}$')),
    Gmail VARCHAR2(255) NOT NULL UNIQUE CHECK (REGEXP_LIKE(Gmail, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')),
    Address VARCHAR2(255) NOT NULL CHECK (LENGTH(Address) <= 255 AND REGEXP_LIKE(Address, '^[a-zA-Z0-9.,\- ]+$')),
    CONSTRAINT chk_valid_gmail_student CHECK (REGEXP_LIKE(SUBSTR(Gmail, INSTR(Gmail, '@') + 1), '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'))
);

CREATE TABLE Courses (
    CourseID NUMBER(10) PRIMARY KEY,
    CourseName VARCHAR2(100) NOT NULL CHECK (REGEXP_LIKE(CourseName, '^[a-zA-Z0-9 ]+$')),
    No_of_Lectures NUMBER(10) NOT NULL CHECK (No_of_Lectures >= 0 AND No_of_Lectures <=2), -- assuming per day
    count_hour NUMBER(10) NOT NULL CHECK (count_hour >0 AND count_hour <=2)  -- assuming per day
);
CREATE TABLE Semesters (
    SemesterID NUMBER(10) PRIMARY KEY,
    SemesterName VARCHAR2(100) NOT NULL CHECK (REGEXP_LIKE(SemesterName, '^[a-zA-Z ]+$')),
    Start_Date DATE NOT NULL,
    End_Date DATE NOT NULL,
    CONSTRAINT chk_valid_semester_dates CHECK (Start_Date < End_Date)
);
CREATE TABLE Timetable (
    CourseID NUMBER(10),
    SemesterID NUMBER(10),
    Start_Time TIMESTAMP,
    End_Time TIMESTAMP,
    Day VARCHAR2(10) CHECK (Day IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')),
    PRIMARY KEY (CourseID, SemesterID, Day),
    FOREIGN KEY (CourseID) REFERENCES Courses(CourseID),
    FOREIGN KEY (SemesterID) REFERENCES Semesters(SemesterID),
    CHECK (Start_Time < End_Time) 
);

CREATE TABLE Attendance (
    AttendedDate DATE NOT NULL,
    Timestamp_S TIMESTAMP,
    Timestamp_E TIMESTAMP,
    Status VARCHAR2(10) CHECK (Status IN ('Present', 'Absent', 'Late', 'Excused')),
    CourseID NUMBER(10),
    StudentID NUMBER(10),
    FOREIGN KEY (CourseID) REFERENCES Courses(CourseID),
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID)
);


CREATE TABLE Master (
    EnrollmentID NUMBER(10) PRIMARY KEY,
    StudentID NUMBER(10) REFERENCES Students(StudentID) NOT NULL,
    CourseID NUMBER(10) REFERENCES Courses(CourseID) NOT NULL,
    FacultyID NUMBER(10) REFERENCES Faculties(FacultyID) NOT NULL,
    SemesterID NUMBER(10) REFERENCES Semesters(SemesterID) NOT NULL
);

CREATE TABLE Course_Semester_Faculty (
    FacultyID NUMBER(10) REFERENCES Faculties(FacultyID) NOT NULL,
    SemesterID NUMBER(10) REFERENCES Semesters(SemesterID) NOT NULL,
    CourseID NUMBER(10) REFERENCES Courses(CourseID) NOT NULL,
    PRIMARY KEY (FacultyID, SemesterID, CourseID)
);


CREATE TABLE Student_Semester (
    StudentID NUMBER(10) REFERENCES Students(StudentID) NOT NULL,
    SemesterID NUMBER(10) REFERENCES Semesters(SemesterID)NOT NULL,
    PRIMARY KEY (StudentID, SemesterID)
);

CREATE TABLE Student_Parent (
    StudentID NUMBER(10) REFERENCES Students(StudentID)NOT NULL,
    ParentID NUMBER(10) REFERENCES Parents(ParentID)NOT NULL,
    PRIMARY KEY (StudentID, ParentID)
);

-- CheckInTrigger
CREATE OR REPLACE TRIGGER CheckInTrigger
BEFORE INSERT ON Attendance
FOR EACH ROW
DECLARE
  vCount NUMBER;
BEGIN
  IF :NEW.Status = 'Scheduled' THEN
    SELECT COUNT(*)
    INTO vCount
    FROM Timetable
    WHERE CourseID = :NEW.CourseID
      AND Start_Time <= CURRENT_TIMESTAMP
      AND End_Time > CURRENT_TIMESTAMP
      AND Day = TO_CHAR(CURRENT_TIMESTAMP, 'Dy');

    IF vCount > 0 THEN
      :NEW.Status := 'Present';
      :NEW.Timestamp_S := CURRENT_TIMESTAMP;
    END IF;
  END IF;
END;
/



-- CheckOutTrigger
CREATE OR REPLACE TRIGGER CheckOutTrigger
BEFORE UPDATE ON Attendance
FOR EACH ROW
DECLARE
  vEndTime TIMESTAMP;
BEGIN
  IF :NEW.Status = 'Present' THEN
    SELECT End_Time
    INTO vEndTime
    FROM Timetable
    WHERE CourseID = :NEW.CourseID
      AND Day = TO_CHAR(CURRENT_TIMESTAMP, 'Dy');

    IF :NEW.Timestamp_E IS NULL AND CURRENT_TIMESTAMP > vEndTime THEN
      :NEW.Timestamp_E := CURRENT_TIMESTAMP;
    END IF;
  END IF;
END;


