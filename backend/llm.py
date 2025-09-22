# llm.py
import os
import google.generativeai as genai

API_KEY = os.environ.get("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("GOOGLE_API_KEY not set")

genai.configure(api_key=API_KEY)

# Choose a sensible model; you can switch in AI Studio later.
_MODEL = "gemini-1.5-pro"

def _mk_model():
    return genai.GenerativeModel(
        model_name=_MODEL,
        generation_config={
            "temperature": 0.3,
            "top_p": 0.9,
            "top_k": 40,
            "max_output_tokens": 768,
            # We’ll ask for JSON when we need it via prompt.
        },
        safety_settings={
            # Use defaults or your policy
        }
    )

def disease_prevention_prompt(disease_name: str, crop_name: str, locale: str = "en") -> str:
    return f"""
You are an agronomy assistant. Keep it practical and concise.

TASK: Provide PREVENTIVE measures (not treatment) for the plant disease below.

CROP: {crop_name}
DISEASE: {disease_name}
LANGUAGE: {locale}

FORMAT: Return JSON with fields:
- "summary": 1–2 sentence overview
- "cultural_practices": array of short actionable bullets (3–6)
- "sanitation_practices": array (2–4)
- "resistant_varieties": array (0–4, if unknown return empty array)
- "monitoring": array (2–4)
- "disclaimer": a single sentence reminding to check local guidelines

Only return JSON, no extra text.
"""

def market_quote_prompt(crop: str, market_name: str, market_city: str, unit_price: float,
                        quantity: float, unit: str, transport_km: float, transport_rate_per_km: float,
                        locale: str = "en") -> str:
    return f"""
You are an agricultural marketing assistant. Explain simply.

INPUTS:
- Crop: {crop}
- Market: {market_name}, {market_city}
- Current market unit price: {unit_price:.2f} per {unit}  (NOTE: given by a price API, do NOT invent)
- Quantity: {quantity} {unit}
- Transport distance (one-way): {transport_km} km
- Transport rate: {transport_rate_per_km:.2f} per km

TASK:
1) Calculate subtotal = unit_price * quantity.
2) Transport cost = transport_km * transport_rate_per_km.
   (If return trip is typical in your area, note it in the explanation, but keep cost as above unless specified.)
3) Total = subtotal + transport cost.

FORMAT: Return JSON:
- "breakdown": {{"unit_price": number, "quantity": number, "subtotal": number,
                "transport_km": number, "transport_rate_per_km": number, "transport_cost": number}}
- "total": number
- "notes": array of short bullets with assumptions and caveats
- "disclaimer": short sentence about price volatility

Language: {locale}
Only return JSON.
"""

def run_json_prompt(prompt: str) -> dict:
    model = _mk_model()
    resp = model.generate_content(prompt)
    # The model returns text; parse JSON safely:
    import json
    # Some models wrap in code fences; strip them.
    txt = resp.text.strip()
    if txt.startswith("```"):
        txt = txt.strip("`")
        # Remove leading language hints like ```json
        first_newline = txt.find("\n")
        if first_newline != -1:
            txt = txt[first_newline+1:]
    return json.loads(txt)
