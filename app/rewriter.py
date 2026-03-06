from openai import OpenAI

from app.config import DEFAULT_LLM_MODEL, NEBIUS_BASE_URL, NEBIUS_API_KEY
from app.settings import get_setting

TONE_INSTRUCTIONS = {
    "formal": "Rewrite in a professional, formal tone. Keep the same meaning.",
    "friendly": "Rewrite in a warm, friendly, casual tone. Keep the same meaning.",
    "shorter": "Make this much shorter and more concise. Keep the core meaning.",
    "funnier": "Rewrite to be witty and humorous. Keep the core meaning.",
}

SYSTEM = (
    "You are a message rewriting assistant. Rewrite the user's message "
    "according to the instruction. Return ONLY the rewritten message text, "
    "with no preamble, explanation, or quotes."
)


def _get_model_name() -> str:
    model = get_setting("llm_model")
    return model if isinstance(model, str) and model.strip() else DEFAULT_LLM_MODEL


def rewrite(text: str, tone: str) -> str:
    """Rewrite text with a given tone."""
    client = OpenAI(base_url=NEBIUS_BASE_URL, api_key=NEBIUS_API_KEY)

    if tone in TONE_INSTRUCTIONS:
        instruction = TONE_INSTRUCTIONS[tone]
    else:
        instruction = f"Rewrite this message to sound more {tone}."

    response = client.chat.completions.create(
        model=_get_model_name(),
        messages=[
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": f"{instruction}\n\nMessage: {text}"},
        ],
        max_tokens=500,
    )
    return response.choices[0].message.content.strip()
