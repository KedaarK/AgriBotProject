# llm.py
import os, json, re
import google.generativeai as genai

API_KEY = os.environ.get("GOOGLE_API_KEY")
if not API_KEY:
    raise RuntimeError("GOOGLE_API_KEY not set")

genai.configure(api_key=API_KEY)

_MODEL = "gemini-1.5-flash"

def _mk_model():
    return genai.GenerativeModel(
        model_name=_MODEL,
        generation_config={
            "temperature": 0.3,
            "top_p": 0.9,
            "top_k": 40,
            "max_output_tokens": 768,
        },
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

def fertilizer_advice_prompt(crop_name: str, disease_name: str, locale: str = "en") -> str:
    return f"""
You are an agronomy assistant. Keep it practical and concise.

TASK: Recommend fertilizer guidance for the crop considering the given disease (focus on soil health and safe nutrient management, not pesticides).

CROP: {crop_name}
DISEASE: {disease_name}
LANGUAGE: {locale}

ASSUME: generic field conditions; if soil test data isn't provided, give general ranges and urge soil testing.

FORMAT: Return JSON with fields:
- "recommendations": array of short bullets (3–6) with N/P/K guidance (units per acre or hectare), and any organic amendments
- "schedule": array of 2–4 bullets (e.g., basal, top-dress timings)
- "notes": concise string with safety/regulatory notes and "adjust based on soil test"
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
- Current market unit price: {unit_price:.2f} per {unit}
- Quantity: {quantity} {unit}
- Transport distance (one-way): {transport_km} km
- Transport rate: {transport_rate_per_km:.2f} per km

TASK:
1) Calculate subtotal = unit_price * quantity.
2) Transport cost = transport_km * transport_rate_per_km.
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

def _strip_code_fences(txt: str) -> str:
    # Remove ```json ... ``` or ``` ... ```
    txt = txt.strip()
    if txt.startswith("```"):
        # remove leading fence
        txt = re.sub(r"^```(?:json)?\s*", "", txt, flags=re.IGNORECASE)
        # remove trailing fence
        txt = re.sub(r"\s*```$", "", txt)
    return txt.strip()

def run_json_prompt(prompt: str) -> dict:
    model = _mk_model()
    resp = model.generate_content(prompt)

    # Prefer the top candidate's text
    txt = (resp.text or "").strip()
    if not txt and resp.candidates:
        txt = (resp.candidates[0].content.parts[0].text or "").strip()

    txt = _strip_code_fences(txt)

    try:
        return json.loads(txt)
    except json.JSONDecodeError:
        # Final fallback: try to extract the first JSON object
        m = re.search(r"\{.*\}", txt, re.DOTALL)
        if m:
            return json.loads(m.group(0))
        raise
