import glob
import os
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
# Job CSV embeddings
# -----------------------------
folder_path = "data"  # CSV folder
hf_model_name = "sentence-transformers/all-MiniLM-L6-v2"

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
else:
    print("No valid data found in CSV files.")
    df = pd.DataFrame()

# -----------------------------
# HF encoder for embeddings
# -----------------------------
_tokenizer = AutoTokenizer.from_pretrained(hf_model_name)
_model = AutoModel.from_pretrained(hf_model_name)


def get_embeddings(text: str):
    """
    Turn text into an embedding using the HF model.
    Returns a Python list (JSON-serializable).
    """
    inputs = _tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    with torch.no_grad():
        outputs = _model(**inputs)
    # Simple mean pooling
    emb = outputs.last_hidden_state.mean(dim=1)  # [1, hidden]
    return emb.squeeze(0).cpu().numpy().tolist()


# -----------------------------
# Generate Job embeddings
# -----------------------------
if not df.empty and "Full Job Description" in df.columns:
    job_descriptions = df["Full Job Description"].astype(str)
    job_embeddings = [get_embeddings(job) for job in job_descriptions]
    print("Embeddings generated for all job descriptions.")
else:
    print("No job descriptions found.")


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


def match_user_to_job(
    user_test_id: int,
    user_embedding: List[float],
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

        top_matches.append(
            {
                "user_test_id": int(user_test_id),
                "job_index": int(idx),
                "similarity_score": similarity_score,
                "similarity_percentage": similarity_percentage,
                "job_title": job.get("Title", "N/A"),
                "job_description": job.get("Full Job Description", "N/A"),
            }
        )

    return {"top_matches": top_matches}

