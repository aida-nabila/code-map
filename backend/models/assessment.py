# SQLAlchemy models (database tables)

from sqlalchemy import Column, ForeignKey, Integer, String, Float, Text
from core.database import Base

class UserTest(Base):
    __tablename__ = "user_test"

    id = Column(Integer, primary_key=True, index=True)
    educationLevel = Column(String, nullable=True)
    cgpa = Column(Float, nullable=True)
    major = Column(String, nullable=True)
    programmingLanguages = Column(String, nullable=True)
    courseworkExperience = Column(String, nullable=True)
    skillReflection = Column(Text, nullable=True)

class GeneratedQuestion(Base):
    __tablename__ = "generated_questions"

    id = Column(Integer, primary_key=True, index=True)
    user_test_id = Column(Integer, nullable=False)  # FK to UserTest.id
    question_text = Column(Text, nullable=False)
    options = Column(Text, nullable=True)
    answer = Column(String, nullable=True)
    difficulty = Column(String, nullable=True)
    question_type = Column(String, nullable=True)
    
class FollowUpAnswers(Base):
    __tablename__ = "follow_up_answers"
    id = Column(Integer, primary_key=True, index=True)
    user_test_id = Column(Integer, ForeignKey("user_test.id"), nullable=False)
    question_id = Column(Integer, ForeignKey("generated_questions.id"), nullable=False)
    selected_option = Column(String, nullable=False)
