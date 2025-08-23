import json
import openai
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("OPENAI_API_KEY not found. Please set it in your .env file.")

# Initialize OpenAI client
client = openai.OpenAI(api_key=OPENAI_API_KEY)


def call_openai(prompt: str, max_tokens=2000, temperature=0.2) -> str:
    """Send a prompt to OpenAI and return the model's text output."""
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": "You are an assistant that returns clean, concise outputs.",
            },
            {"role": "user", "content": prompt},
        ],
        max_tokens=max_tokens,
        temperature=temperature,
    )
    return response.choices[0].message.content.strip()


def strip_json_codeblock(text: str) -> str:
    """Remove ```json and ``` from OpenAI output before parsing."""
    text = text.strip()
    if text.startswith("```json"):
        text = text[len("```json") :]
    elif text.startswith("```"):
        text = text[len("```") :]
    if text.endswith("```"):
        text = text[:-3]
    return text.strip()


def generate_questions(user_input: str):
    # 1. Extract topics
    topics = call_openai(
        f"""Extract all **coding-related** skills, languages, libraries, and frameworks from this statement:
        '{user_input}'.
        Output them as a single comma-separated list. No numbering, no explanations, no extra words."""
    )
    print("\n[DEBUG] Extracted topics:", topics)

    # 2. Extract primary programming language
    language_for_scaffold = call_openai(
        f"""From the following list of topics: '{topics}', extract the name of the primary **programming language** mentioned.
        If none is found, return exactly 'None'."""
    )
    print("[DEBUG] Extracted primary language:", language_for_scaffold)

    # 3. Generate coding questions if applicable
    coding_questions = []
    if language_for_scaffold.lower() != "none":
        coding_questions_text = call_openai(
            f"""Generate exactly 5 coding problems based on: '{topics}'.
            - Include a short code snippet in '{language_for_scaffold}' (≤30 lines).
            - Then write a question about that snippet.
            - Difficulty ratio: 1 Easy, 1 Medium, 3 Hard.
            - Format each question as code (triple backticks) + text.
            - Only self-contained examples, no APIs or external files.
            - Do NOT include answers.
            - Return questions as JSON list, each object with:
              {{"question": "...", "difficulty": "Easy/Medium/Hard", "category": "Coding"}}"""
        )
        # Robust parsing: remove empty items
        coding_questions = [
            q.strip()
            for q in coding_questions_text.replace("\n", "||").split("||")
            if q.strip()
        ]

    # 4. Generate non-coding questions
    non_coding_questions_text = call_openai(
        f"""Generate exactly 10 non-coding conceptual questions based on: '{topics}'.
        - No coding required.
        - Cover definitions, theory, practical applications.
        - Difficulty ratio: 1 Easy, 3 Medium, 6 Hard.
        - Return questions as JSON list, each object with:
          {{"question": "...", "difficulty": "Easy/Medium/Hard", "category": "Non-coding"}}"""
    )
    non_coding_questions = [
        q.strip()
        for q in non_coding_questions_text.replace("\n", "||").split("||")
        if q.strip()
    ]

    # 5. Convert coding questions to MCQs
    coding_mcqs = []
    if coding_questions:
        coding_mcqs_text = call_openai(
            f"""Convert the following coding questions into JSON multiple-choice questions (MCQs):
            {coding_questions}

            Rules:
            - Keep difficulty and category.
            - Provide exactly 4 options (A, B, C, D), only 1 correct.
            - Return **only JSON**, no extra text.
            - Example format:
            [
              {{"question": "...", "options": ["A","B","C","D"], "answer":"A", "difficulty":"Easy", "category":"Coding"}}
            ]"""
        )
        cleaned_text = strip_json_codeblock(coding_mcqs_text)
        print("[DEBUG] Coding MCQs JSON:", cleaned_text)
        try:
            coding_mcqs = json.loads(cleaned_text)
            if not isinstance(coding_mcqs, list):
                print("[ERROR] coding_mcqs is not a list, returning empty list")
                coding_mcqs = []
        except json.JSONDecodeError as e:
            print("[ERROR] Failed to parse coding MCQs JSON:", e)
            coding_mcqs = []

    # 6. Convert non-coding questions to MCQs
    non_coding_mcqs = []
    if non_coding_questions:
        non_coding_mcqs_text = call_openai(
            f"""Convert the following non-coding questions into JSON multiple-choice questions (MCQs):
            {non_coding_questions}

            Rules:
            - Keep difficulty and category.
            - Provide exactly 4 options (A, B, C, D), only 1 correct.
            - Return **only JSON**, no extra text.
            - Example format:
            [
              {{"question": "...", "options": ["A","B","C","D"], "answer":"A", "difficulty":"Easy", "category":"Non-coding"}}
            ]"""
        )
        cleaned_text = strip_json_codeblock(non_coding_mcqs_text)
        print("[DEBUG] Non-coding MCQs JSON:", cleaned_text)
        try:
            non_coding_mcqs = json.loads(cleaned_text)
            if not isinstance(non_coding_mcqs, list):
                print("[ERROR] non_coding_mcqs is not a list, returning empty list")
                non_coding_mcqs = []
        except json.JSONDecodeError as e:
            print("[ERROR] Failed to parse non-coding MCQs JSON:", e)
            non_coding_mcqs = []

    # 7. Merge all questions and assign unique IDs
    all_questions = coding_mcqs + non_coding_mcqs

    print("[DEBUG] Total questions generated:", len(all_questions))
    # 8. Return final data
    return {
        "topics": topics,
        "primary_language": language_for_scaffold,
        "questions": all_questions,
    }
