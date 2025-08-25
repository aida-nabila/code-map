import glob
import os
import pickle
from typing import Any, Dict, List
from dotenv import load_dotenv
import openai
import pandas as pd
from sqlalchemy.orm import Session
import torch
from transformers import AutoTokenizer, AutoModel
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

from core.database import SessionLocal
from models.assessment import (
    FollowUpAnswers,
    GeneratedQuestion,
    UserTest,
)
from services.scoring_service import calculate_score

# -----------------------------
# Env & OpenAI client
# -----------------------------
load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("OPENAI_API_KEY not found. Please set it in your .env file.")

client = openai.OpenAI(api_key=OPENAI_API_KEY)

# -----------------------------
# Global variables - Now initialized as None
# -----------------------------
_tokenizer = None
_model = None
df = pd.DataFrame()
job_embeddings = []

def initialize_ai_models():
    """Initialize AI models and load job data - call this on server startup"""
    global _tokenizer, _model, df, job_embeddings
    
    print("Initializing AI models...")
    
    # Load HF model
    hf_model_name = "sentence-transformers/all-MiniLM-L6-v2"
    _tokenizer = AutoTokenizer.from_pretrained(hf_model_name)
    _model = AutoModel.from_pretrained(hf_model_name)
    print("✓ HuggingFace model loaded")
    
    # Load job data
    folder_path = "data"
    csv_files = glob.glob(f"{folder_path}/*.csv")
    dfs: List[pd.DataFrame] = []

    for file in csv_files:
        try:
            df_temp = pd.read_csv(file)
            if not df_temp.empty:
                dfs.append(df_temp)
        except pd.errors.EmptyDataError:
            print(f"Skipping empty file: {file}")
            continue

    if dfs:
        df = pd.concat(dfs, ignore_index=True)
        print(f"✓ Loaded {len(df)} job records")
        
        # Try to load pre-generated embeddings
        embeddings_file = os.path.join(folder_path, "job_embeddings.pkl")
        if os.path.exists(embeddings_file):
            print("Loading pre-generated embeddings...")
            try:
                with open(embeddings_file, 'rb') as f:
                    job_embeddings = pickle.load(f)
                print(f"✓ Loaded {len(job_embeddings)} pre-generated embeddings")
            except Exception as e:
                print(f"Error loading embeddings: {e}. Regenerating...")
                job_embeddings = _generate_and_save_embeddings(df, embeddings_file)
        else:
            # Generate and save embeddings for first time
            job_embeddings = _generate_and_save_embeddings(df, embeddings_file)
    else:
        print("No valid data found in CSV files.")
        df = pd.DataFrame()
    
    print("✓ Server startup complete - Ready for requests!")

def _generate_and_save_embeddings(df, embeddings_file):
    """Generate embeddings and save to file"""
    print("Generating embeddings for all job descriptions...")
    print("This will take a while (5-15 minutes)...")
    
    job_descriptions = df["Full Job Description"].astype(str)
    
    # Show progress
    total = len(job_descriptions)
    embeddings = []
    
    for i, job_desc in enumerate(job_descriptions):
        if i % 100 == 0:  # Print progress every 100 jobs
            print(f"Processing {i}/{total} jobs...")
        embeddings.append(get_embeddings(job_desc))
    
    # Save to file
    try:
        with open(embeddings_file, 'wb') as f:
            pickle.dump(embeddings, f)
        print(f"✓ Saved {len(embeddings)} embeddings to {embeddings_file}")
    except Exception as e:
        print(f"Error saving embeddings: {e}")
    
    return embeddings

# -----------------------------
# Helper function to check if models are loaded
# -----------------------------
def _ensure_models_loaded():
    """Ensure models are loaded before using them"""
    if _tokenizer is None or _model is None:
        raise Exception("AI models not initialized. Call initialize_ai_models() first.")

# -----------------------------
# HF encoder for embeddings
# -----------------------------
def get_embeddings(text: str):
    """
    Turn text into an embedding using the HF model.
    Returns a Python list (JSON-serializable).
    """
    _ensure_models_loaded()
    
    inputs = _tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    with torch.no_grad():
        outputs = _model(**inputs)
    # Simple mean pooling
    emb = outputs.last_hidden_state.mean(dim=1)  # [1, hidden]
    return emb.squeeze(0).cpu().numpy().tolist()

# -----------------------------
# OpenAI call function
# -----------------------------
def call_openai(prompt: str, max_tokens=2000, temperature=0.2) -> str:
    """
    Generate a descriptive profile text from OpenAI based on a prompt.
    """
    resp = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": (
                    "You are an assistant that returns clean, concise outputs. "
                    "Write in a professional, neutral tone; avoid buzzwords."
                ),
            },
            {"role": "user", "content": prompt},
        ],
        max_tokens=max_tokens,
        temperature=temperature,
    )
    return resp.choices[0].message.content.strip()

