# flask_backend/app.py
import os
import random
from dotenv import load_dotenv
from flask import Flask, request, jsonify
from flask_cors import CORS

# load .env
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Try to import the Gemini SDK if available
use_gemini = False
try:
    import google.generativeai as genai  # type: ignore
    if GEMINI_API_KEY:
        genai.configure(api_key=GEMINI_API_KEY)
        use_gemini = True
except Exception:
    use_gemini = False

app = Flask(__name__)
CORS(app)


# ---- Simple template bank (fallback) ----
TEMPLATES = {
    "general": {
        "polite": [
            "I’m so sorry, I can’t chat right now — I need to focus on something urgent. Can we talk later?",
            "I’d love to, but I’m actually running late and need to handle something. Thanks for understanding!"
        ],
        "blunt": [
            "I’m just not up for talking now.",
            "Not interested, thanks."
        ],
        "funny": [
            "I’d love to, but my introvert battery is at 2% — must recharge!",
            "I have an appointment with my couch. Rain check?"
        ]
    },
    "social": {
        "polite": [
            "I’m feeling a bit overwhelmed in crowds today — can we catch up another time?",
            "I’ve had a long day and need to step away, sorry!"
        ],
        "blunt": [
            "Crowds drain me — I need to sit this one out.",
            "Not feeling social right now."
        ],
        "funny": [
            "My social battery died — sending a rescue text later!",
            "I’m performing a solo invisibility act right now."
        ]
    },
    "work": {
        "polite": [
            "I have a deadline I must finish right now — sorry I can’t talk.",
            "I’m in the middle of something work-related. Can we talk after I finish?"
        ],
        "blunt": [
            "I need to focus on work, talk later.",
            "Can’t chat — work in progress."
        ],
        "funny": [
            "If I stop working now my boss will notice — gotta go behave like a responsible adult.",
            "My to-do list has me trapped. Rescue me later."
        ]
    },
    "family": {
        "polite": [
            "I’m dealing with something personal right now — can we talk later?",
            "I need a little quiet time, please understand."
        ],
        "blunt": [
            "I don’t want to discuss this now.",
            "I need space."
        ],
        "funny": [
            "Currently practicing the ancient art of staying silent. Will resume later.",
            "My 'avoid awkward convo' skill is at level expert today."
        ]
    }
}


def pick_template(category: str, tone: str, length: str, context: str) -> str:
    """Return a template-based excuse, optionally including context."""
    cat = category if category in TEMPLATES else "general"
    tone_map = TEMPLATES.get(cat, TEMPLATES["general"])
    tone = tone if tone in tone_map else list(tone_map.keys())[0]
    choices = tone_map[tone]
    excuse = random.choice(choices)

    # If context is provided, try to make a small contextual addition (short)
    if context and len(excuse) < 120:
        excuse = f"{excuse} ({context})"
    # Slightly vary by length preference:
    if length == "short":
        return excuse.split(".")[0].strip() + "."
    elif length == "long":
        # try to concatenate two templates for longer responses
        second = random.choice(choices)
        if second != excuse:
            return f"{excuse} {second}"
        return excuse
    else:
        return excuse


# ---- AI helper (Gemini) ----
def generate_with_gemini(context: str, category: str, tone: str, length: str) -> str:
    """
    Uses Gemini via google.generativeai library.
    If your installed SDK differs, adapt the call accordingly.
    """
    if not use_gemini:
        raise RuntimeError("Gemini SDK not configured or GEMINI_API_KEY missing.")

    # Build a precise prompt
    length_hint = {
        "short": "1-2 sentence, concise",
        "medium": "2-4 sentences",
        "long": "5-7 sentences"
    }.get(length, "2 sentences")

    prompt = (
    f"You are an awkwardly charming, quick-witted introvert who is trying to gracefully "
    f"escape an unwanted conversation. You speak from your own perspective, as if you "
    f"are the one making the excuse in real life.\n\n"
    f"The goal: Give a short, believable excuse that sounds natural, feels relatable, "
    f"and makes the other person smile or laugh. Keep it polite and harmless, but add "
    f"a dash of self-deprecating humor or cleverness.\n\n"
    f"Situation/Context: {context or 'a casual social interaction'}\n"
    f"Category (reason type): {category}\n"
    f"Tone (style of excuse): {tone}\n"
    f"Preferred Length: {length_hint}\n\n"
    f"Write ONE excuse in the first person (using 'I'), as if I’m saying it right now. "
    f"Make it sound human, slightly awkward in a cute way, and funny enough that the "
    f"other person won’t take offense."
)


    # Example: using generate_content; adapt if your SDK uses another method
    model = genai.GenerativeModel("gemini-2.5-flash")  # adjust model name if needed
    response = model.generate_content(prompt)
    # response may be an object with .text
    text = getattr(response, "text", None)
    if not text and isinstance(response, dict):
        text = response.get("text")
    if not text:
        text = str(response)
    return text.strip()


# ---- Routes ----
@app.route("/generate", methods=["POST"])
def generate_excuse():
    try:
        data = request.get_json(force=True)
        context = data.get("context", "").strip()
        category = data.get("category", "general").strip().lower()
        tone = data.get("tone", "polite").strip().lower()
        length = data.get("length", "short").strip().lower()  # short/medium/long
        use_ai = bool(data.get("use_ai", False))

        # Basic validation
        if len(context) > 1000:
            return jsonify({"error": "Context too long"}), 400

        # Try AI if requested and configured
        if use_ai and use_gemini:
            try:
                excuse = generate_with_gemini(context, category, tone, length)
                return jsonify({"excuse": excuse, "source": "ai"})
            except Exception as e:
                # log error and fall back to templates
                print("Gemini error:", e)

        # fallback to template generator
        excuse = pick_template(category, tone, length, context)
        return jsonify({"excuse": excuse, "source": "template"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "ai_enabled": use_gemini})


if __name__ == "__main__":
    # Development: use debug=True for local testing only
    app.run(host="0.0.0.0", port=5000)
