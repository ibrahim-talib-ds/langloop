"""IP-based geolocation — best effort, no auth needed."""
import httpx
from fastapi import APIRouter, Request

router = APIRouter(prefix="/geo", tags=["geo"])


@router.get("/me")
async def geo_me(request: Request):
    """Return best-effort country + language for the caller's IP."""
    # Try headers first (works when behind Cloudflare / proxies)
    country = request.headers.get("cf-ipcountry")
    if country and country != "XX":
        return {"country": country, "source": "cloudflare"}

    ip = request.client.host if request.client else None
    # For localhost we can't detect — fallback
    if not ip or ip.startswith(("127.", "10.", "192.168.", "172.")):
        return {"country": "US", "source": "fallback"}

    try:
        async with httpx.AsyncClient(timeout=2.5) as client:
            r = await client.get(f"https://ipapi.co/{ip}/json/")
            if r.status_code == 200:
                data = r.json()
                return {
                    "country": data.get("country_code") or "US",
                    "city": data.get("city"),
                    "source": "ipapi",
                }
    except Exception:
        pass
    return {"country": "US", "source": "fallback"}
