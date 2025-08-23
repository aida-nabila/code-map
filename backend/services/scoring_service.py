from typing import List, Dict

def calculate_score(results: List[Dict]) -> Dict:
    """
    Calculates the user's score based on follow-up results.
    
    Args:
        results: List of dicts with keys 'question_id', 'is_correct', etc.

    Returns:
        A dictionary containing total questions, correct answers, and percentage score.
    """
    total_questions = len(results)
    correct_answers = sum(1 for r in results if r.get("is_correct"))
    score_percentage = (correct_answers / total_questions * 100) if total_questions else 0

    return {
        "total_questions": total_questions,
        "correct_answers": correct_answers,
        "score_percentage": round(score_percentage, 2)
    }