# -----------------------------
# Data aggregation for a user
# -----------------------------
def get_user_embedding_data(user_test_id: int) -> Dict[str, Any]:
    """
    Fetch user responses and follow-up results; compute score; build combined_data.
    score reflects how consistent/true the skillReflection is relative to follow-up answers.
    """
    db: Session = SessionLocal()
    try:
        # 1) Fetch user responses (ORM model)
        user_res = (
            db.query(UserTest).filter(UserTest.id == user_test_id).first()
        )
        if not user_res:
            return {"error": f"No user responses found for user_test_id {user_test_id}"}

        # 2) Fetch follow-up answers
        follow_ups = (
            db.query(FollowUpAnswers)
            .filter(FollowUpAnswers.user_test_id == user_test_id)
            .all()
        )

        # 3) Build results for scoring
        results: List[Dict[str, Any]] = []
        for f in follow_ups:
            correct_q = (
                db.query(GeneratedQuestion)
                .filter(GeneratedQuestion.id == f.question_id)
                .first()
            )
            is_correct = bool(
                correct_q and correct_q.answer == f.selected_option
            )
            results.append(
                {
                    "question_id": f.question_id,
                    "selected_option": f.selected_option,
                    "answer": correct_q.answer if correct_q else None,
                    "is_correct": is_correct,
                }
            )

        # 4) Calculate score (how true the skill reflection is)
        score = calculate_score(results)

        # 5) Normalize programmingLanguages to a list (in case stored as JSON/text)
        prog_langs = user_res.programmingLanguages
        if isinstance(prog_langs, str):
            # naive split fallback; replace with json.loads if you store JSON text
            prog_langs = [p.strip() for p in prog_langs.split(",") if p.strip()]

        combined_data = {
            "user_test_id": user_test_id,
            "user_responses": {
                "educationLevel": getattr(user_res, "educationLevel", None),
                "cgpa": getattr(user_res, "cgpa", None),
                "major": getattr(user_res, "major", None),
                "programmingLanguages": prog_langs,
                "courseworkExperience": getattr(user_res, "courseworkExperience", None),
                "skillReflection": getattr(user_res, "skillReflection", None),
            },
            "follow_up_results": results,
            "score": score,
        }
        return combined_data
    finally:
        db.close()


# -----------------------------
# Profile generation via OpenAI
# -----------------------------
def _build_profile_prompt(combined_data: Dict[str, Any]) -> str:
    """
    Build a clear instruction that explains how to use score:
    score = how consistent/true the user's skillReflection is vs. follow-up test.
    """
    return (
        "Analyze the following user information and write a thorough, objective profile. "
        "Focus on strengths, weaknesses, practical skills, and realistic next steps. "
        "Interpret 'score' as the degree to which the user's skillReflection is confirmed "
        "by follow-up test answers (higher = more accurate self-assessment). "
        "Avoid fluff; keep it evidence-based and specific.\n\n"
        f"USER DATA:\n{combined_data}\n\n"
        "Return a single descriptive paragraph with bullet-style clauses separated by semicolons."
    )


def generate_user_profile_text(combined_data: Dict[str, Any]) -> str:
    prompt = _build_profile_prompt(combined_data)
    return call_openai(prompt)


# -----------------------------
# Create user embedding
# -----------------------------
def create_user_embedding(user_test_id: int) -> Dict[str, Any]:
    """
    1) Collect combined_data (user responses + follow-up results + score)
    2) Generate descriptive profile text via OpenAI
    3) Convert profile text into an embedding via HF encoder
    """
    combined_data = get_user_embedding_data(user_test_id)
    if "error" in combined_data:
        return combined_data

    profile_text = generate_user_profile_text(combined_data)
    user_embedding = get_embeddings(profile_text)

    return {
        "user_test_id": user_test_id,
        "profile_text": profile_text,
        "user_embedding": user_embedding,  # list[float]
        "combined_data": combined_data,  # included for debugging/inspection
    }

# -----------------------------
# Match user to job 
# -----------------------------
def match_user_to_job(
    user_test_id: int,
    user_embedding: List[float], use_openai_summary: bool = True, # new flag to control summary generation
) -> Dict[str, Any]:
    """
    Compare user embedding to all job embeddings using cosine similarity.
    df and job_embeddings are now global, no need to pass them.
    """

    global df, job_embeddings  # use the global variables defined when loading CSVs

    if df.empty or not job_embeddings:
        return {"error": "No jobs or embeddings available."}

    # Convert to numpy
    user_vec = np.array(user_embedding).reshape(1, -1)  # (1, dim)
    job_matrix = np.array(job_embeddings)  # (num_jobs, dim)

    # Compute cosine similarity
    similarities = cosine_similarity(user_vec, job_matrix)[0]  # shape: (num_jobs,)

    # Get indices of top 3 jobs (sorted by similarity score)
    top_n = 3
    top_indices = np.argsort(similarities)[-top_n:][::-1]  # descending order

    # Collect job info
    top_matches = []
    for idx in top_indices:
        job = df.iloc[idx]
        similarity_score = float(similarities[idx])
        similarity_percentage = round(similarity_score * 100, 2)
        job_desc = job.get("Full Job Description", "N/A")
        
        # Initialize variables for skills and knowledge
        required_skills = []
        required_knowledge = []
        
        # Generate cleaned/comprehensive description using OpenAI
        if use_openai_summary and job_desc != "N/A":
            try:
                summary_prompt = (
                    "Extract a clear, comprehensive job description from the text below. "
                    "Focus on responsibilities. "
                    "Write it concisely in a professional tone (1 paragraph).\n\n"
                    f"JOB DESCRIPTION TEXT:\n{job_desc}\n\n"
                    "Return only the cleaned-up job description without any additional text."
                )
                
                skills_prompt = (
                    "ANALYZE THIS JOB DESCRIPTION AND EXTRACT ALL REQUIRED SKILLS:\n\n"
                    f"{job_desc}\n\n"
                    "EXTRACTION RULES:\n"
                    "1. Extract BOTH technical skills (programming languages, tools, software) AND soft skills (communication, leadership, teamwork)\n"
                    "2. Return ONLY a comma-separated list without any additional text\n"
                    "3. Be specific - if it mentions 'Python', include 'Python', not just 'programming'\n"
                    "4. Include skills mentioned in requirements, qualifications, or responsibilities sections\n"
                    "5. Remove duplicates and keep the most specific term\n\n"
                    "EXAMPLE OUTPUT: Python, Java, SQL, React, AWS, Communication, Teamwork, Problem Solving\n\n"
                    "EXTRACTED SKILLS:"
                )
                
                knowledge_prompt = (
                    "ANALYZE THIS JOB DESCRIPTION AND EXTRACT ALL REQUIRED KNOWLEDGE AREAS:\n\n"
                    f"{job_desc}\n\n"
                    "EXTRACTION RULES:\n"
                    "1. Extract knowledge domains, subject matter expertise, and specialized areas\n"
                    "2. Include things like: algorithms, data structures, machine learning, web development, cybersecurity, etc.\n"
                    "3. Return ONLY a comma-separated list without any additional text\n"
                    "4. Focus on knowledge requirements, not just skills\n"
                    "5. Remove duplicates\n\n"
                    "EXAMPLE OUTPUT: Algorithms, Data Structures, Machine Learning, Web Development, Database Systems, Cloud Computing\n\n"
                    "EXTRACTED KNOWLEDGE:"
                )
                
                print(f"Processing job {idx} with OpenAI...")
                
                # Get job description summary
                job_desc = call_openai(summary_prompt, max_tokens=800)
                
                # Extract skills with retry logic
                try:
                    skills_response = call_openai(skills_prompt, max_tokens=300)
                    print(f"Raw skills response: {skills_response}")
                    required_skills = [skill.strip() for skill in skills_response.split(',') if skill.strip()]
                except Exception as skills_error:
                    print(f"Skills extraction failed for job {idx}: {skills_error}")
                    required_skills = ["Error extracting skills"]
                
                # Extract knowledge with retry logic
                try:
                    knowledge_response = call_openai(knowledge_prompt, max_tokens=300)
                    print(f"Raw knowledge response: {knowledge_response}")
                    required_knowledge = [knowledge.strip() for knowledge in knowledge_response.split(',') if knowledge.strip()]
                except Exception as knowledge_error:
                    print(f"Knowledge extraction failed for job {idx}: {knowledge_error}")
                    required_knowledge = ["Error extracting knowledge"]
                
                # Debug prints after extraction
                print(f"Extracted skills for job {idx}: {required_skills}")
                print(f"Extracted knowledge for job {idx}: {required_knowledge}")
                
            except Exception as e:
                print(f"OpenAI error for job index {idx}: {e}")
                # fallback to original
                job_desc = job.get("Full Job Description", "N/A")
                required_skills = ["Failed to extract skills"]
                required_knowledge = ["Failed to extract knowledge"]
        else:
            # If not using OpenAI summary, still try to extract basic info
            job_desc = job.get("Full Job Description", "N/A")
            required_skills = ["Enable OpenAI extraction for detailed skills"]
            required_knowledge = ["Enable OpenAI extraction for detailed knowledge"]

        top_matches.append(
            {
                "user_test_id": int(user_test_id),
                "job_index": int(idx),
                "similarity_score": similarity_score,
                "similarity_percentage": similarity_percentage,
                "job_title": job.get("Title", "N/A"),
                "job_description": job_desc,
                "required_skills": required_skills,
                "required_knowledge": required_knowledge
            }
        )
    
    return {"top_matches": top_matches}

# -----------------------------
# Check if everything is loaded
# -----------------------------
def is_initialized() -> bool:
    """Check if AI models and data are loaded"""
    return _tokenizer is not None and _model is not None and not df.empty

